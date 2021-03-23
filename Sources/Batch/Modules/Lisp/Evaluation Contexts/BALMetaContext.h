//
//  BALMetaContext.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALEvaluationContext.h>

NS_ASSUME_NONNULL_BEGIN
/**
 Context wrapper that's an union of multiple contexts
 
 It should be initialized with the contextes in order of priority: first one to give a non "nil"
 (not to be confused with a BALPrimitiveValue with a nil type, which is considered a result)
 will "win".
 */
@interface BALMetaContext : NSObject <BALEvaluationContext>

+ (instancetype)metaContextWithContexts:(NSArray<id<BALEvaluationContext>>*)contexts;

- (instancetype)initWithContexts:(NSArray<id<BALEvaluationContext>>*)contexts;

@end

NS_ASSUME_NONNULL_END
