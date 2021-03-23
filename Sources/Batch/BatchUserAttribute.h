//
//  BatchUserAttribute.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BatchUserAttributeType) {
    BatchUserAttributeTypeString,
    BatchUserAttributeTypeLongLong,
    BatchUserAttributeTypeDouble,
    BatchUserAttributeTypeBool,
    BatchUserAttributeTypeDate
};

@interface BatchUserAttribute: NSObject

/**
 The value of the attribute. You can use the typed methods below to get a typed result.
 */
@property (nonatomic, nonnull) id value;

/**
 The type of the value for the attribute.
 */
@property (assign, nonatomic) BatchUserAttributeType type;

/**
 Get the date value for date type attributes.
 
 @return A date value or nil if the attribute is not a date.
 */
- (nullable NSDate *)dateValue;

/**
 Get the string value for string type attributes.
 
 @return A string value or nil if the attribute is not a string.
 */
- (nullable NSString *)stringValue;

/**
 Get the number value for double, long long and bool type attributes.
 
 @return A string value or nil if the attribute is not a number.
 */
- (nullable NSNumber *)numberValue;

@end
