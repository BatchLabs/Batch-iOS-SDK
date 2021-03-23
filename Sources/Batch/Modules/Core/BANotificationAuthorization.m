#import <Batch/BANotificationAuthorization.h>

#import <UserNotifications/UserNotifications.h>

#import <Batch/BAThreading.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BASessionManager.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAParameter.h>
#import <Batch/BatchPushPrivate.h>

@implementation BANotificationAuthorizationSettings

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.applicationSetting = -1;
        self.status = BANotificationAuthorizationStatusNotRequested;
        self.types = BANotificationAuthorizationTypesNone;
    }
    return self;
}

- (BOOL)isEqualToSettings:(BANotificationAuthorizationSettings*)object
{
    if (self == object) {
        return true;
    }
    
    if (![object isKindOfClass:[BANotificationAuthorizationSettings class]]) {
        return false;
    }
    
    if (self.status != object.status) {
        return false;
    }
    
    if (self.types != object.types) {
        return false;
    }
    
    if (self.applicationSetting != object.applicationSetting) {
        return false;
    }
    
    return true;
}

/**
 Like dictionaryReprensentation but returns nil when the value hasn't been fetched yet
 */
- (nullable NSDictionary*)optionalDictionaryRepresentation
{
    return self.status == BANotificationAuthorizationStatusWaitingForValue ? nil : [self dictionaryRepresentation];
}

/**
 Be careful not to change this in a non retro-compatible way, or handle these cases gracefully
 */
- (nonnull NSDictionary*)persistableRepresentation
{
    return [self dictionaryRepresentation];
}

- (nonnull NSDictionary*)dictionaryRepresentation
{
    return @{
             @"status": @(self.status),
             @"types": @(self.types),
             @"app_setting": @(self.applicationSetting),
             };
}

@end

@implementation BANotificationAuthorization

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.currentSettings = [BANotificationAuthorizationSettings new];
        [self settingsMayHaveChanged];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

+ (BatchPushNotificationSettingStatus)applicationSettings
{
    return [(NSNumber*)[BAParameter objectForKey:kParametersAppNotificationSettingsKey
                                     kindOfClass:[NSNumber class]
                                        fallback:@(BatchPushNotificationSettingStatusUndefined)] unsignedIntegerValue];
}

- (void)setApplicationSettings:(BatchPushNotificationSettingStatus)appSettings skipServerEvent:(BOOL)skipServerEvent
{
    [BAParameter setValue:@(appSettings) forKey:kParametersAppNotificationSettingsKey saved:true];
    if (!skipServerEvent) {
        [self settingsMayHaveChanged];
    }
}

- (BOOL)shouldFetchSettings
{
    return self.currentSettings.status == BANotificationAuthorizationStatusUnknown;
}

- (void)fetch:(void(^ _Nullable)(BANotificationAuthorizationSettings* _Nonnull))completionHandler
{
    [self fetchUN:completionHandler];
}

- (void)fetchUN:(void(^ _Nullable)(BANotificationAuthorizationSettings* _Nonnull))completionHandler NS_AVAILABLE_IOS(10.0) {
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        BANotificationAuthorizationSettings *baSettings = [BANotificationAuthorizationSettings new];
        
        switch (settings.authorizationStatus) {
            case UNAuthorizationStatusDenied:
                baSettings.status = BANotificationAuthorizationStatusDenied;
                break;
            case UNAuthorizationStatusAuthorized:
                baSettings.status = BANotificationAuthorizationStatusGranted;
                break;
            case UNAuthorizationStatusNotDetermined:
                baSettings.status = BANotificationAuthorizationStatusNotRequested;
                break;
            case UNAuthorizationStatusProvisional:
                baSettings.status = BANotificationAuthorizationStatusProvisional;
                break;
            default: // Future enum caes
                baSettings.status = BANotificationAuthorizationStatusUnknown;
                break;
        }
        
        BANotificationAuthorizationTypes types = BANotificationAuthorizationTypesNone;
        
        if ((settings.alertSetting & UNNotificationSettingEnabled) > 0) {
            types |= BANotificationAuthorizationTypesAlert;
        }
        
        if ((settings.soundSetting & UNNotificationSettingEnabled) > 0) {
            types |= BANotificationAuthorizationTypesSound;
        }
        
        if ((settings.badgeSetting & UNNotificationSettingEnabled) > 0) {
            types |= BANotificationAuthorizationTypesBadge;
        }
        
        if ((settings.notificationCenterSetting & UNNotificationSettingEnabled) > 0) {
            types |= BANotificationAuthorizationTypesNotificationCenter;
        }
        
        if ((settings.lockScreenSetting & UNNotificationSettingEnabled) > 0) {
            types |= BANotificationAuthorizationTypesLockscreen;
        }
        
        baSettings.types = types;
        baSettings.applicationSetting = [BANotificationAuthorization applicationSettings];
        
        [self updateSettings:baSettings completionHandler:completionHandler];
    }];
}

- (void)settingsMayHaveChanged
{
    if (self.currentSettings.status != BANotificationAuthorizationStatusUnknown) {
        [BALogger debugForDomain:@"Core" message:@"Notification authorization settings may have changed. Refreshing..."];
    }
    [self fetch:nil];
}

- (void)updateSettings:(BANotificationAuthorizationSettings* _Nonnull)settings completionHandler:(void(^ _Nullable)(BANotificationAuthorizationSettings* _Nonnull))completionHandler
{
    BANotificationAuthorizationSettings *oldSettings = self.currentSettings;
    BANotificationAuthorizationSettings *newSettings = oldSettings;
    
    if (![settings isEqualToSettings:oldSettings]) {
        [BALogger debugForDomain:@"Core" message:@"Fetched new notification authorization settings"];
        newSettings = settings;
        self.currentSettings = settings;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            // Check if the notification settings changed between the last time we sent them to the server and now
            BANotificationAuthorizationSettings* sentSettings = [self persistedSettings];
            if (![settings isEqualToSettings:sentSettings]) {
                // Send the event to the server, and store it so that future calls of this method don't send the same event multiple times
                // But don't send it if the value is of no use to the server
                if (settings.status != BANotificationAuthorizationStatusUnknown &&
                    settings.status != BANotificationAuthorizationStatusWaitingForValue &&
                    settings.status != BANotificationAuthorizationStatusNotRequested) {
                    [BATrackerCenter trackPrivateEvent:@"_NOTIF_STATUS_CHANGE" parameters:settings.dictionaryRepresentation collapsable:true];
                }
                [self persistSettings:settings];
            }
        });
    }
    
    if (completionHandler) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            completionHandler(newSettings);
        });
    }
}

- (void)applicationWillEnterForeground
{
    [self settingsMayHaveChanged];
}

#pragma mark Settings persistence

- (void)persistSettings:(BANotificationAuthorizationSettings* _Nonnull)settings
{
    if (settings == nil) {
        return;
    }
    
    [BAParameter setValue:[settings persistableRepresentation] forKey:kParametersNotificationAuthSentStatusKey saved:YES];
}

- (nullable BANotificationAuthorizationSettings*)persistedSettings
{
    NSDictionary *settingsDict = [BAParameter objectForKey:kParametersNotificationAuthSentStatusKey fallback:nil];
    if ([settingsDict isKindOfClass:[NSDictionary class]])
    {
        NSNumber *types = settingsDict[@"types"];
        NSNumber *status = settingsDict[@"status"];
        
        if ([types isKindOfClass:[NSNumber class]] &&
            [status isKindOfClass:[NSNumber class]]) {
            
            BANotificationAuthorizationSettings *settings = [BANotificationAuthorizationSettings new];
            settings.applicationSetting = [BANotificationAuthorization applicationSettings];
            settings.types = [types unsignedIntegerValue];
            settings.status = [status unsignedIntegerValue];
            return settings;
        }
    }
    
    return nil;
}

@end
