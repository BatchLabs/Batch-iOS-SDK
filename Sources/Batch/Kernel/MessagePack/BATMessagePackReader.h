//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    BATMessagePackReaderErrorLibraryFailure = 100,
    BATMessagePackReaderErrorUnknownError = 101,
    BATMessagePackReaderErrorMalformedData = 110,
    BATMessagePackReaderErrorUnsupportedType = 111,
    BATMessagePackReaderErrorTypeMismatch = 112,
} BATMessagePackReaderError;

@interface BATMessagePackReader : NSObject

/// Initialize a MessagePack reader with raw data.
/// @param data MessagePack data
- (nonnull instancetype)initWithData:(nonnull NSData *)data;

/// Read nil.
/// @param error If an errors occurs, will contain the error.
/// @returns wherther nil has been successfully read or not.
- (BOOL)readNilWithError:(NSError *_Nullable *_Nullable)error;

/// Read a Bool.
/// @param error If an errors occurs, will contain the error.
/// @param allowNil whether a nil value is allowed
/// @returns the value. If you set allowNil to true, you will need to
///          read the error pointer to distinguish a genuine error from an expected nil value.
- (nullable NSNumber *)readBoolAllowingNil:(BOOL)allowNil error:(NSError *_Nullable *_Nullable)error;

/// Read an Integer.
/// This method will read any signed or unsigned integer.
/// @param error If an errors occurs, will contain the error.
/// @param allowNil whether a nil value is allowed
/// @returns the value. If you set allowNil to true, you will need to
///          read the error pointer to distinguish a genuine error from an expected nil value.
- (nullable NSNumber *)readIntegerAllowingNil:(BOOL)allowNil error:(NSError *_Nullable *_Nullable)error;

/// Read a decimal.
/// This method will read floats and doubles.
/// @param error If an errors occurs, will contain the error.
/// @param allowNil whether a nil value is allowed
/// @returns the value. If you set allowNil to true, you will need to
///          read the error pointer to distinguish a genuine error from an expected nil value.
- (nullable NSNumber *)readDecimalAllowingNil:(BOOL)allowNil error:(NSError *_Nullable *_Nullable)error;

/// Read a String.
/// @param error If an errors occurs, will contain the error.
/// @param allowNil whether a nil value is allowed
/// @returns the value or nil if an error occurred. If you set allowNil to true, you will need to
///          read the error pointer to distinguish a genuine error from an expected nil value.
- (nullable NSString *)readStringAllowingNil:(BOOL)allowNil error:(NSError *_Nullable *_Nullable)error;

/// Read raw Data.
/// @param error If an errors occurs, will contain the error.
/// @param allowNil whether a nil value is allowed
/// @returns the value or nil if an error occurred. If you set allowNil to true, you will need to
///          read the error pointer to distinguish a genuine error from an expected nil value.
- (nullable NSData *)readDataAllowingNil:(BOOL)allowNil error:(NSError *_Nullable *_Nullable)error;

/// Read a dictionary.
/// The dictionary's keys can be of the following types:
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
/// @param error If an errors occurs, will contain the error.
/// @param allowNil whether a nil value is allowed
/// @returns the value or nil if an error occurred. If you set allowNil to true, you will need to
///          read the error pointer to distinguish a genuine error from an expected nil value.
- (nullable NSDictionary *)readDictionaryAllowingNil:(BOOL)allowNil error:(NSError *_Nullable *_Nullable)error;
;

/// Read a dictionary header.
/// @param error If an errors occurs, will contain the error.
/// @returns the value or nil if an error occurred.
- (nullable NSNumber *)readDictionaryHeaderWithError:(NSError *_Nullable *_Nullable)error;

/// Read an array.
/// The array's objects can be of the following types:
///     NSNull
///     NSNumber (for bools, integers and decimals)
///     NSString
///     NSData
///     NSArray
///     NSDictionary
/// @param error If an errors occurs, will contain the error.
/// @param allowNil whether a nil value is allowed
/// @returns the value or nil if an error occurred. If you set allowNil to true, you will need to
///          read the error pointer to distinguish a genuine error from an expected nil value.
- (nullable NSArray *)readArrayAllowingNil:(BOOL)allowNil error:(NSError *_Nullable *_Nullable)error;

/// Read an array header.
/// @param error If an errors occurs, will contain the error.
/// @returns the value or nil if an error occurred.
- (nullable NSNumber *)readArrayHeaderWithError:(NSError *_Nullable *_Nullable)error;

/// Read any value.
/// The result can be of the following types:
///     NSNull
///     NSNumber (for bools, integers and decimals)
///     NSString
///     NSData
///     NSArray
///     NSDictionary
/// @param error If an errors occurs, will contain the error.
/// @returns the value or nil if an error occurred. Nil MessagePack values are represented as NSNull.
- (nullable id)readAnyWithError:(NSError *_Nullable *_Nullable)error;

@end
