//
//  BALUserAttributeContext.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BALUserAttributeContext.h>

@implementation BALUserAttributeContext
{
    id<BAUserDatasourceProtocol> _datasource;
    NSDictionary<NSString*, BAUserAttribute*>* _attributes;
    NSDictionary<NSString*, NSSet<NSString*>*>* _tagCollections;
}

+ (instancetype)contextWithDatasource:(id<BAUserDatasourceProtocol>)datasource
{
    return [[BALUserAttributeContext alloc] initWithDatasource:datasource];
}

- (instancetype)initWithDatasource:(id<BAUserDatasourceProtocol>)datasource;
{
    self = [super init];
    if (self) {
        _datasource = datasource;
        
        // Attributes and tags are lazily fetched
        // The code could be optimized further by tweaking the datasources to be able
        // to only fetch a specific attribute
    }
    return self;
}

- (nullable BALValue *)resolveVariableNamed:(nonnull NSString *)name
{
    if ([name length] > 2) {
        if ([name hasPrefix:@"c."]) {
            
            [self fetchAttributes];
            
            for (NSString *key in _attributes.allKeys) {
                BAUserAttribute *attr = _attributes[key];
                // Attributes are stored with "c."
                if ([name caseInsensitiveCompare:key] == NSOrderedSame) {
                    return [self attributeToValue:attr];
                }
            }
            return [BALPrimitiveValue nilValue];
            
        } else if ([name hasPrefix:@"t."]) {
            
            NSString *wantedCollection = [name substringFromIndex:2];
            if (wantedCollection != nil && [wantedCollection length] > 0) {
                [self fetchTags];
                NSSet<NSString*>* collection = _tagCollections[wantedCollection];
                if (collection != nil) {
                    return [BALPrimitiveValue valueWithStringSet:collection];
                }
            }
            return [BALPrimitiveValue nilValue];
        }
    }
    return nil;
}

- (void)fetchAttributes
{
    if (_attributes == nil) {
        _attributes = [_datasource attributes];
    }
}

- (void)fetchTags
{
    if (_tagCollections == nil) {
        _tagCollections = [_datasource tagCollections];
    }
}

- (BALValue*)attributeToValue:(BAUserAttribute*)attribute
{
    if (attribute == nil) {
        return [BALPrimitiveValue nilValue];
    }
    
    switch (attribute.type) {
        case BAUserAttributeTypeDate:
        {
            NSDate *date = attribute.value;
            if ([date isKindOfClass:[NSDate class]]) {
                // Multiply by 1000 to get milliseconds, in order to conform to its Java counterpart.
                return [BALPrimitiveValue valueWithDouble:floor(date.timeIntervalSince1970 * (double)1000)];
            }
        }
        case BAUserAttributeTypeBool:
        {
            NSNumber *nbr = attribute.value;
            if ([nbr isKindOfClass:[NSNumber class]]) {
                return [BALPrimitiveValue valueWithBoolean:[nbr boolValue]];
            }
        }
        case BAUserAttributeTypeDouble:
        case BAUserAttributeTypeLongLong:
        {
            NSNumber *nbr = attribute.value;
            if ([nbr isKindOfClass:[NSNumber class]]) {
                return [BALPrimitiveValue valueWithDouble:[nbr doubleValue]];
            }
        }
        case BAUserAttributeTypeString:
        {
            NSString *str = attribute.value;
            if ([str isKindOfClass:[NSString class]]) {
                return [BALPrimitiveValue valueWithString:str];
            }
        }
        case BAUserAttributeTypeURL:
        {
            NSURL *url = attribute.value;
            if ([url isKindOfClass:[NSURL class]]) {
                return [BALPrimitiveValue valueWithURL:url];
            }
        }
        case BAUserAttributeTypeDeleted:
        default:
            return [BALPrimitiveValue nilValue];
    }
    
    return [BALPrimitiveValue nilValue];
}

@end
