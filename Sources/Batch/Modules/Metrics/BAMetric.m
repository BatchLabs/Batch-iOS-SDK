//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//
#import <Batch/BACounter.h>
#import <Batch/BAInjection.h>
#import <Batch/BAMetric.h>
#import <Batch/BAMetricManager.h>

#define LOGGER_DOMAIN @"BAMetric"

@implementation BAMetric

#pragma mark - Instance setup

- (instancetype)initWithName:(nonnull NSString *)name {
    self = [super init];
    if (self) {
        _name = name;
        _type = [self type];
        _children = [NSMutableDictionary dictionary];
        _values = [NSMutableArray array];
    };
    return self;
}

- (instancetype)initWithName:(nonnull NSString *)name andLabelNames:(nonnull NSString *)firstLabel, ... {
    self = [super init];
    if (self) {
        _name = name;
        _type = [self type];
        _children = [NSMutableDictionary dictionary];
        _values = [NSMutableArray array];
        _labelNames = [NSMutableArray array];
        NSString *label;
        va_list argumentList;
        if (firstLabel) {
            [_labelNames addObject:firstLabel];
            va_start(argumentList, firstLabel);
            while ((label = va_arg(argumentList, id)) != nil) {
                [_labelNames addObject:label];
            }
            va_end(argumentList);
        }
    };
    return self;
}

- (instancetype)initWithName:(nonnull NSString *)name
           andLabelNamesList:(nonnull NSMutableArray<NSString *> *)labelNames {
    self = [super init];
    if (self) {
        _name = name;
        _type = [self type];
        _children = [NSMutableDictionary dictionary];
        _values = [NSMutableArray array];
        _labelNames = labelNames;
    };
    return self;
}

#pragma mark - Metric Methods

- (id)registerMetric {
    [[BAInjection injectClass:BAMetricManager.class] addMetric:self];
    return self;
}

- (id)labels:(nonnull NSArray<NSString *> *)args {
    NSMutableArray *labels = [NSMutableArray array];
    NSString *firstLabel = args.firstObject;

    if (firstLabel) {
        [labels addObject:firstLabel];
        for (NSUInteger i = 1; i < args.count; i++) {
            NSString *label = args[i];
            [labels addObject:label];
        }
    }
    id child = [_children objectForKey:labels];
    if (child == nil) {
        child = [self newChild:labels];
        [_children setObject:child forKey:labels];
    }
    return child;
}

- (BOOL)hasChildren {
    return [_children count] > 0;
}

- (BOOL)hasChanged {
    return [_values count] > 0;
}

- (void)update {
    [[BAInjection injectClass:BAMetricManager.class] sendMetrics];
}

#pragma mark - BAMetricProtocol methods (must be override in a subclass)

- (id)newChild:(NSArray<NSString *> *)labels {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

- (void)reset {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

#pragma mark - Serialization methods

- (nonnull NSDictionary *)toDictionary {
    NSMutableDictionary *metricDict = [NSMutableDictionary dictionary];
    [metricDict setObject:_name forKey:@"name"];
    [metricDict setObject:_type forKey:@"type"];
    [metricDict setObject:_values forKey:@"values"];
    if (_labelNames != nil && _labelValues != nil && [_labelNames count] == [_labelValues count]) {
        NSMutableDictionary *labelsDict = [NSMutableDictionary dictionary];
        unsigned long i, size = [_labelNames count];
        for (i = 0; i < size; i++) {
            [labelsDict setObject:[_labelValues objectAtIndex:i] forKey:[_labelNames objectAtIndex:i]];
        }
        [metricDict setObject:labelsDict forKey:@"labels"];
    }
    return metricDict;
}

#pragma mark - NSCopying methods

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    BAMetric *copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy->_name = _name;
        copy->_type = _type;
        copy->_values = [_values mutableCopy];
        copy->_labelNames = [_labelNames mutableCopy];
        copy->_labelValues = [_labelValues mutableCopy];
        copy->_children = [_children mutableCopy];
    }
    return copy;
}

@end
