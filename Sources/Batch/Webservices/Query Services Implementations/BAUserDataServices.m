//
//  BAUserDataWebservice.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAUserDataServices.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BAInjection.h>
#import <Batch/BAParameter.h>
#import <Batch/BARandom.h>
#import <Batch/BAUserDataManager.h>
#import <Batch/BAWSQueryAttributes.h>
#import <Batch/BAWSQueryAttributesCheck.h>
#import <Batch/BAWSResponseAttributes.h>
#import <Batch/BAWSResponseAttributesCheck.h>
#import <Batch/BAWebserviceURLBuilder.h>
#import <Batch/Batch-Swift.h>

#define DEFAULT_RECHECK_WAIT_TIME @(15000)

@interface BAUserDataSendServiceDatasource ()

@property long long version;
@property (nonnull) NSDictionary *attributes;
@property (nonnull) NSDictionary<NSString *, NSSet<NSString *> *> *tags;

@end

@implementation BAUserDataSendServiceDatasource : NSObject

- (instancetype)initWithVersion:(long long)version
                     attributes:(nonnull NSDictionary *)attributes
                        andTags:(nonnull NSDictionary<NSString *, NSSet<NSString *> *> *)tags {
    self = [super init];
    if (self) {
        _version = version;
        _attributes = attributes;
        _tags = tags;
    }
    return self;
}

- (NSURL *)requestURL {
    NSString *host = [[BAInjection injectProtocol:@protocol(BADomainManagerProtocol)] urlFor:BADomainServiceWeb
                                                                        overrideWithOriginal:FALSE];
    return [BAWebserviceURLBuilder webserviceURLForHost:host shortname:self.requestShortIdentifier];
}

- (NSString *)requestIdentifier {
    return @"attributesSend";
}

- (NSString *)requestShortIdentifier {
    return kParametersAttributesSendWebserviceShortname;
}

- (NSArray<id<BAWSQuery>> *)queriesToSend {
    BAWSQueryAttributes *query = [[BAWSQueryAttributes alloc] initWithVersion:self.version
                                                                   attributes:self.attributes
                                                                      andTags:self.tags];
    return @[ query ];
}

- (nullable BAWSResponse *)responseForQuery:(BAWSQuery *)query content:(NSDictionary *)content {
    if ([query isKindOfClass:[BAWSQueryAttributes class]]) {
        return [[BAWSResponseAttributes alloc] initWithResponse:content];
    }
    return nil;
}

@end

@implementation BAUserDataSendServiceDelegate : NSObject

- (void)webserviceClient:(BAQueryWebserviceClient *)client didFailWithError:(NSError *)error {
    // TODO: backoff on the send
}

- (void)webserviceClient:(BAQueryWebserviceClient *)client
    didSucceedWithResponses:(NSArray<id<BAWSResponse>> *)responses {
    for (BAWSResponse *response in responses) {
        if ([response isKindOfClass:[BAWSResponseAttributes class]]) {
            BAWSResponseAttributes *castedResponse = (BAWSResponseAttributes *)response;
            [BAUserDataManager storeTransactionID:castedResponse.transactionID forVersion:castedResponse.version];
            if (castedResponse.projectKey != nil) {
                NSString *oldProjectKey = [BAParameter objectForKey:kParametersProjectKey fallback:nil];
                if (![castedResponse.projectKey isEqualToString:oldProjectKey]) {
                    // If we are here this mean we are running on a fresh V2 install and user has
                    // just wrote some profile data.
                    // So we save the project key to not trigger the profile data migration from the
                    // next ATC response otherwise we would erase the data we just sent.
                    [BAParameter setValue:castedResponse.projectKey forKey:kParametersProjectKey saved:true];
                }
            }
        }
    }
}

@end

@interface BAUserDataCheckServiceDatasource ()

@property long long version;
@property (nonnull) NSString *transactionID;

@end

@implementation BAUserDataCheckServiceDatasource : NSObject

- (instancetype)initWithVersion:(long long)version transactionID:(nonnull NSString *)transactionID {
    self = [super init];
    if (self) {
        _version = version;
        _transactionID = transactionID;
    }
    return self;
}

- (NSURL *)requestURL {
    NSString *host = [[BAInjection injectProtocol:@protocol(BADomainManagerProtocol)] urlFor:BADomainServiceWeb
                                                                        overrideWithOriginal:FALSE];

    return [BAWebserviceURLBuilder webserviceURLForHost:host shortname:self.requestShortIdentifier];
}

- (NSString *)requestIdentifier {
    return @"attributesCheck";
}

- (NSString *)requestShortIdentifier {
    return kParametersAttributesCheckWebserviceShortname;
}

- (NSArray<id<BAWSQuery>> *)queriesToSend {
    BAWSQueryAttributesCheck *query = [[BAWSQueryAttributesCheck alloc] initWithTransactionID:self.transactionID
                                                                                   andVersion:self.version];
    return @[ query ];
}

- (nullable BAWSResponse *)responseForQuery:(BAWSQuery *)query content:(NSDictionary *)content {
    if ([query isKindOfClass:[BAWSQueryAttributesCheck class]]) {
        return [[BAWSResponseAttributesCheck alloc] initWithResponse:content];
    }
    return nil;
}

@end

@implementation BAUserDataCheckServiceDelegate : NSObject

- (void)webserviceClient:(BAQueryWebserviceClient *)client didFailWithError:(NSError *)error {
}

- (void)webserviceClient:(BAQueryWebserviceClient *)client
    didSucceedWithResponses:(NSArray<id<BAWSResponse>> *)responses {
    BOOL foundValidCheckAnswer = NO;
    for (BAWSResponse *response in responses) {
        // Start query response.
        if ([response isMemberOfClass:[BAWSResponseAttributesCheck class]] == YES) {
            BAWSResponseAttributesCheck *castedResponse = (BAWSResponseAttributesCheck *)response;

            foundValidCheckAnswer = YES;

            switch (castedResponse.action) {
                case BAWSResponseAttrCheckActionOk:
                    // yay
                    break;
                case BAWSResponseAttrCheckActionRecheck: {
                    NSNumber *timeToWait = castedResponse.time;
                    if (timeToWait == nil) {
                        // Default wait before recheck
                        timeToWait = DEFAULT_RECHECK_WAIT_TIME;
                    }

                    long long longTimeToWait = [timeToWait longLongValue]; // pun intended
                    if (longTimeToWait < 0) {
                        longTimeToWait = 0;
                    }

                    [BAUserDataManager startAttributesCheckWSWithDelay:longTimeToWait];

                    break;
                }
                case BAWSResponseAttrCheckActionBump: {
                    long long version = [castedResponse.version longLongValue];
                    if (version <= 0) {
                        foundValidCheckAnswer = NO;
                        break;
                    }

                    [BAUserDataManager updateWithServerDataVersion:version];

                    break;
                }
                case BAWSResponseAttrCheckActionResend: {
                    long long timeToWait = [castedResponse.time longLongValue];
                    if (timeToWait < 0) {
                        timeToWait = 0;
                    }

                    [BAUserDataManager startAttributesSendWSWithDelay:timeToWait];

                    break;
                }
                case BAWSResponseAttrCheckActionUnknown:
                default:
                    // Revert the found flack so we end up in the generic action
                    // Not so elegant.
                    foundValidCheckAnswer = NO;
                    break;
            }

            // Checking whether project has changed
            if (castedResponse.projectKey != nil) {
                NSString *oldProjectKey = [BAParameter objectForKey:kParametersProjectKey fallback:nil];
                if (![castedResponse.projectKey isEqualToString:oldProjectKey]) {
                    [BAParameter setValue:castedResponse.projectKey forKey:kParametersProjectKey saved:true];
                    [[BAInjection injectProtocol:@protocol(BAProfileCenterProtocol)]
                        onProjectChanged:oldProjectKey
                              withNewKey:castedResponse.projectKey];
                }
            }
        }
    }

    if (!foundValidCheckAnswer) {
        [BAUserDataManager startAttributesCheckWSWithDelay:[DEFAULT_RECHECK_WAIT_TIME longLongValue]];
    }
}

@end
