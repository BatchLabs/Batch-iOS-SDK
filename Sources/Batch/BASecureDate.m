//
//  BASecureDate.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//
#import <Batch/BASecureDate.h>

#import <Batch/BAParameter.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BAUptimeProvider.h>

@interface BASecureDate ()

@property NSTimeInterval bootInterval;

@property NSTimeInterval serverInterval;

@end

@implementation BASecureDate

#pragma mark -
#pragma mark Public methods

// Instance management.
+ (BASecureDate *)instance
{
    static BASecureDate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BASecureDate alloc] init];
    });
    
    return sharedInstance;
}

// Update the secure date system with the server date.
- (void)updateServerDate:(NSNumber *)timestamp
{
    @synchronized(self)
    {
        if (timestamp != nil)
        {
            // Server gives us miliseconds.
            [self setServerInterval:(NSTimeInterval)([timestamp doubleValue]/1000)];
            [self setBootInterval:[BAUptimeProvider uptime]];
        }
    }
}

// The computed secure date.
- (NSDate *)date
{
    if (![self serverInterval] || ![self bootInterval])
    {
        return nil;
    }

    NSDate *date = nil;
    @synchronized(self)
    {
        NSDate *serverDate = [NSDate dateWithTimeIntervalSince1970:[self serverInterval]];
        NSTimeInterval delta = [BAUptimeProvider uptime] - [self bootInterval];
        
        date = [NSDate dateWithTimeInterval:delta sinceDate:serverDate];
    }
    
    return date;
}

- (NSString *)formattedString
{
    
    NSDate *currentDate = [self date];
    if ([BANullHelper isNull:currentDate])
    {
        return nil;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if ([kParametersDateFormat rangeOfString:@"'Z'"].location != NSNotFound)
    {
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    }
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [formatter setDateFormat:kParametersDateFormat];
    
    NSString *dateString = [formatter stringFromDate:currentDate];
    
    return dateString;
}

@end
