//
//  SExpression.m
//  BatchObjLisp
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Batch/BALOperators.h>
#import <Batch/BALSExpression.h>

@implementation BALSExpression

- (instancetype)initWithValues:(NSArray<BALValue *> *)values;
{
    self = [super init];
    if (self) {
        _values = [values copy];
    }
    return self;
}

+ (instancetype)expressionWithValues:(NSArray<BALValue *> *)values {
    return [[BALSExpression alloc] initWithValues:values];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[BALSExpression class]]) {
        return NO;
    } else {
        return [self.values isEqualToArray:((BALSExpression *)other).values];
    }
}

- (nonnull BALValue *)reduce:(nonnull id<BALEvaluationContext>)context {
    if ([_values count] == 0) {
        return [BALPrimitiveValue nilValue];
    }

    BALValue *firstValue = _values[0];
    if (![firstValue isKindOfClass:[BALOperatorValue class]]) {
        return [BALErrorValue errorWithKind:BALErrorValueKindTypeError
                                    message:@"S-Expressions should have an operator as their first value"];
    }

    NSMutableArray<BALPrimitiveValue *> *arguments =
        [[NSMutableArray alloc] initWithCapacity:MAX(0, _values.count - 1)];
    for (int i = 1; i < _values.count; i++) {
        BALValue *val = _values[i];
        if ([val conformsToProtocol:@protocol(BALReducable)]) {
            val = [(id<BALReducable>)val reduce:context];
        }

        if (val == nil) {
            return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal
                                        message:@"Unexpected nil value while reducing S-Expression"];
        }

        if ([val isKindOfClass:[BALErrorValue class]]) {
            return val;
        }

        if (![val isKindOfClass:[BALPrimitiveValue class]]) {
            return [BALErrorValue
                errorWithKind:BALErrorValueKindTypeInternal
                      message:@"Error while reducing S-Expression: at this point, value should be a PrimitiveValue"];
        }

        [arguments addObject:(BALPrimitiveValue *)val];
    }

    BALOperator *operator=((BALOperatorValue *)firstValue).operator;

    if (operator== nil) {
        return [BALErrorValue errorWithKind:BALErrorValueKindTypeInternal
                                    message:@"Can't reduce a S-Expression with a nil operator"];
    }

    return operator.handler(context, arguments);
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString new];

    [desc appendString:@"("];

    for (int i = 0; i < _values.count; i++) {
        if (i != 0) {
            [desc appendFormat:@" "];
        }

        [desc appendString:[_values[i] description]];
    }

    [desc appendString:@")"];

    return desc;
}

- (NSString *)debugDescription {
    NSMutableString *desc = [NSMutableString new];

    [desc appendString:@"\n"];
    [desc appendString:@"("];

    for (int i = 0; i < _values.count; i++) {
        [desc appendString:@"\n\t"];

        NSString *subDesc = [_values[i] debugDescription];
        if ([subDesc hasPrefix:@"\n"]) {
            subDesc = [subDesc stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        subDesc = [subDesc stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];

        [desc appendString:subDesc];
    }

    [desc appendString:@"\n"];
    [desc appendString:@")"];

    return desc;
}

@end
