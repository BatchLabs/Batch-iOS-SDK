//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BACounter.h>

@interface BACounter (Protected)

/// Protected method from BAMetric
- (void)update;

@end

@implementation BACounter {
    /// Current counter value
    double _value;
}
#pragma mark - BAMetricProtocol methods

- (BAMetric *)newChild:(nonnull NSMutableArray<NSString *> *)labels {
    BACounter *counter = [[BACounter alloc] initWithName:super.name andLabelNamesList:[super labelNames]];
    counter.labelValues = labels;
    return counter;
}

- (void)reset {
    _value = 0;
    [[super values] removeAllObjects];
    [[super children] removeAllObjects];
}

- (NSString *)type {
    return @"counter";
}

#pragma mark - BACounter methods

- (void)increment {
    _value++;
    [[super values] removeAllObjects];
    [[super values] addObject:[NSNumber numberWithDouble:_value]];
    [self update];
}

#pragma mark - NSCopying methods

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    BACounter *copy = [super copyWithZone:zone];
    copy->_value = _value;
    return copy;
}

@end
