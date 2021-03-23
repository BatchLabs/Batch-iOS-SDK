//
//  BatchEventDataPrivate.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BatchEventData.h>

#define BA_EVENT_DATA_TAGS_KEY @"tags"
#define BA_EVENT_DATA_ATTRIBUTES_KEY @"attributes"
#define BA_EVENT_DATA_CONVERTED_KEY @"converted"

// Expose private constructors
// This header is private and should NEVER be distributed within the framework

@class BATTypedEventAttribute;

NS_ASSUME_NONNULL_BEGIN

@interface BatchEventData ()
{
    @public
    NSMutableDictionary<NSString*, BATTypedEventAttribute*>* _attributes;
    NSMutableSet<NSString*>* _tags;
    BOOL _convertedFromLegacy;
}

- (void)_copyLegacyData:(NSDictionary*)data;

- (NSDictionary<NSString*, NSObject*>*)_internalDictionaryRepresentation;

@end

typedef NS_ENUM(NSUInteger, BAEventAttributeType) {
    BAEventAttributeTypeString,
    BAEventAttributeTypeInteger,
    BAEventAttributeTypeDouble,
    BAEventAttributeTypeBool,
    BAEventAttributeTypeDate,
};


@interface BATTypedEventAttribute : NSObject

+ (nonnull instancetype)attributeWithValue:(NSObject*)value type:(BAEventAttributeType)type;

- (NSString*)typeSuffix;

@property (nonatomic, nonnull) NSObject *value;

@property (assign, nonatomic) BAEventAttributeType type;

@end

NS_ASSUME_NONNULL_END
