//
//  Atoms.h
//  BatchObjLisp
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BALOperator;
@protocol BALEvaluationContext;

NS_ASSUME_NONNULL_BEGIN

/**
 Root of everything.
 
 Everything in our LISP is a Value.
 
 A value is abstract, but has different concrete implementations:
 - SExpression: An executable list of values, which should always begin by a Operator, if not empty
 - Variable: A variable reference
 - Error: An error, described by kind and message. Errors should bubble as soon as possible
 - Primitive: A primitive value (Nil, Double, Bool, String, String Array)
 - Operator: A builtin function
 
 Reducable values are not usuable as-is, and must be resolved to get a primitive value.
 Reducing SExpressions is how you compute a result, as the program's root must be a S-Expression.
 Operators cannot be reduced, and must only be used as the first value of a S-Expression
 
 Please note that all concepts here are the result of our take on LISP, and might be different than existing
 implementations.
 */
@interface BALValue: NSObject
@end

/**
 Defines reducable values
 
 A reducable value can be reduced to another Value (usually a Primitive or Error)
 */
@protocol BALReducable <NSObject>

- (BALValue*)reduce:(id<BALEvaluationContext>)context;

@end

#pragma mark Values definitions

typedef NS_ENUM(NSUInteger, BALErrorValueKind) {
    BALErrorValueKindTypeInternal,
    BALErrorValueKindTypeError,
    BALErrorValueKindTypeParser,
};

@interface BALErrorValue : BALValue

@property (readonly) BALErrorValueKind kind;
@property (readonly) NSString *message;

+ (instancetype)errorWithKind:(BALErrorValueKind)kind message:(NSString*)message;

@end

typedef NS_ENUM(NSUInteger, BALPrimitiveValueType) {
    BALPrimitiveValueTypeNil,
    BALPrimitiveValueTypeString,
    BALPrimitiveValueTypeDouble,
    BALPrimitiveValueTypeBool,
    BALPrimitiveValueTypeStringSet,
};

@interface BALPrimitiveValue : BALValue

@property (readonly) BALPrimitiveValueType type;

@property (readonly, nullable) id value; // What could go wrong

+ (instancetype)nilValue;

+ (nullable instancetype)valueWithString:(NSString*)value;

+ (instancetype)valueWithDouble:(double)value;

+ (instancetype)valueWithBoolean:(BOOL)value;

+ (nullable instancetype)valueWithStringSet:(NSSet<NSString*>*)value;

@end

@interface BALOperatorValue : BALValue

@property (readonly) BALOperator *operator;

+ (instancetype)operatorValueWithOperator:(BALOperator*)operator;

@end

@interface BALVariableValue : BALValue <BALReducable>

@property (readonly) NSString *name;

+ (instancetype)variableWithName:(NSString*)name;

@end

NS_ASSUME_NONNULL_END
