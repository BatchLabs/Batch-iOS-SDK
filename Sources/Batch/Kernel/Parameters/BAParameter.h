//
//  BAParameter.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BAParameter
 @abstract Singleton for parameters management
 @discussion The singleton provide an handy way to get and set parameters for the library. This class is thread safe
 */
@interface BAParameter : NSObject

/*!
 @method objectForKey:fallback:
 @abstract Return the value for the givent key, fallback otherwise.
 @param key     :   The key to get the value from.
 @param value   :   The fallback returned if anything goes wrong.
 @return the value if any, fallback otherwise
 */
+ (nullable id)objectForKey:(nonnull NSString *)key fallback:(nullable id)value;

/*!
 @method objectForKey:fallback:
 @abstract Return the value for the givent key, fallback otherwise.
 @param key        :   The key to get the value from.
 @param class      : The kind of class the result should be
 @param fallback   :   The fallback returned if anything goes wrong.
 @return the value if any and of the right class, fallback otherwise
 */
+ (nullable id)objectForKey:(nonnull NSString *)key kindOfClass:(nonnull Class)class fallback:(nullable id)fallback;

/*!
 @method setValue:forKey:saved:
 @abstract Set a value for a key and write it into the domain preferences if needed.
 @param value   :   The value to store.
 @param key     :   The key to use for storage.
 @param save    :   Boolean to set if the value must be keept.
 @return An error if something goes wrong, nothing otherwise.
 */
+ (nullable NSError *)setValue:(nonnull id)value forKey:(nonnull NSString *)key saved:(BOOL)save;

/*!
 @method removeObjectForKey:
 @abstract Remove the value and the key.
 @param key     :   The key to use for storage.
 @return An error if something goes wrong, nothing otherwise.
 */
+ (nullable NSError *)removeObjectForKey:(nonnull NSString *)key;

/**
 Remove all parameters
 */
+ (void)removeAllObjects;

@end
