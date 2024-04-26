//
//  BAUserDefaults.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAEncryptionProtocol.h>

/*!
 @class BAUserDefaults
 @abstract Preferences storage for BA.
 @discussion Embed a custom user defaults for Batch usage.
 */
@interface BAUserDefaults : NSObject

/*!
 @method initWithCryptor:
 @abstract Build the storage.
 @param cryptor : Standard cryptor (optional).
 @return Instance or nil.
 */
- (instancetype _Nonnull)initWithCryptor:(id<BAEncryptionProtocol> _Nullable)cryptor;

/*!
 @method initWithCryptor:andSuiteName
 @abstract Build the storage.
 @param cryptor : Standard cryptor (optional).
 @param suiteName : The name of the suite to use for the UserDefaults.
 @return Instance or nil.
 */
- (instancetype _Nonnull)initWithCryptor:(id<BAEncryptionProtocol> _Nullable)cryptor
                            andSuiteName:(NSString *_Nullable)suiteName;

/*!
 @method objectForKey:
 @abstract Retrieve the value for the given key.
 @param key :   The stored key for that value.
 @return The value or nil.
 */
- (id _Nullable)objectForKey:(NSString *_Nonnull)key;

/*!
 @method setValue:forKey:
 @abstract Change the value for a given key.
 @param value   :   The value to save.
 @param key     :   Key for that value.
 */
- (void)setValue:(id _Nullable)value forKey:(NSString *_Nonnull)key;

/*!
 @method removeObjectForKey:
 @abstract Remove the value and the key.
 @param key     :   The key to use for storage.
 */
- (void)removeObjectForKey:(NSString *_Nonnull)key;

/**
 Remove all k/v
 */
- (void)removeAllObjects;

@end
