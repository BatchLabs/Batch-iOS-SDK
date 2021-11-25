//
//  BALEventContext.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BALEventContext.h>

#import <Batch/BATrackerCenter.h>
#import <Batch/BatchEventDataPrivate.h>

@implementation BALEventContext
{
    NSString* _eventName;
    NSString* _eventLabel;
    BatchEventData* _data;
    BOOL _publicEvent;
}

+ (instancetype)contextWithPrivateEvent:(NSString*)name
{
    return [[BALEventContext alloc] initWithEvent:name label:nil data:nil];
}

+ (instancetype)contextWithPublicEvent:(NSString*)name label:(nullable NSString*)label data:(nullable BatchEventData*)data
{
    return [[BALEventContext alloc] initWithEvent:name label:label data:data];
}

- (instancetype)initWithEvent:(NSString*)name label:(nullable NSString*)label data:(nullable BatchEventData*)data
{
    self = [super init];
    if (self) {
        _eventName = [name copy];
        _eventLabel = [label copy];
        _data = [data copy];
        _publicEvent = [_eventName hasPrefix:@"E."];
    }
    return self;
}

- (nullable BALValue*)resolveVariableNamed:(nonnull NSString*)variableName
{
    if (![variableName hasPrefix:@"e."]) {
        return nil;
    }
    
    if ([variableName isEqualToString:@"e.name"]) {
        return [BALPrimitiveValue valueWithString:_eventName];
    } else if ([variableName isEqualToString:@"e.label"]) {
        return [self label];
    } else if ([variableName isEqualToString:@"e.tags"]) {
        return [self tags];
    } else if ([variableName isEqualToString:@"e.converted"]) {
        return [self converted];
    } else if ([variableName hasPrefix:@"e.attr['"]) {
        return [self dataForRawVariableName:variableName];
    }
    
    return nil;
}

- (nonnull BALValue*)label
{
    if (_publicEvent && _eventLabel != nil) {
        
        return [BALPrimitiveValue valueWithString:_eventLabel];
    }
    
    return [BALPrimitiveValue nilValue];
}

- (nonnull BALValue*)tags
{
    if (_publicEvent && _data != nil) {
        NSSet *tags = _data->_tags;
        
        if ([tags isKindOfClass:[NSSet class]]) {
            return [BALPrimitiveValue valueWithStringSet:tags];
        }
    }
    
    return [BALPrimitiveValue nilValue];
}

- (nonnull BALValue*)converted
{
    if (_publicEvent && _data != nil) {
        return [BALPrimitiveValue valueWithBoolean:_data->_convertedFromLegacy];
    }
    
    return [BALPrimitiveValue valueWithBoolean:false];
}

- (nonnull BALValue*)dataForRawVariableName:(NSString*)variableName
{
    if (_publicEvent && _data != nil) {
        
        NSDictionary *attributes = _data->_attributes;
        
        if (![attributes isKindOfClass:[NSDictionary class]] ||
            [attributes count] == 0) {
            return [BALPrimitiveValue nilValue];
        }
        
        NSString *wantedAttributeName = [self extractAttributeFromVariableName:variableName];
        
        if (wantedAttributeName == nil) {
            return [BALPrimitiveValue nilValue];
        }
        
        BATTypedEventAttribute *typedAttribute = attributes[wantedAttributeName];
        if (typedAttribute != nil) {
            NSObject *value = typedAttribute.value;
            switch (typedAttribute.type) {
                case BAEventAttributeTypeBool:
                    if ([value isKindOfClass:[NSNumber class]]) {
                        return [BALPrimitiveValue valueWithBoolean:[(NSNumber*)value boolValue]];
                    }
                    break;
                case BAEventAttributeTypeDouble:
                    if ([value isKindOfClass:[NSNumber class]]) {
                        return [BALPrimitiveValue valueWithDouble:[(NSNumber*)value doubleValue]];
                    }
                    break;
                case BAEventAttributeTypeInteger:
                    if ([value isKindOfClass:[NSNumber class]]) {
                        return [BALPrimitiveValue valueWithDouble:[(NSNumber*)value integerValue]];
                    }
                    break;
                case BAEventAttributeTypeString:
                    if ([value isKindOfClass:[NSString class]]) {
                        return [BALPrimitiveValue valueWithString:(NSString*)value];
                    }
                    break;
                case BAEventAttributeTypeDate:
                    if ([value isKindOfClass:[NSDate class]]) {
                        // Multiply by 1000 to get milliseconds, in order to conform to its Java counterpart.
                        return [BALPrimitiveValue valueWithDouble:floor(((NSDate*)value).timeIntervalSince1970 * (double)1000)];
                    }
                case BAEventAttributeTypeURL:
                    if ([value isKindOfClass:[NSURL class]]) {
                        return [BALPrimitiveValue valueWithURL:(NSURL*)value];
                    }
                    break;
            }
        }
    }
    
    return [BALPrimitiveValue nilValue];
}

- (nullable NSString*)extractAttributeFromVariableName:(NSString*)variableName
{
    // Assume that we already checked that the string is prefixed by e.attr["
    if ([variableName hasSuffix:@"']"] && variableName.length > 10) {
        NSString *extractedName = [variableName substringWithRange:NSMakeRange(8, variableName.length-10)];
        if ([extractedName length] > 0) {
            return extractedName;
        }
    }
    
    return nil;
}

@end
