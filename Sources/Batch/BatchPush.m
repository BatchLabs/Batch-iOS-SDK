//
//  BatchPush.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BatchPush.h>
#import <Batch/BatchPushPrivate.h>
#import <Batch/BAPushCenter.h>
#import <Batch/BAParameter.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BANotificationAuthorization.h>

NSString *const BatchPushReceivedNotification = @"BatchPushReceivedNotification";

NSString *const BatchPushOpenedNotification = @"BatchPushOpenedNotification";

NSString *const BatchPushOpenedNotificationPayloadKey = @"payload";

NSString *const BatchUserActionInputTextFieldPlaceholderKey = @"BatchUserActionInputTextFieldPlaceholder";

NSString *const BatchPushUserDidAnswerAuthorizationRequestNotification = @"BatchPushUserDidAnswerAuthorizationRequestNotification";

NSString *const BatchPushUserDidAcceptKey = @"BatchPushUserDidAcceptKey";

@implementation BatchPush

+ (BatchPushNotificationSettingStatus)notificationSettingStatus
{
    return [BANotificationAuthorization applicationSettings];
}

+ (void)setNotificationSettingStatus:(BatchPushNotificationSettingStatus)status
{
    switch (status)
    {
        case BatchPushNotificationSettingStatusUndefined:
        case BatchPushNotificationSettingStatusEnabled:
        case BatchPushNotificationSettingStatusDisabled:
            [[[[BACoreCenter instance] status] notificationAuthorization] setApplicationSettings:status skipServerEvent:false];
            break;
        default:
            [BALogger errorForDomain:@"BatchPush" message:@"Invalid BatchPushNotificationSettingStatus value"];
            break;
    }
}

+ (void)setupPush
{
    // This used to set Batch Push's state to YES, but now we forcibly enable the push
}

// Change the used remote notification types.
+ (void)setRemoteNotificationTypes:(BatchNotificationType)type
{
    [BAPushCenter setRemoteNotificationTypes:type];
}

+ (void)setSupportsAppNotificationSettings:(BOOL)supportsAppNotificationSettings
{
    [[BAPushCenter instance] setSupportsAppNotificationSettings:supportsAppNotificationSettings];
}

+ (BOOL)supportsAppNotificationSettings
{
    return [[BAPushCenter instance] supportsAppNotificationSettings];
}

+ (void)requestNotificationAuthorization
{
    [[BAPushCenter instance] requestNotificationAuthorization];
}

+ (void)requestProvisionalNotificationAuthorization
{
    [[BAPushCenter instance] requestProvisionalNotificationAuthorization];
}

+ (void)refreshToken
{
    [[BAPushCenter instance] refreshToken];
}

+ (void)openSystemNotificationSettings
{
     [[BAPushCenter instance] openSystemNotificationSettings];
}

// Call to trigger the iOS popup that asks the user if he wants to allow Push Notifications.
+ (void)registerForRemoteNotifications
{
    [[BAPushCenter instance] requestNotificationAuthorization];
}

+ (void)registerForRemoteNotificationsWithCategories:(NSSet *)categories
{
    [BAPushCenter setNotificationsCategories:categories];
    [[BAPushCenter instance] requestNotificationAuthorization];
}

+ (void)setNotificationsCategories:(NSSet *)categories
{
    [BAPushCenter setNotificationsCategories:categories];
}

// Clear the application's badge on the homescreen.
+ (void)clearBadge
{
    [BAPushCenter clearBadge];
}

// Clear the app's notifications in the notification center. Also clears your badge.
+ (void)dismissNotifications
{
    [BAPushCenter dismissNotifications];
}

// Disable Batch's automatic deeplink handling
+ (void)enableAutomaticDeeplinkHandling:(BOOL)handleDeeplinks
{
    [BAPushCenter enableAutomaticDeeplinkHandling:handleDeeplinks];
}

+ (NSString *)deeplinkFromUserInfo:(NSDictionary *)userInfo
{
    return [BAPushCenter deeplinkFromUserInfo:userInfo];
}

+ (NSString *)lastKnownPushToken
{
    NSString *token = [BAParameter objectForKey:kParametersPushTokenKey fallback:nil];
    
    if ([token isKindOfClass:[NSString class]])
    {
        return token;
    }
    
    return nil;
}

+ (void)disableAutomaticIntegration
{
    [BAPushCenter disableAutomaticIntegration];
}

+ (void)handleDeviceToken:(NSData*)token
{
    [BAPushCenter handleDeviceToken:token];
}

+ (BOOL)isBatchPush:(NSDictionary*)userInfo
{
    return [BAPushCenter isBatchPush:userInfo];
}

+ (void)handleNotification:(NSDictionary*)userInfo
{
    [BAPushCenter handleNotification:userInfo];
}

+ (void)handleNotification:(NSDictionary*)userInfo actionIdentifier:(NSString*)identifier
{
    [BAPushCenter handleNotification:userInfo actionIdentifier:identifier];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (void)handleRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [BAPushCenter handleRegisterUserNotificationSettings:notificationSettings];
}
#pragma clang diagnostic pop

+ (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification willShowSystemForegroundAlert:(BOOL)willShowSystemForegroundAlert
{
    [BAPushCenter handleUserNotificationCenter:center willPresentNotification:notification willShowSystemForegroundAlert:willShowSystemForegroundAlert];
}

+ (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response
{
    [BAPushCenter handleUserNotificationCenter:center didReceiveNotificationResponse:response];
}

@end

@implementation BatchUNUserNotificationCenterDelegate

+ (BatchUNUserNotificationCenterDelegate *)sharedInstance
{
    static BatchUNUserNotificationCenterDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BatchUNUserNotificationCenterDelegate alloc] init];
    });
    
    return sharedInstance;
}

+ (void)registerAsDelegate
{
    [UNUserNotificationCenter currentNotificationCenter].delegate = [self sharedInstance];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _showForegroundNotifications = false;
    }
    return self;
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    [BAPushCenter handleUserNotificationCenter:center willPresentNotification:notification willShowSystemForegroundAlert:self.showForegroundNotifications];
    
    UNNotificationPresentationOptions options = UNNotificationPresentationOptionNone;
    if (self.showForegroundNotifications) {
        options = UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound;
        
        // TODO: Remove ifdef once we Xcode 12 supports macOS 11 Big Sur
#ifdef __IPHONE_14_0
        if (@available(iOS 14.0, *)) {
            options = options | UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner;
        } else {
            options = options | UNNotificationPresentationOptionAlert;
        }
#else
        options = options | UNNotificationPresentationOptionAlert;
#endif
    }
    
    if (completionHandler) {
        completionHandler(options);
    };
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
    [BAPushCenter handleUserNotificationCenter:center didReceiveNotificationResponse:response];
    
    if (completionHandler) {
        completionHandler();
    }
}

@end
