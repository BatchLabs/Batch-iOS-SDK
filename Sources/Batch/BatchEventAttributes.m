#import <Batch/BAInjection.h>
#import <Batch/Batch-Swift.h>
#import <Batch/BatchEventAttributes.h>
#import <Batch/BatchEventAttributesPrivate.h>
#import <Batch/BatchProfile.h>

#import <Batch/BALogger.h>

#define PUBLIC_DOMAIN @"BatchProfile - Event Data"
#define DEBUG_DOMAIN @"BatchEventAttributes"

@implementation BatchEventAttributes {
    // Other ivars are in BatchEventDataPrivate
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _attributes = [NSMutableDictionary new];
    }
    return self;
}

- (instancetype)initWithBuilder:(void (^)(BatchEventAttributes *_Nonnull))builder {
    self = [self init];
    if (builder) {
        builder(self);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    BatchEventAttributes *copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        // We do not need a deep copy of the array as everything we store in it is either
        // immutable or has already been copied
        copy->_attributes = [_attributes mutableCopy];
        copy->_label = [_label copy];
        copy->_tags = [_tags copy];
    }

    return copy;
}

- (BOOL)validateWithError:(NSError **)error {
    NSArray<NSString *> *errors =
        [[BAInjection injectProtocol:@protocol(BAProfileCenterProtocol)] validateEventAttributes:self];

    if ([errors count] > 0) {
        NSString *errorDescription = [NSString
            stringWithFormat:@"Failed to validate event attributes:\n\n%@", [errors componentsJoinedByString:@"\n"]];

        if (error) {
            *error = [NSError errorWithDomain:PROFILE_ERROR_DOMAIN
                                         code:BatchProfileErrorInvalidEventAttributes
                                     userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
        }

        return false;
    } else {
        if (error) {
            *error = nil;
        }
        return true;
    }
}

- (void)putStringArray:(nonnull NSArray<NSString *> *)value forKey:(NSString *)key {
    if (![value isKindOfClass:NSArray.class]) {
        return;
    }

    if (![self _areArrayElements:value ofType:NSString.class]) {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Could not add string array: invalid array element types (must be NSString)"];
        return;
    }

    if ([@"$tags" isEqualToString:key]) {
        _tags = [value copy];
        return;
    }

    // This makes a deep copy as NSString conforms to NSCopying
    NSArray<BatchEventAttributes *> *valueCopy = [[NSArray alloc] initWithArray:value copyItems:true];
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:valueCopy type:BAEventAttributeTypeStringArray]
                      forKey:key];
}

- (void)putObjectArray:(nonnull NSArray<BatchEventAttributes *> *)value forKey:(NSString *)key {
    if (![value isKindOfClass:NSArray.class]) {
        return;
    }

    if (![self _areArrayElements:value ofType:BatchEventAttributes.class]) {
        [BALogger
            publicForDomain:PUBLIC_DOMAIN
                    message:@"Could not add object array: invalid array element types (must be BatchEventAttributes)"];
        return;
    }

    // This makes a deep copy as BatchEventAttributes conforms to NSCopying
    NSArray<BatchEventAttributes *> *valueCopy = [[NSArray alloc] initWithArray:value copyItems:true];
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:valueCopy type:BAEventAttributeTypeObjectArray]
                      forKey:key];
}

- (void)putObject:(nonnull BatchEventAttributes *)value forKey:(NSString *)key {
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:[value copy] type:BAEventAttributeTypeObject]
                      forKey:key];
}

- (void)putBool:(BOOL)value forKey:(NSString *)key {
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:[NSNumber numberWithBool:value]
                                                                   type:BAEventAttributeTypeBool]
                      forKey:key];
}

- (void)putInteger:(NSInteger)value forKey:(NSString *)key {
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:[NSNumber numberWithInteger:value]
                                                                   type:BAEventAttributeTypeInteger]
                      forKey:key];
}

- (void)putFloat:(float)value forKey:(NSString *)key {
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:[NSNumber numberWithFloat:value]
                                                                   type:BAEventAttributeTypeDouble]
                      forKey:key];
}

- (void)putDouble:(double)value forKey:(NSString *)key {
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:[NSNumber numberWithDouble:value]
                                                                   type:BAEventAttributeTypeDouble]
                      forKey:key];
}

- (void)putString:(NSString *)value forKey:(NSString *)key {
    if (![value isKindOfClass:NSString.class]) {
        return;
    }

    if ([@"$label" isEqualToString:key]) {
        _label = [value copy];
        return;
    }

    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:[value copy] type:BAEventAttributeTypeString]
                      forKey:key];
}

- (void)putDate:(NSDate *)value forKey:(NSString *)key {
    if (![value isKindOfClass:[NSDate class]]) {
        [BALogger publicForDomain:PUBLIC_DOMAIN message:@"Cannot add a null or non NSDate date attribute. Ignoring."];
        return;
    }

    NSNumber *timestamp = @(floor([value timeIntervalSince1970] * 1000));
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:timestamp type:BAEventAttributeTypeDate]
                      forKey:key];
}

- (void)putURL:(NSURL *)value forKey:(NSString *)key {
    if (![value isKindOfClass:[NSURL class]]) {
        [BALogger publicForDomain:PUBLIC_DOMAIN message:@"Cannot add a null or non NSURL url attribute. Ignoring."];
        return;
    }

    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:value type:BAEventAttributeTypeURL] forKey:key];
}

- (void)_putTypedAttribute:(BATTypedEventAttribute *)attribute forKey:(NSString *)key {
    _attributes[key.lowercaseString] = attribute;
}

- (BOOL)_areArrayElements:(nonnull NSArray *)array ofType:(Class)clazz {
    for (id element in array) {
        if (![element isKindOfClass:clazz]) {
            return false;
        }
    }
    return true;
}

- (nonnull NSDictionary<NSString *, BATTypedEventAttribute *> *)_attributes {
    return _attributes;
}

- (nullable NSString *)_label {
    return _label;
}

- (nullable NSArray<NSString *> *)_tags {
    return _tags;
}

@end

@implementation BATTypedEventAttribute : NSObject

+ (nonnull instancetype)attributeWithValue:(NSObject *)value type:(BAEventAttributeType)type {
    BATTypedEventAttribute *attr = [BATTypedEventAttribute new];
    attr.value = value;
    attr.type = type;
    return attr;
}

- (NSString *)typeSuffix {
    switch (self.type) {
        case BAEventAttributeTypeBool:
            return @"b";
        case BAEventAttributeTypeInteger:
            return @"i";
        case BAEventAttributeTypeDouble:
            return @"f";
        case BAEventAttributeTypeString:
            return @"s";
        case BAEventAttributeTypeDate:
            return @"t";
        case BAEventAttributeTypeURL:
            return @"u";
        case BAEventAttributeTypeStringArray:
        case BAEventAttributeTypeObjectArray:
            return @"a";
        case BAEventAttributeTypeObject:
            return @"o";
        default:
            return @"x";
    }
}

@end
