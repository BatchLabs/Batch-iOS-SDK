//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BAMetricRegistry.h"

@implementation BAMetricRegistry
{
    BAObservation *_localCampaignsJITResponseTime;
    
    BACounter *_localCampaignsJITCount;
    
    BAObservation *_localCampaignsSyncResponseTime;

}

- (instancetype)init
{
    self = [super init];
    if ([BANullHelper isNull:self]) {
        return self;
    }
    [self registerMetrics];
    return self;
}

+ (instancetype)instance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void) registerMetrics
{
    _localCampaignsJITResponseTime = [[[BAObservation alloc] initWithName:@"sdk_local_campaigns_jit_ws_duration"] registerMetric];
    
    _localCampaignsJITCount = [[[BACounter alloc] initWithName:@"sdk_local_campaigns_jit_ws_count" andLabelNames: @"status", nil] registerMetric];
    
    _localCampaignsSyncResponseTime = [[[BAObservation alloc] initWithName:@"sdk_local_campaigns_sync_ws_duration"] registerMetric];

}

- (BAObservation*)localCampaignsJITResponseTime
{
    return _localCampaignsJITResponseTime;
}

- (BACounter*)localCampaignsJITCount
{
    return _localCampaignsJITCount;
}

- (BAObservation*)localCampaignsSyncResponseTime
{
    return _localCampaignsSyncResponseTime;
}

@end
