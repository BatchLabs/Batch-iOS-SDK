//
//  BATJsonDictionary.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 NSDictionary wrapper with helper methods for JSON parsing
 */
@interface BATJsonDictionary : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dict errorDomain:(NSErrorDomain)errorDomain;

/**
 Get an object for the given key, check if it an instance of the wanted class and return it as is if it does.
 If an error occurs, the return value will be 'nil'.
 If you allow a key to be nil/nonexistent, you'll have to check the error pointer to see if the value really was null or
 of the wrong kind.

 NSNull values will be returned as nil.
 */
- (nullable id)objectForKey:(NSString *)key kindOfClass:(Class)class allowNil:(BOOL)allowNil error:(NSError **)error;

/**
 Get an object for the given key, check if it an instance of the wanted class and return it as is if it does.
 If an error occurs, or if the value is nil/nonexistent/[NSNull null], the return value will be the fallback.

 */
- (nullable id)objectForKey:(NSString *)key kindOfClass:(Class)class fallback:(nullable id)fallback;

/**
 String prefix to prepend to the error localized descriptions.
 */
@property (nullable) NSString *errorDescriptionPrefix;

@end

NS_ASSUME_NONNULL_END
