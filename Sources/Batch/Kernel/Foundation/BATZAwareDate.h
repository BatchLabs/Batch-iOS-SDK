//
//  BATZAwareDate.h
//  Batch
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 BATZAwareDate is a helper date class used to understand timezone aware dates.
 
 Dates can be communicated using timestamps, making them much cheaper to parse than string based date formats,
 but allows the offsetting of the underlying UTC timestamp to match a local time.
 
 If you give this date a NSDate representing "2017-02-03 08:00 UTC", and set "relativeToUserTZ" to YES,
 it will offset the UTC date so that it becomes "2017-02-03 08:00" in the local timezone.
 
 For example, if the current timezone is "UTC+2", "2017-02-03 08:00 UTC" would be offsetted to become
 "2017-02-03 06:00".
 */
@interface BATZAwareDate : NSObject

/**
 Returns the current date, not relative to the user TZ.
 Useful to compare the current date with a relative one.
 */
+ (instancetype)date;

+ (instancetype)dateWithDate:(NSDate*)date relativeToUserTZ:(BOOL)useLocalTZ;

/**
 Returns a timestamp according to the "relativeToUserTZ" parameter and the current timezone,
 offsetted if needed so that the timestamp points to the wanted local time.
 */
- (NSTimeInterval)offsettedTimeIntervalSince1970;

- (BOOL)isAfter:(BATZAwareDate*)date;

- (BOOL)isBefore:(BATZAwareDate*)date;

- (BOOL)isEqualToDate:(BATZAwareDate*)date;

@end

NS_ASSUME_NONNULL_END
