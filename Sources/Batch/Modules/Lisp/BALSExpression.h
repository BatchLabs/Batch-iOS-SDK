//
//  SExpression.h
//  BatchObjLisp
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BALValues.h>

@class BALEvaluationContext;

NS_ASSUME_NONNULL_BEGIN

/**
 A S-Expression is an executable list
 */

@interface BALSExpression : BALValue <BALReducable>

@property (readonly) NSArray<BALValue*>* values;

+ (instancetype)expressionWithValues:(NSArray<BALValue*>*)expressions;

@end

NS_ASSUME_NONNULL_END
