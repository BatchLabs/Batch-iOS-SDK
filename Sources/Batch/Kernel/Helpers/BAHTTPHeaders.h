//
//  BAHTTPHeaders.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAHTTPHeaders : NSObject

/*!
 @method userAgent
 @abstract Generate a custom user agent from application an mobile infos.
 @return Formated string description of the user agent.
 */
+ (NSString *)userAgent;

/*!
 @method acceptLanguage
 @abstract Generate a custom accect language from device locale.
 @return Formated string.
 */
+ (NSString *)acceptLanguage;

@end
