//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <Batch/BAMetric.h>

@interface BACounter : BAMetric

/// Increment the counter value
- (void)increment;

/// Reset the counter value
- (void)reset;

@end
