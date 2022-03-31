//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//
#import <Batch/BAMetric.h>
#import <Batch/BACounter.h>
#import <Batch/BAMetricManager.h>
#import <Batch/BAInjection.h>


#define LOGGER_DOMAIN @"BAMetric"


@implementation BAMetric

#pragma mark  - Instance setup

- (instancetype)initWithName:(nonnull NSString*)name
{
    self = [super init];
    if (self) {
        _name = name;
        _type = [self type];
        _children = [NSMutableDictionary dictionary];
        _values = [NSMutableArray array];
    };
    return self;
}

- (instancetype)initWithName:(nonnull NSString*)name andLabelNames:(nonnull NSString*)firstLabel, ...
{
    self = [super init];
    if (self) {
        _name = name;
        _type = [self type];
        _children = [NSMutableDictionary dictionary];
        _values = [NSMutableArray array];
        _labelNames = [NSMutableArray array];
        NSString* label;
        va_list argumentList;
        if (firstLabel)
        {
            [_labelNames addObject: firstLabel];
            va_start(argumentList, firstLabel);
            while ((label = va_arg(argumentList, id)) != nil) {
                [_labelNames addObject: label];
            }
            va_end(argumentList);
        }
    };
    return self;
}

- (instancetype)initWithName:(nonnull NSString*)name andLabelNamesList:(nonnull NSMutableArray<NSString*>*) labelNames
{
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

#pragma mark  - Metric Methods

- (id)registerMetric {
    [[BAInjection injectClass:BAMetricManager.class] addMetric:self];
    return self;
}

- (id)labels:(nonnull NSString*)firstLabel, ...
{
    NSMutableArray* labels = [NSMutableArray array];
    NSString* label;
    va_list argumentList;
    if (firstLabel)
    {
        [labels addObject: firstLabel];
        va_start(argumentList, firstLabel);
        while ((label = va_arg(argumentList, id)) != nil) {
            [labels addObject: label];
        }
        va_end(argumentList);
    }
    id child =  [_children objectForKey:labels];
    if(child == nil){
        child = [self newChild:labels];
        [_children setObject:child forKey:labels];
    }
    return child;
}

- (BOOL)hasChildren
{
    return [_children count] > 0;
}

- (BOOL)hasChanged
{
    return [_values count] > 0;
}

- (void)update
{
    [[BAInjection injectClass:BAMetricManager.class] sendMetrics];
}

#pragma mark - BAMetricProtocol methods (must be override in a subclass)

- (id)newChild:(NSArray<NSString *> *)labels
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

- (void)reset
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

#pragma mark - MsgPack methods

- (BOOL)packToWriter:(nonnull BATMessagePackWriter *)writer error:(NSError **)error
{
    NSError *writerError;
    
    NSMutableDictionary *metricDict =[NSMutableDictionary dictionary];
    [metricDict setObject:_name forKey:@"name"];
    [metricDict setObject:_type forKey:@"type"];
    [metricDict setObject:_values forKey:@"values"];
    if(_labelNames != nil && _labelValues != nil && [_labelNames count] == [_labelValues count]) {
        NSMutableDictionary *labelsDict =[NSMutableDictionary dictionary];
        unsigned long i, size = [_labelNames count];
        for(i = 0; i < size; i++) {
            [labelsDict setObject:[_labelValues objectAtIndex:i] forKey:[_labelNames objectAtIndex:i]];
        }
        [metricDict setObject:labelsDict forKey:@"labels"];
    }
    [writer writeDictionary:metricDict error:&writerError];
    if (writerError != nil) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Could not pack metric"];
        if (error != nil) {
            *error = writerError;
        }
        return false;
    }
    return true;
}

- (nullable NSData *)pack:(NSError * _Nullable * _Nullable)error
{
    BATMessagePackWriter *writer = [BATMessagePackWriter new];
    if ([self packToWriter:writer error:error]) {
        return writer.data;
    }
    return nil;
}

#pragma mark - NSCopying methods

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    BAMetric *copy = [BAMetric new];
    copy->_name = _name;
    copy->_type = _type;
    copy->_values = [_values mutableCopy];
    copy->_labelNames = [_labelNames mutableCopy];
    copy->_labelValues = [_labelValues mutableCopy];
    copy->_children = [_children mutableCopy];
    return copy;
}

@end
