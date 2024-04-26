//
//  BatchEventAttributesPrivate.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BatchEventAttributes.h>

#define BA_EVENT_DATA_TAGS_KEY @"tags"
#define BA_EVENT_DATA_ATTRIBUTES_KEY @"attributes"
#define BA_EVENT_DATA_CONVERTED_KEY @"converted"

// Expose private constructors
// This header is private and should NEVER be distributed within the framework

@class BATTypedEventAttribute;

NS_ASSUME_NONNULL_BEGIN

@interface BatchEventAttributes () {
   @public
    NSMutableDictionary<NSString *, BATTypedEventAttribute *> *_attributes;
    NSString *_label;
    NSArray<NSString *> *_tags;
}

@property (readonly, nonnull) NSDictionary<NSString *, BATTypedEventAttribute *> *_attributes;

@property (readonly, nullable) NSString *_label;

@property (readonly, nullable) NSArray<NSString *> *_tags;

@end

typedef NS_CLOSED_ENUM(NSUInteger, BAEventAttributeType) {
    BAEventAttributeTypeString,
    BAEventAttributeTypeInteger,
    BAEventAttributeTypeDouble,
    BAEventAttributeTypeBool,
    BAEventAttributeTypeDate,
    BAEventAttributeTypeURL,
    BAEventAttributeTypeStringArray,
    BAEventAttributeTypeObjectArray,
    BAEventAttributeTypeObject,
};

@interface BATTypedEventAttribute : NSObject

+ (nonnull instancetype)attributeWithValue:(NSObject *)value type:(BAEventAttributeType)type;

@property (readonly, nonnull) NSString *typeSuffix;

@property (nonatomic, nonnull) NSObject *value;

@property (assign, nonatomic) BAEventAttributeType type;

@end

NS_ASSUME_NONNULL_END
