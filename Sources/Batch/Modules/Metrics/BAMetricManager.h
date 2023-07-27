//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMetric.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAMetricManager : NSObject

/// Singleton shared instance
+ (instancetype)sharedInstance;

/// Add a metric to the registered metric list
- (void)addMetric:(BAMetric *)metric;

/// Send metrics that have changed
- (void)sendMetrics;

@end

NS_ASSUME_NONNULL_END
