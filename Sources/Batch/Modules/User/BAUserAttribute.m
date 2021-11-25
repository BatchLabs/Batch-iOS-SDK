//
//  BAUserAttribute.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BAUserAttribute.h>

@implementation BAUserAttribute

+ (instancetype)attributeWithValue:(nonnull id)value type:(BAUserAttributeType)type
{
    BAUserAttribute *attribute = [[BAUserAttribute alloc] init];
    attribute.value = value;
    attribute.type = type;
    
    return attribute;
}

+ (nonnull NSDictionary<NSString*, id>*)serverJsonRepresentationForAttributes:(nullable NSDictionary<NSString*, BAUserAttribute*>*)attributes;
{
    NSMutableDictionary *result = [NSMutableDictionary new];
    
    for (NSString *name in attributes.allKeys)
    {
        BAUserAttribute *attribute = attributes[name];
        // Convert the dates!
        id value = attribute.value;
        
        if ([value isKindOfClass:[NSDate class]])
        {
            value = @(floor([value timeIntervalSince1970] * 1000));
        }
        
        // Convert the urls!
        if ([value isKindOfClass:[NSURL class]])
        {
            value = ((NSURL *) value).absoluteString;
        }

        [result setObject:value forKey:[NSString stringWithFormat:@"%@.%@", [name substringFromIndex:2], [BAUserAttribute stringForType:attribute.type]]];
    }
    
    return result;
}

+ (NSString*)stringForType:(BAUserAttributeType)type
{
    switch (type)
    {
        case BAUserAttributeTypeBool:
            return @"b";
        case BAUserAttributeTypeLongLong:
            return @"i";
        case BAUserAttributeTypeDouble:
            return @"f";
        case BAUserAttributeTypeString:
            return @"s";
        case BAUserAttributeTypeDate:
            return @"t";
        case BAUserAttributeTypeURL:
            return @"u";
        default:
            return @"x";
    }
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[BAUserAttribute class]]) {
        return NO;
    } else {
        BAUserAttribute *castedOther = other;
        // Pointer comparaison takes care of nil values
        return self.type == castedOther.type && (self.value == castedOther.value || [self.value isEqual:castedOther.value]);
    }
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"type: %@ value: %@", [BAUserAttribute stringForType:self.type], self.value];
}

@end
