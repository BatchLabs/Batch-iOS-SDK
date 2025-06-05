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

/// Count dns errors
- (BACounter *)dnsErrorCount;

/// Count loading image error
- (BACounter *)downloadingImageErrorCount;

/// New observation for download image time
- (BAObservation *)registerNewDownloadImageDurationMetric;

@end

NS_ASSUME_NONNULL_END
