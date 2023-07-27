//
//  BAEncryptionProtocol.h
//  Core
//
//  https://batch.com
//  Copyright (c) 2012 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @protocol BAEncryptionProtocol
 @abstract Convertor from encrypation
 @discussion Protocol for encryption process.
 */
@protocol BAEncryptionProtocol <NSObject>

@required

/*!
 @method initWithKey:
 @abstract Instanciate the cipher with the cryption key.
 @param key         :   A cryption key string.
 @return this object, NULL otherwise.
 */
- (nullable instancetype)initWithKey:(nonnull NSString *)key;

/*!
 @method setCombinedKey:
 @abstract Use a dynamic generated key, combine the current key depending on the given format.
 Override the current key.
 @param key :   String format for key combine. ex: @"aF3xe%@1"
 */
- (void)setCombinedKey:(nonnull NSString *)key;

/*!
 @method encrypt:
 @abstract Encode a string data.
 @param tocrypt : The string to encode.
 @return encoded string, NULL otherwise.
 */
- (nullable NSString *)encrypt:(nullable NSString *)tocrypt;

/*!
 @method decrypt:
 @abstract Decode a string data.
 @param crypted : The encoded string.
 @return clear string data, NULL otherwise.
 */
- (nullable NSString *)decrypt:(nullable NSString *)crypted;

/*!
 @method encryptData:
 @abstract Encode a data.
 @param tocrypt : The data to encode.
 @return encoded data, NULL otherwise.
 */
- (nullable NSData *)encryptData:(nullable NSData *)tocrypt;

/*!
 @method decryptData:
 @abstract Decode a data.
 @param crypted : The encoded data.
 @return clear data, NULL otherwise.
 */
- (nullable NSData *)decryptData:(nullable NSData *)crypted;

@end
