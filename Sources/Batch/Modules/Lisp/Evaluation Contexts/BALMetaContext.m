//
//  BALMetaContext.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BALMetaContext.h>

@implementation BALMetaContext
{
    NSArray<id<BALEvaluationContext>>* _contexts;
}

+ (instancetype)metaContextWithContexts:(NSArray<id<BALEvaluationContext>>*)contexts
{
    return [[BALMetaContext alloc] initWithContexts:contexts];
}

- (instancetype)initWithContexts:(NSArray<id<BALEvaluationContext>>*)contexts
{
    self = [super init];
    if (self) {
        _contexts = [contexts copy];
    }
    return self;
}

- (nullable BALValue *)resolveVariableNamed:(nonnull NSString *)name
{
    BALValue *val = nil;
    for (id<BALEvaluationContext> ctx in _contexts)
    {
        val = [ctx resolveVariableNamed:name];
        if (val != nil) {
            return val;
        }
    }
    return nil;
}

@end
