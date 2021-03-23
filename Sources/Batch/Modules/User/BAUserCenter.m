//
//  BAUserCenter.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BAUserCenter.h>
#import <Batch/BAUserDataManager.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BAOptOut.h>
#import <Batch/BALogger.h>
#import <Batch/BAParameter.h>

/*
 @abstract Class responsible 
 */
@implementation BAUserCenter

+ (void)batchWillStart
{
    [BAUserDataManager startAttributesCheckWSWithDelay:[kParametersUserStartCheckInitialDelay longLongValue]];
    [[BANotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(optOutValueDidChange:)
                                                 name:kBATOptOutChangedNotification
                                               object:nil];

    NSNumber *lastFailure = [BAParameter objectForKey:kParametersCipherV2LastFailure kindOfClass:[NSNumber class] fallback:nil];
    if (lastFailure != nil) {
        double now = [[NSDate date] timeIntervalSince1970] - kCipherFallbackResetTime; // 2 days
        if ([lastFailure doubleValue] < now) {
            [BAParameter removeObjectForKey:kParametersCipherV2LastFailure];
        }
    }
}

+ (void)optOutValueDidChange:(NSNotification *)notification
{
    if ([@(true) isEqualToNumber:[notification.userInfo objectForKey:kBATOptOutWipeDataKey]])
    {
        [BALogger debugForDomain:@"BAUserCenter" message:@"Wiping user data"];
        [BAUserDataManager clearData];
    }
}

@end
