//
//  Atoms.m
//  BatchObjLisp
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Batch/BALValues.h>
#import <Batch/BALEvaluationContext.h>
#import <Batch/BALOperators.h>

@implementation BALValue
@end

@implementation BALErrorValue

- (instancetype)initWithKind:(BALErrorValueKind)kind message:(NSString*)message;
{
    self = [super init];
    if (self) {
        _kind = kind;
        _message = message;
    }
    return self;
}

+ (instancetype)errorWithKind:(BALErrorValueKind)kind message:(NSString*)message;
{
    return [[BALErrorValue alloc] initWithKind:kind message:message];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[BALErrorValue class]]) {
        return NO;
    } else {
        BALErrorValue *castedOther = other;
        return self.kind == castedOther.kind && [self.message isEqualToString:castedOther.message];
    }
}

- (NSString*)description
{
    NSString *kind;
    switch (self.kind) {
        case BALErrorValueKindTypeInternal:
            kind = @"Internal error";
            break;
        case BALErrorValueKindTypeError:
            kind = @"Program error";
            break;
        case BALErrorValueKindTypeParser:
            kind = @"Parser error";
            break;
        default:
            kind = @"Unknown error kind.";
            break;
    }
    
    return [NSString stringWithFormat:@"<ErrorValue> Kind: %@, Message: \"%@\"", kind, self.message];
}

@end

@implementation BALPrimitiveValue

- (instancetype)initWithValue:(id)value type:(BALPrimitiveValueType)type
{
    self = [super init];
    if (self) {
        _type = type;
        _value = value;
    }
    return self;
}

+ (instancetype)nilValue
{
    return [[BALPrimitiveValue alloc] initWithValue:nil type:BALPrimitiveValueTypeNil];
}

+ (nullable instancetype)valueWithString:(NSString*)value
{
    if ([value isKindOfClass:[NSString class]]) {
        return [[BALPrimitiveValue alloc] initWithValue:value type:BALPrimitiveValueTypeString];
    } else {
        return nil;
    }
}

+ (instancetype)valueWithDouble:(double)value
{
    return [[BALPrimitiveValue alloc] initWithValue:[NSNumber numberWithDouble:value] type:BALPrimitiveValueTypeDouble];
}

+ (instancetype)valueWithBoolean:(BOOL)value
{
    return [[BALPrimitiveValue alloc] initWithValue:[NSNumber numberWithBool:value] type:BALPrimitiveValueTypeBool];
}

+ (nullable instancetype)valueWithStringSet:(NSSet<NSString*>*)value
{
    if ([value isKindOfClass:[NSSet<NSString*> class]]) {
        return [[BALPrimitiveValue alloc] initWithValue:[value copy] type:BALPrimitiveValueTypeStringSet];
    } else {
        return nil;
    }
}

+ (nullable instancetype)valueWithURL:(NSURL*)value
{
    if ([value isKindOfClass:[NSURL class]]) {
        return [[BALPrimitiveValue alloc] initWithValue:value type:BALPrimitiveValueTypeURL];
    } else {
        return nil;
    }
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[BALPrimitiveValue class]]) {
        return NO;
    } else {
        BALPrimitiveValue *castedOther = other;
        // Pointer comparaison takes care of nil values
        return self.type == castedOther.type && (self.value == castedOther.value || [self.value isEqual:castedOther.value]);
    }
}

- (NSString*)description
{
    if (self.type == BALPrimitiveValueTypeNil)
    {
        return @"Nil";
    }
    
    NSString *valueDescription = [self.value description];
    
    if (self.type == BALPrimitiveValueTypeString)
    {
        valueDescription = [NSString stringWithFormat:@"\"%@\"", [self escapeString:valueDescription]];
    }
    else if (self.type == BALPrimitiveValueTypeStringSet)
    {
        valueDescription = [self setDescription:self.value];
    }
    
    return valueDescription;
}

- (NSString*)debugDescription
{
    NSString *valueDescription = [self.value description];
    NSString *typeDescription;
    switch (self.type) {
        case BALPrimitiveValueTypeNil:
            typeDescription = @"Nil";
            break;
        case BALPrimitiveValueTypeBool:
            typeDescription = @"Bool";
            break;
        case BALPrimitiveValueTypeDouble:
            typeDescription = @"Double";
            break;
        case BALPrimitiveValueTypeString:
            typeDescription = @"String";
            valueDescription = [NSString stringWithFormat:@"\"%@\"", [self escapeString:valueDescription]];
            break;
        case BALPrimitiveValueTypeStringSet:
            typeDescription = @"String Set";
            valueDescription = [self setDescription:self.value];
            break;
        default:
            typeDescription = @"Unknown primitive type.";
            break;
    }
    
    return [NSString stringWithFormat:@"<PrimitiveValue> Type: %@, Value: \"%@\"", typeDescription, valueDescription];
}

- (NSString*)escapeString:(NSString*)value
{
    value = [value stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    value = [value stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    value = [value stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    value = [value stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
    value = [value stringByReplacingOccurrencesOfString:@"\'" withString:@"\\'"];
    value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];

    return value;
}

- (NSString*)setDescription:(NSSet<NSString*>*)set
{
    if (![set isKindOfClass:[NSSet class]]) {
        return @"[error]";
    }
    
    NSMutableString *desc = [NSMutableString new];
    
    [desc appendString:@"["];
    
    NSArray<NSString*>* array = [set allObjects];
    for (int i = 0; i < array.count; i++)
    {
        if (i > 0) {
            [desc appendString:@" "];
        }
        [desc appendString:[NSString stringWithFormat:@"\"%@\"", [self escapeString:array[i]]]];
    }
    
    [desc appendString:@"]"];
    
    return desc;
}

@end

@implementation BALOperatorValue

- (instancetype)initWithOperator:(BALOperator*)operator
{
    self = [super init];
    if (self) {
        _operator = operator;
    }
    return self;
}

+ (instancetype)operatorValueWithOperator:(BALOperator*)operator
{
    return [[BALOperatorValue alloc] initWithOperator:operator];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[BALOperatorValue class]]) {
        return NO;
    } else {
        return [self.operator.symbol isEqualToString:((BALOperatorValue*)other).operator.symbol];
    }
}

- (NSString*)description
{
    return self.operator.symbol;
}

- (NSString*)debugDescription
{
    return [NSString stringWithFormat:@"<Operator> Symbol: %@", self.operator.symbol];
}

@end

@implementation BALVariableValue

- (instancetype)initWithName:(NSString*)name
{
    self = [super init];
    if (self) {
        _name = name;
    }
    return self;
}

+ (instancetype)variableWithName:(NSString*)name
{
    return [[BALVariableValue alloc] initWithName:name];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[BALVariableValue class]]) {
        return NO;
    } else {
        return [self.name isEqualToString:((BALVariableValue*)other).name];
    }
}

- (nonnull BALValue *)reduce:(nonnull id<BALEvaluationContext>)context
{
    BALValue *resolved = [context resolveVariableNamed:self.name.lowercaseString];
    if (resolved == nil) {
        resolved = [BALPrimitiveValue nilValue];
    }
    return resolved;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"`%@`", self.name];
}

- (NSString*)debugDescription
{
    return [NSString stringWithFormat:@"<Variable>: %@", self.name];
}

@end
