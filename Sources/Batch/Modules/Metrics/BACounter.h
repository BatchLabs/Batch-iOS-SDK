//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//
#import <Batch/BAMetric.h>
#import <Foundation/Foundation.h>

@interface BACounter : BAMetric

/// Increment the counter value
- (void)increment;

/// Reset the counter value
- (void)reset;

@end
