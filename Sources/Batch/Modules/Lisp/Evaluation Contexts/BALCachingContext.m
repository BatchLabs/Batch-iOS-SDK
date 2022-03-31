//
//  BALCachingContext.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BALCachingContext.h>

@implementation BALCachingContext {
    NSMutableDictionary *_cache;
    id<BALEvaluationContext> _context;
}

+ (instancetype)cachingContextWithContext:(id<BALEvaluationContext>)context {
    return [[BALCachingContext alloc] initWithContext:context];
}

- (instancetype)initWithContext:(id<BALEvaluationContext>)context {
    self = [super init];
    if (self) {
        _cache = [NSMutableDictionary new];
        _context = context;
    }
    return self;
}

- (nullable BALValue *)resolveVariableNamed:(NSString *)name {
    id cachedValue = _cache[name];
    if (cachedValue == [NSNull null]) {
        // Cache hit, but it was nil
        return nil;
    } else if (cachedValue != nil) {
        return cachedValue;
    }

    BALValue *resolved = [_context resolveVariableNamed:name];

    if (resolved != nil) {
        _cache[name] = resolved;
    } else {
        _cache[name] = [NSNull null];
    }

    return resolved;
}

@end
