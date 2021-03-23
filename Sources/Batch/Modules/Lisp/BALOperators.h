//
//  Operators.h
//  BatchObjLisp
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALEvaluationContext.h>
#import <Batch/BALValues.h>

NS_ASSUME_NONNULL_BEGIN

typedef BALValue* _Nonnull (^BALOperatorHandler)(id<BALEvaluationContext> context, NSArray<BALPrimitiveValue*>* values);

@interface BALOperator : NSObject

@property NSString *symbol;
@property BALOperatorHandler handler;

- (instancetype)initWithSymbol:(NSString*)symbol handler:(BALOperatorHandler)handler;

@end

@interface BALOperatorProvider : NSObject

- (BALOperator*)operatorForSymbol:(NSString*)symbol;

@end

NS_ASSUME_NONNULL_END
