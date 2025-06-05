//
//  BAStartService.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAStartService.h>
#import <Batch/Batch-Swift.h>

#import <Batch/BAWebserviceURLBuilder.h>

#import <Batch/BAWSQueryPushToken.h>
#import <Batch/BAWSQueryStart.h>
#import <Batch/BAWSResponsePushToken.h>
#import <Batch/BAWSResponseStart.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BAInjection.h>
#import <Batch/BANullHelper.h>
#import <Batch/BAParameter.h>

@implementation BAStartServiceDatasource

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isSilent = false;
    }
    return self;
}

- (NSURL *)requestURL {
    NSString *host = [[BAInjection injectProtocol:@protocol(BADomainManagerProtocol)] urlFor:BADomainServiceWeb
                                                                        overrideWithOriginal:FALSE];
    return [BAWebserviceURLBuilder webserviceURLForHost:host shortname:self.requestShortIdentifier];
}

- (NSString *)requestIdentifier {
    return @"start";
}

- (NSString *)requestShortIdentifier {
    return kParametersStartWebserviceShortname;
}

- (NSArray<id<BAWSQuery>> *)queriesToSend {
    NSMutableArray *queries = [[NSMutableArray alloc] initWithCapacity:2];

    BAWSQueryStart *startQuery = [[BAWSQueryStart alloc] init];
    startQuery.isSilent = self.isSilent;

    [queries addObject:startQuery];

    id<BAWSQuery> tokenQuery = [self tokenQuery];
    if (tokenQuery) {
        [queries addObject:tokenQuery];
    }

    return queries;
}

- (nullable BAWSResponse *)responseForQuery:(BAWSQuery *)query content:(NSDictionary *)content {
    if ([query isKindOfClass:[BAWSQueryStart class]]) {
        return [[BAWSResponseStart alloc] initWithResponse:content];
    } else if ([query isKindOfClass:[BAWSQueryPushToken class]]) {
        return [[BAWSResponsePushToken alloc] initWithResponse:content];
    }
    return nil;
}

- (nullable id<BAWSQuery>)tokenQuery {
    NSString *token = [BAParameter objectForKey:kParametersPushTokenKey fallback:@""];

    if ([BANullHelper isStringEmpty:token]) {
        return nil;
    }

    BOOL usesProductionEnvironment = true;
    id savedUsesProductionEnv = [BAParameter objectForKey:kParametersPushTokenIsProductionKey fallback:nil];
    if ([savedUsesProductionEnv isKindOfClass:[NSNumber class]]) {
        usesProductionEnvironment = [savedUsesProductionEnv boolValue];
    } else {
        usesProductionEnvironment = [BACoreCenter.instance.status isLikeProduction];
    }

    return [[BAWSQueryPushToken alloc] initWithToken:token andIsProduction:usesProductionEnvironment];
}

@end
