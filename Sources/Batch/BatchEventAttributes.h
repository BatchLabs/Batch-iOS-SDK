//
//  BatchEventAttributes.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Object holding attributes to be associated to an event
///
/// - Note: Keys should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30 characters.
@interface BatchEventAttributes : NSObject <NSCopying>

/// Initialize an event data object.
- (instancetype)init;

/// Initialize an event using block/closure. Convinence initializer for Swift usage.
- (instancetype)initWithBuilder:(void (^__nonnull)(BatchEventAttributes *))builder;

/// Validate the event data.
/// - Parameter error: NSError to write to. If the validation succeeds, your variable will be set to nil. Otherwise, get
/// the error description for more info. Detailed error information is not available via error domain or code.
/// - Returns True if the event data validates successfully, false if not. If the data does not validate, Batch will
/// refuse to track an event with it.
- (BOOL)validateWithError:(NSError **)error;

/// Add an array of string attribute for the specified key.
///
/// - Parameters:
///   - value: Array of string values to add. Strings must not be longer than 200 characters. Cannot have more than 25
///   items.
///   - key:  Attribute key. Should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30
///   characters.
- (void)putStringArray:(nonnull NSArray<NSString *> *)value forKey:(NSString *)key NS_SWIFT_NAME(put(_:forKey:));

/// Add an array of objects attribute for the specified key.
///
/// - Parameters:
///   - value: Array of object values to add. Must be represented by BatchEventAttributes instances that are copied when
///   put. Warning: sub objects have more limitations than root BatchEventAttributes. Cannot have more than 25 items.
///   - key:  Attribute key. Should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30
///   characters.
- (void)putObjectArray:(nonnull NSArray<BatchEventAttributes *> *)value
                forKey:(NSString *)key NS_SWIFT_NAME(put(_:forKey:));

/// Add an object attribute for the specified key.
///
/// - Parameters:
///   - value: Object value to add. Must be represented by a BatchEventAttributes instance. Warning: sub objects have
///   more limitations than root BatchEventAttributes.
///   - key:  Attribute key. Should be made of letters, numbers or underscores ([a-z0-9_]) and can't be longer than 30
///   characters.
- (void)putObject:(nonnull BatchEventAttributes *)value forKey:(NSString *)key NS_SWIFT_NAME(put(_:forKey:));

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
