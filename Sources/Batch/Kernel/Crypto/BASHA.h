//
//  BASHA.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BASHA : NSObject

/**
 Returns the raw SHA256 of a given NSData
 */
+ (nullable NSData *)sha256HashOf:(nullable NSData *)data;

/**
 Returns the raw SHA1 of a given NSData
 */
+ (nullable NSData *)sha1HashOf:(nullable NSData *)data;

@end

NS_ASSUME_NONNULL_END
