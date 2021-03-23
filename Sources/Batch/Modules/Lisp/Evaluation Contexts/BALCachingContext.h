//
//  BALCachingContext.h
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALEvaluationContext.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Wrapper context that adds a caching layer
 
 This is NOT thread safe
 */
@interface BALCachingContext : NSObject <BALEvaluationContext>

+ (instancetype)cachingContextWithContext:(id<BALEvaluationContext>)context;

- (instancetype)initWithContext:(id<BALEvaluationContext>)context;

@end

NS_ASSUME_NONNULL_END
