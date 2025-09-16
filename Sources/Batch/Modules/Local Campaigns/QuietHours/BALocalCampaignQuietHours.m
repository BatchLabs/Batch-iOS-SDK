//
//  BALocalCampaignQuietHours.m
//  Batch
//
//  Copyright © 2025 Batch.com. All rights reserved.
//

#import "BALocalCampaignQuietHours.h"
#import <Batch/BALocalCampaignDayOfWeek.h>
#import <Batch/BATJsonDictionary.h>

#define LOGGER_DOMAIN @"BALocalCampaignQuietHours"

@implementation BALocalCampaignQuietHours

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSError *err = nil;
        BATJsonDictionary *json = [[BATJsonDictionary alloc] initWithDictionary:dictionary errorDomain:LOGGER_DOMAIN];

        // Extract and validate startHour
        NSNumber *startHour = [json objectForKey:@"startHour" kindOfClass:[NSNumber class] allowNil:NO error:&err];
        if (err != nil) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"startHour is not a NSNumber"];
            return nil;
        } else {
            _startHour = [startHour integerValue];
        }

        // Extract and validate startMin
        NSNumber *startMin = [json objectForKey:@"startMin" kindOfClass:[NSNumber class] allowNil:NO error:&err];
        if (err != nil) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"startMin is not a NSNumber"];
            return nil;
        } else {
            _startMin = [startMin integerValue];
        }

        // Extract and validate endHour
        NSNumber *endHour = [json objectForKey:@"endHour" kindOfClass:[NSNumber class] allowNil:NO error:&err];
        if (err != nil) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"endHour is not a NSNumber"];
            return nil;
        } else {
            _endHour = [endHour integerValue];
        }

        // Extract and validate endMin
        NSNumber *endMin = [json objectForKey:@"endMin" kindOfClass:[NSNumber class] allowNil:NO error:&err];
        if (err != nil) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"endMin is not a NSNumber"];
            return nil;
        } else {
            _endMin = [endMin integerValue];
        }

        // Extract and validate quietDaysOfWeek
        NSArray *quietDays = [json objectForKey:@"quietDaysOfWeek" kindOfClass:[NSArray class] allowNil:YES error:&err];
        if (err != nil) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"quietDays is not a NSArray"];
            return nil;
        } else {
            // Ensure all elements in the array are valid BALocalCampaignDayOfWeek values
            for (id day in quietDays) {
                if (![day isKindOfClass:[NSNumber class]]) {
                    [BALogger debugForDomain:LOGGER_DOMAIN message:@"day is not a NSNumber"];

                    return nil;
                }
                NSInteger dayValue = [day integerValue];
                if (dayValue < BALocalCampaignDayOfWeekSunday || dayValue > BALocalCampaignDayOfWeekSaturday) {
                    [BALogger debugForDomain:LOGGER_DOMAIN message:@"day value is unknown"];
                    // Invalid day of week value

                    return nil;
                }
            }
            _quietDaysOfWeek = quietDays;
        }
    }

    return self;
}

@end
