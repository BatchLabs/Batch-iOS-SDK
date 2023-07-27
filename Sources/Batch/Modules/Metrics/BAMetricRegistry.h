//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BACounter.h>
#import <Batch/BAObservation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAMetricRegistry : NSObject

@property (nonnull, readonly, class) BAMetricRegistry *instance;

/// Observe local campaigns JIT response time
- (BAObservation *)localCampaignsJITResponseTime;

/// Count local campaign ws calls by status ("OK", "KO")
- (BACounter *)localCampaignsJITCount;

/// Observe local campaigns sync response time
- (BAObservation *)localCampaignsSyncResponseTime;

@end

NS_ASSUME_NONNULL_END
