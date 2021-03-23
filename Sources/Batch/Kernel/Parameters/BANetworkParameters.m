//
//  BANetworkParameters.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2012 Batch SDK. All rights reserved.
//

#import <Batch/BANetworkParameters.h>

#if TARGET_OS_MACCATALYST

@implementation BANetworkParameters

// MCC+MNC
+ (NSString *)simOperatorCode
{
    return @"";
}

@end

#else

#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

@implementation BANetworkParameters

// MCC+MNC
+ (NSString *)simOperatorCode
{
    static CTTelephonyNetworkInfo *telephonyNetworkInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
    });
    //TODO add cache
    CTCarrier *carrier;
    
    if (@available(iOS 12.1, *)) {
        // This APi is available from iOS 12.0, but returns nil
        NSDictionary<NSString*, CTCarrier*>* carriers = [telephonyNetworkInfo serviceSubscriberCellularProviders];
        for (CTCarrier* candidateCarrier in carriers.allValues) {
            // Try to find a SIM that's active.
            // Note that for dual sim both can be active. We don't know which one is the default, so we just pick one.
            if ([candidateCarrier.mobileCountryCode length] > 0 || [candidateCarrier.mobileNetworkCode length] > 0) {
                carrier = candidateCarrier;
                break;
            }
        }
    } else {
        carrier = [telephonyNetworkInfo subscriberCellularProvider];
    }
    
    NSString *mobileCountryCode = [carrier mobileCountryCode];
    NSString *mobileNetworkCode = [carrier mobileNetworkCode];
    
    if (mobileCountryCode == nil) {
        mobileCountryCode = @"";
    }
    
    if (mobileNetworkCode == nil) {
        mobileNetworkCode = @"";
    }
    
    NSString *operatorCode = [mobileCountryCode stringByAppendingString:mobileNetworkCode];
    if ([operatorCode length] > 0) {
        return operatorCode;
    } else {
        return nil;
    }
}

@end

#endif
