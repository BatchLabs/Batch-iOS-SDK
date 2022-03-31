//
//  BADateFormatting.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BADateFormatting.h>
#import "Defined.h"

@implementation BADateFormatting

+ (NSDateFormatter *)dateFormatter;
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      dateFormatter = [[NSDateFormatter alloc] init];
      dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
      dateFormatter.dateFormat = kParametersDateFormat;
      dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });

    return dateFormatter;
}

@end
