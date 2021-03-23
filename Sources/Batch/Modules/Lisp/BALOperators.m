//
//  Operators.m
//  BatchObjLisp
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Batch/BALOperators.h>

@implementation BALOperator

- (instancetype)initWithSymbol:(NSString*)symbol handler:(BALOperatorHandler)handler;
{
    self = [super init];
    if (self) {
        self.symbol = symbol;
        self.handler = handler;
    }
    return self;
}

@end

@implementation BALOperatorProvider
{
    NSMutableDictionary<NSString*, BALOperator*>* _operators;
    NSNumberFormatter *_numberFormatter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operators = [NSMutableDictionary new];
        [self setupOperators];
    }
    return self;
}

- (void)setupOperators
{
    // (if condition then else?)
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"if"
                                 handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                     NSUInteger nbArgs = values.count;
                                     if (nbArgs < 2 || nbArgs > 3) {
                                         return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"if: should be called with 2 or 3 arguments"];
                                     }
                                     
                                     BALPrimitiveValue *trueValue = values[1];
                                     BALPrimitiveValue *falseValue;
                                     if (nbArgs == 3) {
                                         falseValue = values[2];
                                     } else {
                                         falseValue = [BALPrimitiveValue nilValue];
                                     }
                                     
                                     BALPrimitiveValue *condition = values[0];
                                     if (condition.type == BALPrimitiveValueTypeNil) {
                                         return falseValue;
                                     } else if (condition.type == BALPrimitiveValueTypeBool) {
                                         if (![condition.value isKindOfClass:[NSNumber class]]) {
                                             return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:@"if: internal consistency error: boolean value should have an underlying NSNumber"];
                                         }
                                         return [(NSNumber*)condition.value boolValue] ? trueValue : falseValue;
                                     } else {
                                         return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"if: condition should be nil or a boolean value"];
                                     }
                                 }]];
    
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"and"
                              handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                  if ([values count] == 0) {
                                      return [BALPrimitiveValue valueWithBoolean:true];
                                  }
                                  
                                  for (BALPrimitiveValue *atomValue in values) {
                                      if (atomValue.type == BALPrimitiveValueTypeNil) {
                                          // Nil values are like false
                                          return [BALPrimitiveValue valueWithBoolean:false];
                                      }
                                      
                                      NSNumber *value = atomValue.value;
                                      if (atomValue.type != BALPrimitiveValueTypeBool || ![value isKindOfClass:[NSNumber class]]) {
                                          return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"and: Cannot compare non boolean values"];
                                      }
                                      
                                      if (![value boolValue]) {
                                          return [BALPrimitiveValue valueWithBoolean:false];
                                      }
                                  }
                                  
                                  return [BALPrimitiveValue valueWithBoolean:true];
    }]];
    
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"or"
                              handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                  if ([values count] == 0) {
                                      return [BALPrimitiveValue valueWithBoolean:true];
                                  }
                                  
                                  for (BALPrimitiveValue *atomValue in values) {
                                      if (atomValue.type == BALPrimitiveValueTypeNil) {
                                          // Nil values are like false
                                          continue;
                                      }
                                      
                                      NSNumber *value = atomValue.value;
                                      if (atomValue.type != BALPrimitiveValueTypeBool || ![value isKindOfClass:[NSNumber class]]) {
                                          return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"or: Cannot compare non boolean values"];
                                      }
                                      
                                      if ([value boolValue]) {
                                          return [BALPrimitiveValue valueWithBoolean:true];
                                      }
                                  }
                                  
                                  return [BALPrimitiveValue valueWithBoolean:false];
                              }]];
    
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"="
                              handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                  if ([values count] <= 1) {
                                      return [BALPrimitiveValue valueWithBoolean:true];
                                  }
                                  
                                  BALPrimitiveValue *firstAtomValue = values[0];
                                  id firstValue = firstAtomValue.value;
                                  if (firstAtomValue == nil) {
                                      return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:@"=: first value shouldn't be nil"];
                                  }
                                  
                                  for (int i = 1; i < values.count; i++) {
                                      BALPrimitiveValue *atomValue = values[i];
                                      
                                      if (atomValue == nil) {
                                          return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:@"=: value can't be nil. Are we out of bounds?"];
                                      }
                                      
                                      if (firstAtomValue.type != atomValue.type) {
                                          return [BALPrimitiveValue valueWithBoolean:false];
                                      }
                                      
                                      id value = atomValue.value;
                                      
                                      if (firstValue == value) { // Handles 'nil' and static strings
                                          continue;
                                      }
                                      
                                      if (![firstValue isEqual:value]) {
                                          return [BALPrimitiveValue valueWithBoolean:false];
                                      }
                                  }
                                  
                                  return [BALPrimitiveValue valueWithBoolean:true];
                              }]];
    
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"not"
                              handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                  if ([values count] != 1) {
                                      return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"not: only accepts one argument"];
                                  }
                                  
                                  BALPrimitiveValue *firstAtomValue = values[0];
                                  if (firstAtomValue.type != BALPrimitiveValueTypeBool) {
                                      return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"not: argument should be a boolean"];
                                  }
                                  
                                  id firstValue = firstAtomValue.value;
                                  if (![firstValue isKindOfClass:[NSNumber class]]) {
                                      return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:@"not: first value should be a NSNumber"];
                                  }
                                  
                                  return [BALPrimitiveValue valueWithBoolean:![(NSNumber*)firstValue boolValue]];
                              }]];
    
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@">"
                              handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                  return [self performNumberOperation:^BOOL(NSNumber *referenceValue, NSNumber *currentValue) {
                                      return [referenceValue compare:currentValue] == NSOrderedDescending;
                                  }
                                                               values:values
                                                       operatorSymbol:@">"];
                              }]];
    
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@">="
                              handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                  return [self performNumberOperation:^BOOL(NSNumber *referenceValue, NSNumber *currentValue) {
                                      NSComparisonResult comp = [referenceValue compare:currentValue];
                                      return comp == NSOrderedDescending || comp == NSOrderedSame;
                                  }
                                                               values:values
                                                       operatorSymbol:@">="];
                              }]];
    
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"<"
                              handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                  return [self performNumberOperation:^BOOL(NSNumber *referenceValue, NSNumber *currentValue) {
                                      return [referenceValue compare:currentValue] == NSOrderedAscending;
                                  }
                                                               values:values
                                                       operatorSymbol:@"<="];
                              }]];
    
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"<="
                              handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                  return [self performNumberOperation:^BOOL(NSNumber *referenceValue, NSNumber *currentValue) {
                                      NSComparisonResult comp = [referenceValue compare:currentValue];
                                      return comp == NSOrderedAscending || comp == NSOrderedSame;
                                  }
                                                               values:values
                                                       operatorSymbol:@"<="];
                              }]];
    
    // Contains takes two arguments:
    //  - First is a set. If the argument is a string, it is automatically converted to a set
    //  - Second is a set (the searched one)
    // It returns true if the second set contains ANY of the elements of the first set.
    //
    // Basically executes -[NSSet intersectsSet:] with safety and type checks
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"contains"
                              handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                  if ([values count] != 2) {
                                      return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"contains: only accepts two arguments"];
                                  }
                                  
                                  // The set that the target should contain
                                  BALPrimitiveValue *wantedSetPrimitive = values[0];
                                  // Automatically convert string primitives
                                  if (wantedSetPrimitive.type == BALPrimitiveValueTypeString) {
                                      wantedSetPrimitive = [BALPrimitiveValue valueWithStringSet:[NSSet setWithObject:wantedSetPrimitive.value]];
                                  }
                                  
                                  // The set that should contains the wanted values
                                  BALPrimitiveValue *targetSetPrimitive = values[1];
                                  // If the searched set is nil, return false
                                  if (targetSetPrimitive.type == BALPrimitiveValueTypeNil) {
                                      return [BALPrimitiveValue valueWithBoolean:false];
                                  }
                                  
                                  if (wantedSetPrimitive.type != BALPrimitiveValueTypeStringSet ||
                                      targetSetPrimitive.type != BALPrimitiveValueTypeStringSet) {
                                      return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"contains: all arguments should be string sets"];
                                  }
                                  
                                  NSSet *wantedSet = wantedSetPrimitive.value;
                                  NSSet *targetSet = targetSetPrimitive.value;
                                  
                                  if (![wantedSet isKindOfClass:[NSSet class]] ||
                                      ![targetSet isKindOfClass:[NSSet class]]) {
                                      return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:@"contains: internal consistency error: all arguments should be of underlying type NSSet"];
                                  }
                                  
                                  return [BALPrimitiveValue valueWithBoolean:[wantedSet intersectsSet:targetSet]];
                              }]];
    
    // ContainsAll takes two arguments:
    //  - First is a set. If the argument is a string, it is automatically converted to a set
    //  - Second is a set (the searched one)
    // It returns true if the second set contains ALL of the elements of the first set.
    //
    // Basically executes -[NSSet isSubsetOfSet:] with safety and type checks
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"containsAll"
                              handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                  if ([values count] != 2) {
                                      return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"contains: only accepts two arguments"];
                                  }
                                  
                                  // The set that the target should contain
                                  BALPrimitiveValue *wantedSetPrimitive = values[0];
                                  // Automatically convert string primitives
                                  if (wantedSetPrimitive.type == BALPrimitiveValueTypeString) {
                                      wantedSetPrimitive = [BALPrimitiveValue valueWithStringSet:[NSSet setWithObject:wantedSetPrimitive.value]];
                                  }
                                  
                                  // The set that should contains the wanted values
                                  BALPrimitiveValue *targetSetPrimitive = values[1];
                                  // If the searched set is nil, return false
                                  if (targetSetPrimitive.type == BALPrimitiveValueTypeNil) {
                                      return [BALPrimitiveValue valueWithBoolean:false];
                                  }
                                  
                                  if (wantedSetPrimitive.type != BALPrimitiveValueTypeStringSet ||
                                      targetSetPrimitive.type != BALPrimitiveValueTypeStringSet) {
                                      return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"contains: all arguments should be string sets"];
                                  }
                                  
                                  NSSet *wantedSet = wantedSetPrimitive.value;
                                  NSSet *targetSet = targetSetPrimitive.value;
                                  
                                  if (![wantedSet isKindOfClass:[NSSet class]] ||
                                      ![targetSet isKindOfClass:[NSSet class]]) {
                                      return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:@"contains: internal consistency error: all arguments should be of underlying type NSSet"];
                                  }
                                  
                                  return [BALPrimitiveValue valueWithBoolean:[wantedSet isSubsetOfSet:targetSet]];
                              }]];
    
    // String and set manipulation operations
    
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"lower"
                                 handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                     return [self performStringOperation:^NSString *(NSString *valueToTransform) {
                                         return valueToTransform.lowercaseString;
                                     } values:values operatorName:@"lower"];
                                 }]];
    
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"upper"
                                 handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                     return [self performStringOperation:^NSString *(NSString *valueToTransform) {
                                         return valueToTransform.uppercaseString;
                                     } values:values operatorName:@"upper"];
                                 }]];
    
    // Casts
    
    // Returns the double value of a string
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"parse-string"
                                 handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                     if ([values count] != 1) {
                                         return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"parse-string: only accepts a string argument"];
                                     }
                                     
                                     BALPrimitiveValue *value = values[0];
                                     if (value.type == BALPrimitiveValueTypeNil) {
                                         return [BALPrimitiveValue nilValue];
                                     }
                                     
                                     if (value.type != BALPrimitiveValueTypeString) {
                                         return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"parse-string: only accepts a string argument"];
                                     }
                                     NSString *strToParse = value.value;
                                     
                                     return [BALPrimitiveValue valueWithDouble:[strToParse doubleValue]];
                                 }]];
    
    // Returns the string value of anything but a set
    // Returns a nil value for nil inputs
    [self addOperator:
     [[BALOperator alloc] initWithSymbol:@"write-to-string"
                                 handler:^BALValue* (id<BALEvaluationContext> _Nonnull context, NSArray<BALPrimitiveValue *> * _Nonnull values) {
                                     if ([values count] != 1) {
                                         return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"write-to-string: only accepts a single, non-set argument"];
                                     }
                                     
                                     BALPrimitiveValue *value = values[0];
                                     NSObject *valueToStringify = value.value;
                                     switch (value.type) {
                                         case BALPrimitiveValueTypeString:
                                             return value;
                                         case BALPrimitiveValueTypeNil:
                                             return [BALPrimitiveValue nilValue];
                                         case BALPrimitiveValueTypeBool:
                                             if (![valueToStringify isKindOfClass:[NSNumber class]]) {
                                                 return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:@"write-to-string: internal consistency error: argument should be of underlying type NSNumber"];
                                             }
                                             return [BALPrimitiveValue valueWithString:((NSNumber*) valueToStringify).boolValue ? @"true" : @"false"];
                                         case BALPrimitiveValueTypeDouble:
                                             if (![valueToStringify isKindOfClass:[NSNumber class]]) {
                                                 return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:@"write-to-string: internal consistency error: argument should be of underlying type NSNumber"];
                                             }
                                             return [BALPrimitiveValue valueWithString:[self stringifyNumber:(NSNumber*)valueToStringify]];
                                         case BALPrimitiveValueTypeStringSet:
                                         default:
                                             return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:@"write-to-string: only accepts a single, non-set argument"];
                                     }
                                 }]];
}

/**
 Perform a block on all values, after ensuring that all values are numbers
 Stops on first false comparaison
 */
- (BALValue*)performNumberOperation:(BOOL (^)(NSNumber* referenceValue, NSNumber* currentValue))operation
                          values:(NSArray<BALPrimitiveValue*>*)values
                  operatorSymbol:(NSString*)symbol
{
    if ([values count] < 2) {
        return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:[symbol stringByAppendingString:@": requires at least two arguments"]];
    }
    
    BALPrimitiveValue *referenceValue = values[0];
    if (referenceValue.type != BALPrimitiveValueTypeDouble) {
        return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:[symbol stringByAppendingString:@": arguments should be numbers"]];
    }
    NSNumber *referenceNumber = referenceValue.value;
    if (![referenceNumber isKindOfClass:[NSNumber class]]) {
        return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:[symbol stringByAppendingString:@": consistency error: underlying types should be NSNumbers"]];
    }
    
    for (int i = 1; i < values.count; i++) {
        BALPrimitiveValue *atomValue = values[i];
        
        if (atomValue == nil) {
            return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:[symbol stringByAppendingString:@": value can't be nil. Are we out of bounds?"]];
        }
        
        if (atomValue.type != BALPrimitiveValueTypeDouble) {
            return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:[symbol stringByAppendingString:@": arguments should be numbers"]];
        }
        
        if (![atomValue.value isKindOfClass:[NSNumber class]]) {
            return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:[symbol stringByAppendingString:@": consistency error: underlying types should be NSNumbers"]];
        }
        
        if (!operation(referenceNumber, atomValue.value)) {
            return [BALPrimitiveValue valueWithBoolean:false];
        }
    }
    
    return [BALPrimitiveValue valueWithBoolean:true];
}

/**
 Perform a block on a string or every string in a string set
 
 Errors out if variable isn't a string/string set
 */
- (BALValue*)performStringOperation:(NSString* (^)(NSString* valueToTransform))operation
                             values:(NSArray<BALPrimitiveValue*>*)values
                       operatorName:(NSString*)operator
{
    if ([values count] != 1) {
        return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:[operator stringByAppendingString:@": requires only one string/set argument"]];
    }
    
    BALPrimitiveValue *referenceValue = values[0];
    NSObject *value = referenceValue.value;
    if (referenceValue.type == BALPrimitiveValueTypeNil) {
        return [BALPrimitiveValue nilValue];
    } else if (referenceValue.type == BALPrimitiveValueTypeString) {
        if (![value isKindOfClass:[NSString class]]) {
            return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:[operator stringByAppendingString:@": consistency error: underlying types should be NSString"]];
        }
        return [BALPrimitiveValue valueWithString:operation((NSString*)value)];
    } else if (referenceValue.type == BALPrimitiveValueTypeStringSet) {
        NSSet *setValue = (NSSet*)value;
        if (![setValue isKindOfClass:[NSSet class]]) {
            return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal message:[operator stringByAppendingString:@": consistency error: underlying types should be NSString"]];
        }
        
        NSMutableSet *resultSet = [NSMutableSet setWithCapacity:setValue.count];
        for (NSString *element in setValue) {
            [resultSet addObject:operation(element)];
        }
        return [BALPrimitiveValue valueWithStringSet:resultSet];
    }
    
    return [BALErrorValue errorWithKind:BALErrorValueKindTypeError message:[operator stringByAppendingString:@": argument should be a string or a set"]];
}

- (NSString*)stringifyNumber:(NSNumber*)number
{
    if (_numberFormatter == nil) {
        _numberFormatter = [NSNumberFormatter new];
        _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _numberFormatter.usesGroupingSeparator = false;
        _numberFormatter.groupingSeparator = @"";
        _numberFormatter.decimalSeparator = @".";
    }
    
    return [_numberFormatter stringFromNumber:number];
}

- (void)addOperator:(BALOperator*)operator
{
    _operators[operator.symbol.lowercaseString] = operator;
}

- (BALOperator*)operatorForSymbol:(NSString*)symbol
{
    return _operators[symbol];
}

@end

