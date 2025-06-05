//
//  BAEventTrackerService.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAEventTrackerService.h>

#import <Batch/BAWSQueryTracking.h>
#import <Batch/BAWSResponseTracking.h>
#import <Batch/BAWebserviceURLBuilder.h>

#import <Batch/BAInjection.h>
#import <Batch/BAPromise.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/Batch-Swift.h>

@interface BAEventTrackerService () {
    NSArray *_events;
    NSArray *_promises;
}
@end

@implementation BAEventTrackerService

- (instancetype)initWithEvents:(NSArray *)events {
    self = [super init];
    if (self) {
        _events = events;
    }
    return self;
}

- (instancetype)initWithEvents:(NSArray *)events promises:(NSArray *)promises {
    self = [super init];
    if (self) {
        _events = events;
        _promises = promises;
    }
    return self;
}

- (NSURL *)requestURL {
    BADomainManager *manager = [BAInjection injectProtocol:@protocol(BADomainManagerProtocol)];
    NSString *host = [manager urlFor:BADomainServiceWeb
                overrideWithOriginal:[manager canCheckOriginalDomainAvalaibility]];
    return [BAWebserviceURLBuilder webserviceURLForHost:host shortname:self.requestShortIdentifier];
}

- (NSString *)requestIdentifier {
    return @"track";
}

- (NSString *)requestShortIdentifier {
    return kParametersTrackingWebserviceShortname;
}

- (NSArray<id<BAWSQuery>> *)queriesToSend {
    BAWSQueryTracking *query = [[BAWSQueryTracking alloc] initWithEvents:_events];
    return @[ query ];
}

- (nullable BAWSResponse *)responseForQuery:(BAWSQuery *)query content:(NSDictionary *)content {
    if ([query isKindOfClass:[BAWSQueryTracking class]]) {
        return [[BAWSResponseTracking alloc] initWithResponse:content];
    }
    return nil;
}

- (void)webserviceClient:(nonnull BAQueryWebserviceClient *)client didFailWithError:(nonnull NSError *)error {
    // Ensure to correctly delay if the orignal domain isn't available at the moment
    BADomainManager *manager = [BAInjection injectProtocol:@protocol(BADomainManagerProtocol)];
    if ([manager canCheckOriginalDomainAvalaibility]) {
        [manager updateLastCheckDomainDate];
    }

    // Promises will notify the caller directly, no need to inform the global tracker.
    // This is especially useful for the opted-out event tracker
    // One day, this will evolve to only work with promises
    if (_promises) {
        for (BAPromise *promise in _promises) {
            [promise reject:nil];
        }
    } else {
        [[BATrackerCenter scheduler] trackingWebserviceDidFail:error forEvents:_events];
    }
}

- (void)webserviceClient:(nonnull BAQueryWebserviceClient *)client
    didSucceedWithResponses:(nonnull NSArray<id<BAWSResponse>> *)responses {
    // Update the domain if the original one is now available
    BADomainManager *manager = [BAInjection injectProtocol:@protocol(BADomainManagerProtocol)];
    if ([manager canCheckOriginalDomainAvalaibility]) {
        [manager resetDomainToOriginal];
    }

    if (_promises) {
        for (BAPromise *promise in _promises) {
            [promise resolve:nil];
        }
    } else {
        [[BATrackerCenter scheduler] trackingWebserviceDidSucceedForEvents:_events];
    }
}

@end
