//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSInteger {
    BATMessagePackWriterErrorLibraryFailure = 100,
    BATMessagePackWriterErrorPrecondition = 101,
} BATMessagePackWriterError;

@interface BATMessagePackWriter : NSObject

/// Returns whether an array is packable or not.
/// The array's objects can be of the following types:
///     NSNull
///     NSNumber (for bools, integers and decimals)
///     NSString
///     NSData
///     NSArray
///     NSDictionary
+ (BOOL)canPackArray:(nullable NSArray*)array;

/// Returns whether a dictionary is packable or not.
/// The keys should conform to NSCopying, but only the following types are supported:
///     NSNull
///     NSNumber (for bools, integers and decimals)
///     NSString
/// The dictionary's objects can be of the following types:
///     NSNull
///     NSNumber (for bools, integers and decimals)
///     NSString
///     NSData
///     NSArray
///     NSDictionary
+ (BOOL)canPackDictionary:(nullable NSDictionary<id<NSCopying>, id>*)dictionary;

/// Write nil.
- (void)writeNil;

/// Write a boolean.
/// @param boolean value to pack
- (void)writeBool:(BOOL)boolean;

/// Write a 64 bit signed integer.
/// @param int64 value to pack
- (void)writeInt64:(int64_t)int64;

/// Write a 64 bit unsigned integer.
/// @param uint64 value to pack
- (void)writeUnsignedInt64:(uint64_t)uint64;

/// Write an integer.
/// Be careful, this changes between 32 and 64 bit.
/// @param integer value to pack
- (void)writeInt:(NSInteger)integer;

/// Write an unsigned integer.
/// Be careful, this changes between 32 and 64 bit.
/// @param integer value to pack
- (void)writeUnsignedInt:(NSUInteger)integer;

/// Write a float.
/// @param value value to pack
- (void)writeFloat:(float)value;

/// Write a double.
/// @param value value to pack
- (void)writeDouble:(double)value;

/// Write a number or nil.
/// @param number number to pack
- (BOOL)writeNumber:(nullable NSNumber*)number error:(NSError * _Nullable * _Nullable)error;

/// Write an array length header.
/// This method takes an NSUInteger for convinence, as it is
/// [NSArray count]'s type, but MessagePack arrays cannot store
/// more than UINT32_MAX elements.
/// @param size size of the array. Must not be greater than UINT32_MAX
- (BOOL)writeArraySize:(NSUInteger)size error:(NSError * _Nullable * _Nullable)error;

/// Write an NSArray or nil.
/// Note that not all kind of values can be packed. Call +(BOOL)canPackArray:(NSArray*)array
/// if you want to know beforehand.
/// @param array array to write
- (BOOL)writeArray:(nullable NSArray*)array error:(NSError * _Nullable * _Nullable)error;

/// Write a dictionary (map) size header.
/// A map's size is the number of key/value pairs.
/// This method takes an NSUInteger for convinence, but MessagePack arrays cannot store
/// more than UINT32_MAX tuples.
/// @param size length of the map. Must not be greater than UINT32_MAX
- (BOOL)writeDictionarySize:(NSUInteger)size error:(NSError * _Nullable * _Nullable)error;

/// Write an NSDictionary or nil.
/// Note that not all kind of values can be packed. Call +(BOOL)canPackDictionary:(NSDictionary*)dictionary
/// if you want to know beforehand.
/// The keys should conform to NSCopying, but only the following types are supported:
///     NSNull
///     NSNumber (for bools, integers and decimals)
///     NSString
/// @param dictionary dictionary to write
- (BOOL)writeDictionary:(nullable NSDictionary<id<NSCopying>, id>*)dictionary error:(NSError * _Nullable * _Nullable)error;

/// Write a NSData or nil.
- (BOOL)writeData:(nullable NSData*)data error:(NSError * _Nullable * _Nullable)error;

/// Write a String or nil.
- (BOOL)writeString:(nullable NSString*)string error:(NSError * _Nullable * _Nullable)error;

/// The MessagePack data. Makes a copy on read, so you may want to cache this instead of repeatedly accessing it.
@property (nonnull, readonly) NSData* data;

@end

NS_ASSUME_NONNULL_END
