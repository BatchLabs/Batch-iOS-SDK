//
//  BATJsonDictionary.h
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
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
 Writes the specified error in the error pointer, and return nil.
 While this may sound a little stupid, it allows for one line error bailing, rather than copy pasting the same tedious 3
 lines
 */
- (nullable id)writeErrorAndReturnNil:(NSError *)error toErrorPointer:(NSError **)outErr;

/**
 String prefix to prepend to the error localized descriptions.
 */
@property (nullable) NSString *errorDescriptionPrefix;

@end

NS_ASSUME_NONNULL_END
