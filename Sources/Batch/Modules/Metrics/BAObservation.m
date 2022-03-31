//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BAObservation.h"

@interface BAObservation (Protected)

/// Protected method from BAMetric
- (void)update;

@end

@implementation BAObservation {
    /// Start time
    NSNumber *_startTime;
}

#pragma mark - BAMetricProtocol methods

- (BAMetric *)newChild:(nonnull NSMutableArray<NSString *> *)labels {
    BAObservation *observation = [[BAObservation alloc] initWithName:super.name andLabelNamesList:[super labelNames]];
    observation.labelValues = labels;
    return observation;
}

- (void)reset {
    [[super values] removeAllObjects];
    [[super children] removeAllObjects];
}

- (NSString *)type {
    return @"observation";
}

#pragma mark - BAObservation methods

- (void)startTimer {
    _startTime = @(floor([[NSDate date] timeIntervalSince1970] * 1000));
}

- (void)observeDuration {
    NSNumber *now = @(floor([[NSDate date] timeIntervalSince1970] * 1000));
    float delta = [now doubleValue] - [_startTime doubleValue];
    [[super values] addObject:[NSNumber numberWithFloat:(float)delta / 1000]];
    [self update];
}

#pragma mark - NSCopying methods

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    BAObservation *copy = [super copyWithZone:zone];
    copy->_startTime = _startTime;
    return copy;
}

@end
