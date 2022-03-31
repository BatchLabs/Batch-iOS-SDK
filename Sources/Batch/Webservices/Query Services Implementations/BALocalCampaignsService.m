//
//  BALocalCampaignsService.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BALocalCampaignsService.h>

#import <Batch/BAInjection.h>
#import <Batch/BALogger.h>
#import <Batch/BAWebserviceURLBuilder.h>

#import <Batch/BALocalCampaignsCenter.h>

#import <Batch/BAMetricRegistry.h>
#import <Batch/BAWSQueryLocalCampaigns.h>
#import <Batch/BAWSResponseLocalCampaigns.h>

#import <Batch/BALocalCampaignCountedEvent.h>

@interface BALocalCampaignsServiceDatasource () {
    NSDictionary<NSString *, BALocalCampaignCountedEvent *> *_viewEvents;
}
@end

@implementation BALocalCampaignsServiceDatasource

- (instancetype)initWithViewEvents:(nullable NSDictionary<NSString *, BALocalCampaignCountedEvent *> *)viewEvents;
{
    self = [super init];
    if (self) {
        _viewEvents = viewEvents;
    }
    return self;
}

- (NSURL *)requestURL {
    return [BAWebserviceURLBuilder webserviceURLForShortname:self.requestShortIdentifier];
}

- (NSString *)requestIdentifier {
    return @"localCampaigns";
}

- (NSString *)requestShortIdentifier {
    return @"local";
}

- (NSArray<id<BAWSQuery>> *)queriesToSend {
    BAWSQueryLocalCampaigns *query = [[BAWSQueryLocalCampaigns alloc] initWithViewEvents:_viewEvents];
    return @[ query ];
}

- (nullable BAWSResponse *)responseForQuery:(BAWSQuery *)query content:(NSDictionary *)content {
    if ([query isKindOfClass:[BAWSQueryLocalCampaigns class]]) {
        return [[BAWSResponseLocalCampaigns alloc] initWithResponse:content];
    }
    return nil;
}

@end

@interface BALocalCampaignsServiceDelegate () {
    BALocalCampaignsCenter *_lcCenter;
    BAMetricRegistry *_metricRegistry;
}

@end

@implementation BALocalCampaignsServiceDelegate

- (instancetype)initWithLocalCampaignsCenter:(BALocalCampaignsCenter *)center {
    self = [super init];
    if (self) {
        _lcCenter = center;
        _metricRegistry = [BAInjection injectClass:BAMetricRegistry.class];
    }
    return self;
}

- (void)webserviceClientWillStart:(BAQueryWebserviceClient *)client {
    [[_metricRegistry localCampaignsSyncResponseTime] startTimer];
}

- (void)webserviceClient:(BAQueryWebserviceClient *)client didFailWithError:(NSError *)error {
    [[_metricRegistry localCampaignsSyncResponseTime] observeDuration];
    [_lcCenter localCampaignsWebserviceDidFinish];
}

- (void)webserviceClient:(BAQueryWebserviceClient *)client
    didSucceedWithResponses:(NSArray<id<BAWSResponse>> *)responses {
    [[_metricRegistry localCampaignsSyncResponseTime] observeDuration];
    for (BAWSResponse *response in responses) {
        if ([response isKindOfClass:[BAWSResponseLocalCampaigns class]]) {
            [self handleLocalCampaignsResponse:(BAWSResponseLocalCampaigns *)response];
        }
    }
    [_lcCenter localCampaignsWebserviceDidFinish];
}

- (void)handleLocalCampaignsResponse:(BAWSResponseLocalCampaigns *)response {
    if (response == nil || response.payload == nil) {
        [BALogger errorForDomain:@"Local Campaigns"
                         message:@"An error occurred while handling the local campaigns query response."];
        return;
    }

    [_lcCenter handleWebserviceResponsePayload:response.payload];
}

@end
