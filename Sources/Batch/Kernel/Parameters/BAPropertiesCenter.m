//
//  PropertiesCenter.m
//  AppGratis
//
//  Copyright (c) 2012 Batch SDK. All rights reserved.
//

#import <Batch/BAPropertiesCenter.h>

#import <Batch/BANetworkParameters.h>
#import <Batch/BAParameter.h>

#import <Batch/BABundleInfo.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BADirectories.h>
#import <Batch/BAInstallationID.h>
#import <Batch/BANotificationAuthorization.h>
#import <Batch/BAOSHelper.h>
#import <Batch/BAThreading.h>
#import <Batch/BATrackingAuthorization.h>

#import <CommonCrypto/CommonCrypto.h>

#include <net/if.h>
#include <net/if_dl.h>
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>

@interface BAPropertiesCenter ()

@property NSDictionary<NSString *, NSString *> *parameterMappings;
@property NSDateFormatter *dateFormatter;

@end

@implementation BAPropertiesCenter

#pragma mark -
#pragma mark Public methods

// Try to respond to one of it's selector from a string description.
+ (NSString *)valueForShortName:(NSString *)selectorString {
    return [[BAPropertiesCenter sharedInstance] valueForShortName:selectorString];
}

#pragma mark -
#pragma mark Private methods

+ (instancetype)sharedInstance {
    static BAPropertiesCenter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [BAPropertiesCenter new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupParameterMappings];
        [self setupDefaultFormatter];
    }
    return self;
}

- (void)setupParameterMappings {
    _parameterMappings = @{
        @"di" : @"localInstallation",
        @"cus" : @"customIdentifier",
        @"tok" : @"pushToken",
#if BATCH_ENABLE_IDFA
        @"idfa" : @"attributionID",
#endif
        @"attid_e" : @"isAttributionIdEnabled",
        @"tath" : @"trackingAuthorizationStatus",
        @"dre" : @"deviceRegion",
        @"dla" : @"deviceLanguage",
        @"dtz" : @"deviceTimezone",
        @"are" : @"applicationRegion",
        @"ala" : @"applicationLanguage",
        @"da" : @"deviceDate",
        @"ada" : @"appInstallDate",
        @"did" : @"sdkInstallDate",
        @"dty" : @"deviceType",
        @"osv" : @"deviceOSVersion",
        @"de" : @"density",
        @"sw" : @"screenWidth",
        @"sh" : @"screenHeight",
        @"so" : @"screenOrientation",
        @"bid" : @"bundleID",
        @"pid" : @"applicationID",
        @"pl" : @"platform",
        @"lvl" : @"APILevel",
        @"mlvl" : @"messagingAPILevel",
        @"apv" : @"appVersion",
        @"apc" : @"versionCode",
        @"plv" : @"pluginVersion",
        @"brv" : @"bridgeVersion",
        @"nty" : @"notifType",
        @"sop" : @"simOperatorCode",
        @"s" : @"sessionIdentifier"
    };
}

- (void)setupDefaultFormatter {
    NSString *format = kParametersDateFormat;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if ([format rangeOfString:@"'Z'"].location != NSNotFound) {
        [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    }
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [formatter setDateFormat:format];
    _dateFormatter = formatter;
}

- (NSString *)valueForShortName:(NSString *)parameterName {
    if ([BANullHelper isStringEmpty:parameterName] == false) {
        // Map the short selector string to the internal class one
        NSString *targetSelector = [self.parameterMappings objectForKey:parameterName];
        if (targetSelector == nil) {
            return nil;
        }

        SEL selector = NSSelectorFromString(targetSelector);
        id target = self;
        if ([target respondsToSelector:selector]) {
            IMP imp = [target methodForSelector:selector];
            id (*func)(id, SEL) = (void *)imp;
            id value = func(target, selector);

            if ([value isKindOfClass:[NSString class]]) {
                return value;
            }
        }
    }

    return nil;
}

#pragma mark -
#pragma mark method implementation

- (NSString *)localInstallation {
    NSString *install = [BAInstallationID installationID];
    return install != nil ? install : @"";
}

- (NSString *)customIdentifier {
    NSString *identifier = [BAParameter objectForKey:kParametersCustomUserIDKey fallback:@""];

    if ([BANullHelper isStringEmpty:identifier] == NO) {
        return identifier;
    }

    return nil;
}

- (NSString *)pushToken {
    NSString *identifier = [BAParameter objectForKey:kParametersPushTokenKey fallback:@""];

    if ([BANullHelper isStringEmpty:identifier] == NO) {
        return identifier;
    }

    return nil;
}

#if BATCH_ENABLE_IDFA
- (NSString *)attributionID {
    return [BACoreCenter instance].status.trackingAuthorization.attributionIdentifier.UUIDString;
}
#endif

- (NSString *)isAttributionIdEnabled {
#if BATCH_ENABLE_IDFA
    return @"1";
#else
    return @"0";
#endif
}

- (NSString *)trackingAuthorizationStatus {
    BATrackingAuthorizationStatus status =
        [BACoreCenter instance].status.trackingAuthorization.trackingAuthorizationStatus;
    return [NSString stringWithFormat:@"%lu", (unsigned long)status];
}

// MCC+MNC
- (NSString *)simOperatorCode {
    return [BANetworkParameters simOperatorCode];
}

- (NSString *)deviceRegion {
    return [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}

- (NSString *)deviceLanguage {
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}

- (NSString *)applicationRegion {
    NSString *appLocale = [[[NSBundle mainBundle] preferredLocalizations] firstObject];
    return [[NSLocale componentsFromLocaleIdentifier:appLocale] objectForKey:NSLocaleCountryCode];
}

- (NSString *)applicationLanguage {
    NSString *appLocale = [[[NSBundle mainBundle] preferredLocalizations] firstObject];
    return [NSLocale canonicalLanguageIdentifierFromString:appLocale];
}

- (NSString *)deviceTimezone {
    return [[NSTimeZone systemTimeZone] description];
}

- (NSString *)deviceDate {
    NSDate *currentDate = [NSDate date];
    return [self.dateFormatter stringFromDate:currentDate];
}

- (NSString *)appInstallDate {
    NSDate *lastInstallDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:NSTemporaryDirectory() error:nil]
        objectForKey:NSFileCreationDate];
    if (lastInstallDate == nil) {
        return nil;
    }

    return [self.dateFormatter stringFromDate:lastInstallDate];
}

- (NSString *)sdkInstallDate {
    NSString *timestampString = [BAParameter objectForKey:kParametersLocalInstallDateIdentifierKey fallback:nil];
    if (timestampString == nil) {
        return nil;
    }

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[timestampString doubleValue]];
    if (date == nil) {
        return nil;
    }

    return [self.dateFormatter stringFromDate:date];
}

- (NSString *)deviceType {
#if TARGET_OS_MACCATALYST
    return [@"Mac - " stringByAppendingString:[BAOSHelper deviceCode]];
#elif TARGET_OS_SIMULATOR
    return [@"Simulator - " stringByAppendingString:[BAOSHelper deviceCode]];
#else
    return [BAOSHelper deviceCode];
#endif
}

- (NSString *)deviceOSVersion {
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *)density {
    return [NSString stringWithFormat:@"%.1f", [[UIScreen mainScreen] scale]];
}

- (NSString *)screenWidth {
    return [NSString stringWithFormat:@"%.1f", [[UIScreen mainScreen] bounds].size.width];
}

- (NSString *)screenHeight {
    return [NSString stringWithFormat:@"%.1f", [[UIScreen mainScreen] bounds].size.height];
}

- (NSString *)screenOrientation {
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
    return [NSString stringWithFormat:@"%@", isPortrait ? @"P" : @"L"];
}

- (NSString *)bundleID {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

- (NSString *)applicationID {
    return BAProductIdentifier;
}

- (NSString *)platform {
    return @"IOS";
}

- (NSString *)APILevel {
    return [NSString stringWithFormat:@"%u", BAAPILevel];
}

- (NSString *)messagingAPILevel {
    return [NSString stringWithFormat:@"%u", BAMessagingAPILevel];
}

- (NSString *)appVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)versionCode {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)pluginVersion {
    const char *pluginVersion = getenv("BATCH_PLUGIN_VERSION");
    if (pluginVersion != nil) {
        return [NSString stringWithFormat:@"%@", [NSString stringWithCString:pluginVersion
                                                                    encoding:NSUTF8StringEncoding]];
    }

    return nil;
}

- (NSString *)bridgeVersion {
    const char *bridgeVersion = getenv("BATCH_BRIDGE_VERSION");
    if (bridgeVersion != nil) {
        return [NSString stringWithFormat:@"%@", [NSString stringWithCString:bridgeVersion
                                                                    encoding:NSUTF8StringEncoding]];
    }

    return nil;
}

- (BANotificationAuthorizationSettings *)notificationAuthorizationSettings {
    // Allows for easy mocking
    return [BACoreCenter instance].status.notificationAuthorization.currentSettings;
}

- (NSString *)notifType {
    // Check if we have a BANotificationAuthorization ready
    // If we do, yay
    // If we don't, fallback on the older API

    BANotificationAuthorizationSettings *settings = [self notificationAuthorizationSettings];
    if (settings != nil && settings.status != BANotificationAuthorizationStatusWaitingForValue) {
        if (settings.status == BANotificationAuthorizationStatusDenied ||
            settings.status == BANotificationAuthorizationStatusNotRequested) {
            // We exclude some status rather than only check for Provisional or Granted as Apple
            // might add some more later on
            return @"0";
        }

        // When using the API, we directly read "sound" and "badge"
        // For "alert", we actually mix "alert", "lockscreen" and "notification center":
        // if any of them is true, we say that alert is on.
        NSUInteger alertTypes = BANotificationAuthorizationTypesAlert | BANotificationAuthorizationTypesLockscreen |
                                BANotificationAuthorizationTypesNotificationCenter;

        /**
         Badge   = 1 << 0
         Sound   = 1 << 1
         Alert   = 1 << 2
         */
        int types = 0;
        BANotificationAuthorizationTypes settingTypes = settings.types;

        if ((settingTypes & BANotificationAuthorizationTypesBadge) > 0) {
            types |= 1 << 0;
        }

        if ((settingTypes & BANotificationAuthorizationTypesSound) > 0) {
            types |= 1 << 1;
        }

        if ((settingTypes & alertTypes) > 0) {
            types |= 1 << 2;
        }

        return [NSString stringWithFormat:@"%i", types];
    } else {
        [BALogger debugForDomain:@"Properties"
                         message:@"Tried to read notificaiton authorization, but was nil or waiting for a value. "
                                 @"Falling back on pre-iOS 10 API."];
    }

    return [self notifTypeFallback];
}

- (NSString *)notifTypeFallback {
    // Version that works using the legacy API
    // Might not give the best result (false positives)
    __block int types = 0;

    [BAThreading performBlockOnMainThread:^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      types = (int)[[UIApplication sharedApplication] currentUserNotificationSettings].types;
#pragma clang diagnostic pop
    }];

    return [NSString stringWithFormat:@"%i", types];
}

- (NSString *)sessionIdentifier {
    return [BACoreCenter instance].status.sessionManager.sessionID;
}

@end
