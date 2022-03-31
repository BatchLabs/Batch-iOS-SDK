//
//  BAHTTPHeaders.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BAHTTPHeaders.h>

#import <Batch/BACoreCenter.h>

#import <Batch/BAOSHelper.h>

@implementation BAHTTPHeaders

// Generate a custom user agent from application an mobile infos.
+ (NSString *)userAgent {
    static NSString *ua;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      ua = [self makeUserAgent];
    });

    return ua;
}

+ (NSString *)makeUserAgent {
    NSString *agent = @"";

    // Look for a plugin version.
    NSString *pluginInfos = @"";
    const char *pluginVersion = getenv("BATCH_PLUGIN_VERSION");
    if (pluginVersion != nil) {
        pluginInfos = [NSString stringWithFormat:@"%@ ", [NSString stringWithCString:pluginVersion
                                                                            encoding:NSUTF8StringEncoding]];
    }

    // Look for a bridge version.
    NSString *bridgeInfos = @"";
    const char *bridgeVersion = getenv("BATCH_BRIDGE_VERSION");
    if (bridgeVersion != nil) {
        bridgeInfos = [NSString stringWithFormat:@"%@ ", [NSString stringWithCString:bridgeVersion
                                                                            encoding:NSUTF8StringEncoding]];
    }

    NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Product reference"];
    if ([BANullHelper isStringEmpty:bundleID] == YES) {
        bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    }
    NSString *appversion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *device = [[BAOSHelper deviceCode] stringByReplacingOccurrencesOfString:@"," withString:@"."];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];

    agent = [NSString stringWithFormat:@"%@%@%@/%@ %@/%@ (%@;iOS %@)", pluginInfos, bridgeInfos, BABundleIdentifier,
                                       BACoreCenter.sdkVersion, bundleID, appversion, device, osVersion];

    return agent;
}

// Generate a custom accect language from device locale.
+ (NSString *)acceptLanguage {
    NSString *localeIdentifier = [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier];
    NSArray *fragments = [localeIdentifier componentsSeparatedByString:@"_"];

    NSString *locale;
    if ([fragments count] > 1) {
        locale = [NSString stringWithFormat:@"%@-%@", [fragments objectAtIndex:0], [fragments objectAtIndex:1]];
    } else {
        locale = localeIdentifier;
    }

    return locale;
}

@end
