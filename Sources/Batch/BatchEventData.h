//
//  BatchEventData.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Object holding data to be associated to an event
///
/// - Note: Keys should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30 characters.
@interface BatchEventData : NSObject <NSCopying>

/// Add a tag.
///
/// - Parameters:
///   - tag: Tag to add. Can't be longer than 64 characters, and can't be empty or null. For better results, you should
///   trim/lowercase your strings, and use slugs when possible.
- (void)addTag:(NSString *)tag NS_SWIFT_NAME(add(tag:));

/// Add a boolean attribute for the specified key.
///
/// - Parameters:
///   - value: Boolean value to add.
///   - key:  Attribute key. Should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30
///   characters.
- (void)putBool:(BOOL)value forKey:(NSString *)key;

/// Add an integer (NSInteger) attribute for the specified key.
///
/// - Parameters:
///   - value: Integer value to add.
///   - key: Attribute key. Should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30
///   characters.
- (void)putInteger:(NSInteger)value forKey:(NSString *)key;

/// Add a float attribute for the specified key.
///
/// - Parameters:
///   - value: Float value to add.
///   - key: Attribute key. Should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30
///   characters.
- (void)putFloat:(float)value forKey:(NSString *)key;

/// Add a double attribute for the specified key.
///
/// - Parameters:
///   -  value: Double value to add.
///   -  key: Attribute key. Should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30
///   characters.
- (void)putDouble:(double)value forKey:(NSString *)key;

/// Add a string attribute for the specified key.
///
/// - Parameters:
///   -  value: String value to add. Can't be longer than 64 characters, and can't be empty or nil. For better results,
///   you should trim/lowercase your strings, and use slugs when possible.
///   -  key: Attribute key. Should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30
///   characters.
- (void)putString:(NSString *)value forKey:(NSString *)key;

/// Add a date attribute for the specified key.
///
/// - Parameters:
///   -  value: Date value to add. Can't be nil.
///   -  key: Attribute key. Should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30
///   characters.
- (void)putDate:(NSDate *)value forKey:(NSString *)key;

/// Add an URL attribute for the specified key.
/// - Parameters:
///   - value: URL value to add. Can't be longer than 2048 characters, and can't be empty or nil. Must follow the format
///   `scheme://[authority][path][?query][#fragment]`.
///   - key: Attribute key. Should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30
///   characters.
- (void)putURL:(NSURL *)value forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
