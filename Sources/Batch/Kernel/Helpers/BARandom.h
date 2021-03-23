//
//  BARandom.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BARandom : NSObject

/*!
 @method generateRandomStringLength:
 @abstract Generate a random [0-9][a-z][A-Z] string.
 @param length  :   Lenght of the string to generate.
 @return The generated string.
 */
+ (NSString *)randomAlphanumericStringWithLength:(int)length;

/*!
 @method generateUUID
 @abstract Generate a random identifier using CFUUIDCreateString() method.
 @return The generated string supposed to be unique.
 */
+ (NSString *)generateUUID;

@end
