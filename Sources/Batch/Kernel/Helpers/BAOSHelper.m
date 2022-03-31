//
//  BAOSHelper.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BAOSHelper.h>

#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <sys/types.h>

@implementation BAOSHelper

// Get the device code string.
+ (NSString *)deviceCode {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return platform;
}

+ (BOOL)parseIntegerSystemVersion:(NSInteger)intSystemVersion out:(NSOperatingSystemVersion *)outVersion {
    // Format is XXXYYYZZZ (extra 0s should NOT be ommited)
    if (outVersion == NULL) {
        return false;
    }

    if (intSystemVersion < 1000000) { // iOS 1.0.0
        return false;
    }

    int interval = 1000;

    // Divide the intSystemVersion by "interval" and take the reminder, essentially
    // shifting the digits.
    // That way, reading the number backwards gives use the elements sequentially
    // Do that for major as well to make sure it only has 3 digits.
    NSInteger tempValue = intSystemVersion;
    outVersion->patchVersion = tempValue % interval;
    tempValue = tempValue / interval;
    outVersion->minorVersion = tempValue % interval;
    tempValue = tempValue / interval;
    outVersion->majorVersion = tempValue % interval;

    return true;
}

@end
