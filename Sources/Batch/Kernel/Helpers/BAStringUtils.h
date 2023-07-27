//
//  BAStringUtils.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAStringUtils : NSObject

/*!
 @method hexStringValueForData:
 @abstract Generate the hexadeciaml value of the data.
 @return Hexadecimal string.
 */
+ (nonnull NSString *)hexStringValueForData:(nonnull NSData *)data;

@end
