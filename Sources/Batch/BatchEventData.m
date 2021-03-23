#import <Batch/BatchEventData.h>
#import <Batch/BatchEventDataPrivate.h>

#import <Batch/BALogger.h>

#define MAXIMUM_VALUES 15
#define MAXIMUM_TAGS 10
#define MAXIMUM_STRING_LENGTH 64
#define ATTRIBUTE_KEY_RULE @"^[a-zA-Z0-9_]{1,30}$"

#define PUBLIC_DOMAIN @"BatchUser - Event Data"
#define DEBUG_DOMAIN @"BatchEventData"

@implementation BatchEventData
{
    // Other ivars are in BatchEventDataPrivate
    NSRegularExpression* _attributeKeyValidationRegexp;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _convertedFromLegacy = false;
        _attributes = [NSMutableDictionary new];
        _tags = [NSMutableSet new];
        
        static NSRegularExpression *regex;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSError *error = nil;
            regex = [NSRegularExpression regularExpressionWithPattern:ATTRIBUTE_KEY_RULE
                                                              options:0
                                                                error:&error];
            if (error)
            {
                // Something went really wrong, so we'll just throw internal errors
                [BALogger errorForDomain:DEBUG_DOMAIN message:@"Error while creating event attribute key regexp."];
                regex = nil;
            }
        });
        
        _attributeKeyValidationRegexp = regex;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    BatchEventData *copy = [BatchEventData new];
    copy->_convertedFromLegacy = _convertedFromLegacy;
    copy->_attributes = [_attributes mutableCopy];
    copy->_tags = [_tags mutableCopy];
    
    return copy;
}

- (void)addTag:(NSString*)tag
{
    if ([self _enforceTagsCount:tag] && [self _enforceStringValue:tag])
    {
        [_tags addObject:[tag lowercaseString]];
    }
}

- (void)putBool:(BOOL)value forKey:(NSString*)key
{
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:[NSNumber numberWithBool:value] type:BAEventAttributeTypeBool] forKey:key];
}

- (void)putInteger:(NSInteger)value forKey:(NSString*)key
{
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:[NSNumber numberWithInteger:value] type:BAEventAttributeTypeInteger] forKey:key];
}

- (void)putFloat:(float)value forKey:(NSString*)key
{
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:[NSNumber numberWithFloat:value] type:BAEventAttributeTypeDouble] forKey:key];
}

- (void)putDouble:(double)value forKey:(NSString*)key
{
    [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:[NSNumber numberWithDouble:value] type:BAEventAttributeTypeDouble] forKey:key];
}

- (void)putString:(NSString*)value forKey:(NSString*)key
{
    if ([self _enforceStringValue:value])
    {
        [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:value type:BAEventAttributeTypeString] forKey:key];
    }
}

- (void)putDate:(NSDate*)value forKey:(NSString*)key
{
    if ([self _enforceDateValue:value])
    {
        NSNumber *timestamp = @(floor([value timeIntervalSince1970] * 1000));
        [self _putTypedAttribute:[BATTypedEventAttribute attributeWithValue:timestamp type:BAEventAttributeTypeDate] forKey:key];
    }
}

- (void)_putTypedAttribute:(BATTypedEventAttribute*)attribute forKey:(NSString*)key
{
    key = key.lowercaseString;
    // If the key already exists, skip the checks
    if ([_attributes objectForKey:key] != nil || ([self _enforceAttributesCount:key] && [self _enforceKey:key]))
    {
        _attributes[key] = attribute;
    }
}

- (BOOL)_enforceStringValue:(NSString*)value
{
    if (value.length == 0)
    {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Cannot add a null or empty string attribute/tag. Ignoring."];
        return false;
    }
    
    if (value.length > MAXIMUM_STRING_LENGTH)
    {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"String attributes and tags can't be longer than %d characters. Ignoring.", MAXIMUM_STRING_LENGTH];
        return false;
    }
    
    return true;
}

- (BOOL)_enforceDateValue:(NSDate*)value
{
    if (![value isKindOfClass:[NSDate class]])
    {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Cannot add a null or non NSDate date attribute. Ignoring."];
        return false;
    }
    
    return true;
}

- (BOOL)_enforceKey:(NSString*)key
{
    if (_attributeKeyValidationRegexp == nil)
    {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Could not put attribute. Internal error."];
        return false;
    }
    
    if ([key isKindOfClass:[NSString class]])
    {
        NSRange matchingRange = [_attributeKeyValidationRegexp rangeOfFirstMatchInString:key
                                                                                 options:0
                                                                                   range:NSMakeRange(0, key.length)];
        if (matchingRange.location != NSNotFound)
        {
            return true;
        }
        else
        {
            [BALogger publicForDomain:PUBLIC_DOMAIN message:@"Invalid key. Please make sure that the key is made of letters, underscores and numbers only (a-zA-Z0-9_). It also can't be longer than 30 characters. Ignoring attribute '%@'.", key];
            return false;
        }
    }

    return false;
}

- (BOOL)_enforceAttributesCount:(NSString*)key
{
    if ([_attributes count] == MAXIMUM_VALUES)
    {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Event data cannot hold more than 15 attributes. Ignoring attribute: '%@'", key];
        return false;
    }
    return true;
}

- (BOOL)_enforceTagsCount:(NSString*)tag
{
    if ([_tags count] == MAXIMUM_TAGS)
    {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Event data cannot hold more than 10 tags. Ignoring tag: '%@'", tag];
        return false;
    }
    return true;
}

- (void)_copyLegacyData:(NSDictionary*)legacyData
{
    if (![legacyData isKindOfClass:[NSDictionary class]])
    {
        return;
    }
    
    if (![NSJSONSerialization isValidJSONObject:legacyData])
    {
        [BALogger debugForDomain:DEBUG_DOMAIN message:@"Legacy event data is not a valid JSON Object according to NSJSONSerialization. Ignoring."];
        return;
    }
    
    _convertedFromLegacy = true;
    
    NSArray<NSString*>* legacyDataKeys = legacyData.allKeys;
    legacyDataKeys = [legacyDataKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for (NSString *key in legacyDataKeys) {
        NSObject *legacyValue = legacyData[key];
        
        if ([_attributes count] >= MAXIMUM_VALUES)
        {
            [BALogger publicForDomain:PUBLIC_DOMAIN
                              message:@"Event data cannot hold more than 10 attributes. Stopping legacy conversion."];
            break;
        }
        
        // Try to guess the legacy value type
        if ([legacyValue isKindOfClass:[NSString class]])
        {
            [self putString:(NSString*)legacyValue forKey:key];
        }
        else if ([legacyValue isKindOfClass:[NSNumber class]])
        {
            NSNumber *numberAttr = (NSNumber*)legacyValue;
            const char *ctype = [numberAttr objCType];
            
            // Possible ctypes for NSNumber: “c”, “C”, “s”, “S”, “i”, “I”, “l”, “L”, “q”, “Q”, “f”, and “d”.
            // Supported ones: "c", "s", "i", "l", "q", "f", "d"
            
            // Non decimal values are read as long long, which is the biggest on both 32 and 64-bit architectures
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"Legacy data for key '%@' is a NSNumber: %s", key, ctype];
            if (strcmp(ctype, @encode(short)) == 0 ||
                strcmp(ctype, @encode(int)) == 0 ||
                strcmp(ctype, @encode(long)) == 0 ||
                strcmp(ctype, @encode(long long)) == 0 )
            {
                // Long long might be truncated on 32 bit platforms
                [self putInteger:[numberAttr integerValue] forKey:key];
            }
            else if(strcmp(ctype, @encode(char)) == 0)
            {
                // Usually chars are booleans, even shorts are stored as ints.
                char val = [numberAttr charValue];
                if (val == 0 || val == 1)
                {
                    [self putBool:[numberAttr boolValue] forKey:key];
                }
                else
                {
                    [self putInteger:[numberAttr integerValue] forKey:key];
                }
            }
            // Decimal values
            else if(strcmp(ctype, @encode(float)) == 0 ||
                    strcmp(ctype, @encode(double)) == 0)
            {
                [self putDouble:[numberAttr doubleValue] forKey:key];
            }
            // According to the documentation that's not supported, but give it a shot
            else if(strcmp(ctype, @encode(BOOL)) == 0)
            {
                [self putBool:[numberAttr boolValue] forKey:key];
            }
            else
            {
                // Try to make it work in a NSInteger
                NSInteger val = [numberAttr integerValue];
                if ([numberAttr isEqualToNumber:[NSNumber numberWithInteger:val]])
                {
                    [self putInteger:[numberAttr integerValue] forKey:key];
                }
            }
        }
        else
        {
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"Unsupported legacy attribute of class '%@' for key '%@'. Ignoring.", NSStringFromClass([legacyValue class]), key];
        }
    }
}

- (NSDictionary<NSString*, NSObject*>*)_internalDictionaryRepresentation
{
    NSMutableDictionary *outAttributes = [NSMutableDictionary dictionaryWithCapacity:_attributes.count];
    
    NSString *formattedKey;
    BATTypedEventAttribute *typedAttr;
    for (NSString *key in _attributes.keyEnumerator) {
        typedAttr = _attributes[key];
        formattedKey = [[[key lowercaseString] stringByAppendingString:@"."] stringByAppendingString:[typedAttr typeSuffix]];
        
        [outAttributes setObject:typedAttr.value forKey:formattedKey];
    }
    
    NSMutableDictionary *representation = [[NSMutableDictionary alloc] initWithCapacity:3];
    representation[BA_EVENT_DATA_TAGS_KEY] = [_tags allObjects];
    representation[BA_EVENT_DATA_ATTRIBUTES_KEY] = outAttributes;

    if (_convertedFromLegacy) {
        representation[BA_EVENT_DATA_CONVERTED_KEY] = @(true);
    }
    
    return representation;
}

@end

@implementation BATTypedEventAttribute : NSObject

+ (nonnull instancetype)attributeWithValue:(NSObject*)value type:(BAEventAttributeType)type
{
    BATTypedEventAttribute *attr = [BATTypedEventAttribute new];
    attr.value = value;
    attr.type = type;
    return attr;
}

- (NSString*)typeSuffix
{
    switch (self.type)
    {
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
        default:
            return @"u";
    }
}

@end
