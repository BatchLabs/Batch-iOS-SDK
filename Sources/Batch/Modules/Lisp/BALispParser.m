//
//  Parser.m
//  BatchObjLisp
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Batch/BALispParser.h>

#define TOKEN_DELIMITER_VARIABLE '`'
#define TOKEN_DELIMITER_STRING '"'
#define TOKEN_DELIMITER_LIST_START '('
#define TOKEN_DELIMITER_STRING_ARRAY_START '['

@implementation BALispParser {
    BOOL isConsumed;
    NSUInteger _pos; // NEVER access/modify this directly: always use getNextChar
    NSUInteger _maxPos;
    NSString *input;
    BOOL endReached;
    BALOperatorProvider *operators;
    NSNumberFormatter *numberFormatter;
}

- (instancetype)initWithExpression:(NSString *)expression {
    self = [super init];
    if (self) {
        isConsumed = false;
        input = [expression stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        _maxPos = MAX(0, input.length - 1);
        endReached = _maxPos == 0 ? true : false;
        _pos = 0;
        operators = [BALOperatorProvider new];
        numberFormatter = [NSNumberFormatter new];
        numberFormatter.allowsFloats = true;
        numberFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        numberFormatter.numberStyle = NSNumberFormatterNoStyle;
        numberFormatter.groupingSeparator = @",";
        numberFormatter.decimalSeparator = @".";
    }
    return self;
}

- (BALValue *)parse {
    if (isConsumed) {
        return [self errorWithMessage:@"This parser has already been consumed. Please instanciate a new one."];
    }

    isConsumed = true;

    if ([self getNextChar] == TOKEN_DELIMITER_LIST_START) {
        return [self parseList];
    }
    return [self errorWithPositionAndMessage:[NSString stringWithFormat:@"Expected %c", TOKEN_DELIMITER_LIST_START]];
}

- (unichar)getNextChar {
    if (endReached) {
        return '\0';
    }

    unichar c = [input characterAtIndex:_pos];
    if (_pos == _maxPos) {
        endReached = true;
    } else {
        _pos++;
    }
    return c;
}

- (BALValue *)parseList {
    // ( has already been consumed
    NSMutableArray<BALValue *> *values = [NSMutableArray new];
    NSMutableString *tokenAccumulator;

    while (!endReached) {
        unichar c = [self getNextChar];

        if (c == ')' || c == ' ') {
            // Both can mark the end of a symbol
            if (tokenAccumulator != nil) {
                // Unprefixed values can either be values or operators
                BALValue *tmpVal = [self parseSpecial:tokenAccumulator];

                if (tmpVal == nil) {
                    tmpVal = [self parseOperator:tokenAccumulator];
                }

                if (tmpVal == nil) {
                    tmpVal = [self parseNumber:tokenAccumulator];
                }

                if (tmpVal == nil) {
                    tmpVal = [self
                        errorWithMessage:[NSString stringWithFormat:@"Unknown symbol '%@': It is not an operator, and "
                                                                    @"it could not be converted to a number",
                                                                    tokenAccumulator]];
                }

                [values addObject:tmpVal];
                tokenAccumulator = nil;
            }

            if (c == ')') {
                for (BALValue *val in values) {
                    if ([val isKindOfClass:[BALErrorValue class]]) {
                        return val;
                    }
                }
                return [BALSExpression expressionWithValues:values];
            }
        } else if (c == TOKEN_DELIMITER_STRING) {
            [values addObject:[self parseString]];
        } else if (c == TOKEN_DELIMITER_VARIABLE) {
            [values addObject:[self parseVariable]];
        } else if (c == TOKEN_DELIMITER_LIST_START) {
            [values addObject:[self parseList]];
        } else if (c == TOKEN_DELIMITER_STRING_ARRAY_START) {
            [values addObject:[self parseStringArray]];
        } else {
            if (tokenAccumulator == nil) {
                tokenAccumulator = [NSMutableString new];
            }
            [tokenAccumulator appendString:[NSString stringWithCharacters:&c length:1]];
        }
    }

    return [self errorUnexpectedEOF:@")"];
}

- (BALValue *)parseStringArray {
    NSMutableSet<NSString *> *values = [NSMutableSet new];

    while (!endReached) {
        unichar c = [self getNextChar];

        if (c == ']') {
            return [BALPrimitiveValue valueWithStringSet:values];
        } else if (c == TOKEN_DELIMITER_STRING) {
            BALValue *stringValue = [self parseString];
            if ([stringValue isKindOfClass:[BALErrorValue class]]) {
                return stringValue;
            } else if ([stringValue isKindOfClass:[BALPrimitiveValue class]] &&
                       [(BALPrimitiveValue *)stringValue type] == BALPrimitiveValueTypeString &&
                       [[(BALPrimitiveValue *)stringValue value] isKindOfClass:[NSString class]]) {
                [values addObject:(NSString *)[(BALPrimitiveValue *)stringValue value]];
            } else {
                return
                    [self errorWithPositionAndMessage:
                              [NSString stringWithFormat:@"Internal parser error: value is not a string nor an error"]];
            }
        } else if (c != ' ') {
            return [self
                errorWithPositionAndMessage:
                    [NSString stringWithFormat:@"Unexpected character '%c' in string arary, expected \" or ]", c]];
        }
    }

    return [self errorUnexpectedEOF:@"]"];
}

- (BALValue *)parseString {
    NSMutableString *accumulator = [NSMutableString new];
    BOOL isEscaping = false;

    while (!endReached) {
        unichar c = [self getNextChar];

        if (isEscaping) {
            switch (c) {
                case '\\': // Actually /
                    c = '\\';
                    break;
                case 'n':
                    c = '\n';
                    break;
                case 't':
                    c = '\t';
                    break;
                case 'r':
                    c = '\r';
                    break;
                case '"':
                    c = '"';
                    break;
                case '\'': // Actually '
                    c = '\'';
                    break;
                default:
                    return [self
                        errorWithPositionAndMessage:[NSString stringWithFormat:@"Invalid escaped character: \\%c", c]];
            }

            isEscaping = false;
        } else if (c == '\\') {
            isEscaping = true;
            continue;
        } else if (c == TOKEN_DELIMITER_STRING) {
            return [BALPrimitiveValue valueWithString:accumulator];
        }

        [accumulator appendString:[NSString stringWithCharacters:&c length:1]];
    }
    return [self errorUnexpectedEOF:[NSString stringWithFormat:@"%c", TOKEN_DELIMITER_STRING]];
}

- (nullable BALPrimitiveValue *)parseSpecial:(NSString *)token {
    token = [token lowercaseString];

    if ([token isEqualToString:@"true"]) {
        return [BALPrimitiveValue valueWithBoolean:true];
    } else if ([token isEqualToString:@"false"]) {
        return [BALPrimitiveValue valueWithBoolean:false];
    } else if ([token isEqualToString:@"nil"]) {
        return [BALPrimitiveValue nilValue];
    }

    return nil;
}

- (nullable BALPrimitiveValue *)parseNumber:(NSString *)numberString {
    NSNumber *parsedNumber = [numberFormatter numberFromString:numberString];
    if (parsedNumber == nil) {
        return nil;
    }
    return [BALPrimitiveValue valueWithDouble:[parsedNumber doubleValue]];
}

- (nullable BALOperatorValue *)parseOperator:(NSString *)symbol {
    BALOperator *op = [operators operatorForSymbol:symbol.lowercaseString];
    if (op == nil) {
        return nil;
    }
    return [BALOperatorValue operatorValueWithOperator:op];
}

- (BALValue *)parseVariable {
    NSMutableString *accumulator = [NSMutableString new];

    while (!endReached) {
        unichar c = [self getNextChar];

        if (c == TOKEN_DELIMITER_VARIABLE) {
            if ([accumulator stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length ==
                0) {
                return [self errorWithMessage:@"Variables cannot have an empty name"];
            }
            return [BALVariableValue variableWithName:accumulator];
        }

        [accumulator appendString:[NSString stringWithCharacters:&c length:1]];
    }
    return [self errorUnexpectedEOF:[NSString stringWithFormat:@"%c", TOKEN_DELIMITER_VARIABLE]];
}

- (BALErrorValue *)errorWithMessage:(NSString *)message {
    return [BALErrorValue errorWithKind:BALErrorValueKindTypeParser message:message];
}

- (BALErrorValue *)errorUnexpectedEOF:(NSString *)expected {
    return [BALErrorValue errorWithKind:BALErrorValueKindTypeParser
                                message:[NSString stringWithFormat:@"Unexpected EOF. Expected: %@", expected]];
}

- (BALErrorValue *)errorWithPositionAndMessage:(NSString *)message {
    return
        [BALErrorValue errorWithKind:BALErrorValueKindTypeParser
                             message:[NSString stringWithFormat:@"At position %lu: %@", (unsigned long)_pos, message]];
}

@end
