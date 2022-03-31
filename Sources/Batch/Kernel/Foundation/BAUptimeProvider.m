//
//  BAUptimeProvider.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BAUptimeProvider.h>

#include <errno.h>
#include <sys/sysctl.h>
#include <time.h>

@implementation BAUptimeProvider

// Gets the real uptime, including the time spent in deep sleep
// [[NSProcessInfo processInfo] systemUptime] drifts, even
// if the documentation doesn't say so.
+ (NSTimeInterval)uptime {
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    time_t now;
    time_t uptime = -1;

    time(&now);

    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0) {
        uptime = now - boottime.tv_sec;
    }

    if (uptime == -1) {
        return [[NSProcessInfo processInfo] systemUptime];
    }

    return uptime;
}

@end
