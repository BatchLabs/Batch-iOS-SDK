//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMetric.h>
#import <Foundation/Foundation.h>
@interface BAObservation : BAMetric

/// Increment the observation value
- (void)startTimer;

/// Observe the duration since startTimer has been called
- (void)observeDuration;

/// Reset the observation value
- (void)reset;

@end
