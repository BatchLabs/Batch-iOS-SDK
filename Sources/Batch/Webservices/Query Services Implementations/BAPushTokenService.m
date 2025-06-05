//
//  BAPushTokenService.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAInjection.h>
#import <Batch/BAPushTokenService.h>
#import <Batch/BAWSQueryPushToken.h>
#import <Batch/BAWSResponsePushToken.h>
#import <Batch/BAWebserviceURLBuilder.h>
#import <Batch/Batch-Swift.h>

@interface BAPushTokenServiceDatasource () {
    NSString *_token;
    BOOL _usesProductionEnvironment;
}
@end

@implementation BAPushTokenServiceDatasource : NSObject

- (instancetype)initWithToken:(NSString *)token usesProductionEnvironment:(BOOL)usesProductionEnvironment;
{
    self = [super init];
    if (self) {
        _token = token;
        _usesProductionEnvironment = usesProductionEnvironment;
    }
    return self;
}

- (NSURL *)requestURL {
    NSString *host = [[BAInjection injectProtocol:@protocol(BADomainManagerProtocol)] urlFor:BADomainServiceWeb
                                                                        overrideWithOriginal:FALSE];
    return [BAWebserviceURLBuilder webserviceURLForHost:host shortname:self.requestShortIdentifier];
}

- (NSString *)requestIdentifier {
    return @"push";
}

- (NSString *)requestShortIdentifier {
    return kParametersPushWebserviceShortname;
}

- (NSArray<id<BAWSQuery>> *)queriesToSend {
    BAWSQueryPushToken *query = [[BAWSQueryPushToken alloc] initWithToken:_token
                                                          andIsProduction:_usesProductionEnvironment];
    return @[ query ];
}

- (nullable BAWSResponse *)responseForQuery:(BAWSQuery *)query content:(NSDictionary *)content {
    if ([query isKindOfClass:[BAWSQueryPushToken class]]) {
        return [[BAWSResponsePushToken alloc] initWithResponse:content];
    }
    return nil;
}

@end
