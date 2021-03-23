//
//  BASecureDate.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BASecureDate : NSObject

/*!
 @method instance
 @abstract Instance method.
 @return BASecureDate singleton.
 */
+ (BASecureDate *)instance __attribute__((warn_unused_result));

/*!
 @method updateServerDate:
 @abstract Update the secure date system with the server date.
 @param timestamp   :   Server timestamp in milliseconds.
 */
- (void)updateServerDate:(NSNumber *)timestamp;

/*!
 @method date
 @abstract The computed secure date.
 @return Secure NSDate or nil if no server hit succed.
 */
- (NSDate *)date __attribute__((warn_unused_result));

/*!
 @method formattedString
 @abstract Formated string date.
 @return Date string representation.
 */
- (NSString *)formattedString __attribute__((warn_unused_result));

@end
