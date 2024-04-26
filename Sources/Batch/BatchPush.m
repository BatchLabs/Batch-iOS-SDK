//
//  BatchPush.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BACoreCenter.h>
#import <Batch/BANotificationAuthorization.h>
#import <Batch/BAParameter.h>
#import <Batch/BAPushCenter.h>
#import <Batch/BatchPush.h>

NSString *const BatchPushReceivedNotification = @"BatchPushReceivedNotification";

NSString *const BatchPushOpenedNotification = @"BatchPushOpenedNotification";

NSString *const BatchPushOpenedNotificationPayloadKey = @"payload";

NSString *const BatchUserActionInputTextFieldPlaceholderKey = @"BatchUserActionInputTextFieldPlaceholder";

NSString *const BatchPushUserDidAnswerAuthorizationRequestNotification =
    @"BatchPushUserDidAnswerAuthorizationRequestNotification";

NSString *const BatchPushUserDidAcceptKey = @"BatchPushUserDidAcceptKey";

@implementation BatchPush

+ (void)setupPush {
    // This used to set Batch Push's state to YES, but now we forcibly enable the push
}

// Change the used remote notification types.
+ (void)setRemoteNotificationTypes:(BatchNotificationType)type {
    [BAPushCenter setRemoteNotificationTypes:type];
}

+ (void)setSupportsAppNotificationSettings:(BOOL)supportsAppNotificationSettings {
    [[BAPushCenter instance] setSupportsAppNotificationSettings:supportsAppNotificationSettings];
}

+ (BOOL)supportsAppNotificationSettings {
    return [[BAPushCenter instance] supportsAppNotificationSettings];
}

+ (void)requestNotificationAuthorization {
    [[BAPushCenter instance] requestNotificationAuthorizationWithCompletionHandler:nil];
}

+ (void)requestNotificationAuthorizationWithCompletionHandler:
    (void (^_Nullable)(BOOL granted, NSError *__nullable error))completionHandler {
    [[BAPushCenter instance] requestNotificationAuthorizationWithCompletionHandler:completionHandler];
}

+ (void)requestProvisionalNotificationAuthorization {
    [[BAPushCenter instance] requestProvisionalNotificationAuthorizationWithCompletionHandler:nil];
}

+ (void)requestProvisionalNotificationAuthorizationWithCompletionHandler:
    (void (^_Nullable)(BOOL granted, NSError *__nullable error))completionHandler {
    [[BAPushCenter instance] requestProvisionalNotificationAuthorizationWithCompletionHandler:completionHandler];
}

+ (void)refreshToken {
    [[BAPushCenter instance] refreshToken];
}

+ (void)openSystemNotificationSettings {
    [[BAPushCenter instance] openSystemNotificationSettings];
}

// Clear the application's badge on the homescreen.
+ (void)clearBadge {
    [BAPushCenter clearBadge];
}

// Clear the app's notifications in the notification center. Also clears your badge.
+ (void)dismissNotifications {
    [BAPushCenter dismissNotifications];
}

// Disable Batch's automatic deeplink handling
+ (void)setEnableAutomaticDeeplinkHandling:(BOOL)handleDeeplinks {
    [[BAPushCenter instance] setHandleDeeplinks:handleDeeplinks];
}

+ (BOOL)enableAutomaticDeeplinkHandling {
    return [[BAPushCenter instance] handleDeeplinks];
}

+ (NSString *)deeplinkFromUserInfo:(NSDictionary *)userInfo {
    return [BAPushCenter deeplinkFromUserInfo:userInfo];
}

+ (NSString *)lastKnownPushToken {
    NSString *token = [BAParameter objectForKey:kParametersPushTokenKey fallback:nil];

    if ([token isKindOfClass:[NSString class]]) {
        return token;
    }

    return nil;
}

+ (void)disableAutomaticIntegration {
    [BAPushCenter disableAutomaticIntegration];
}

+ (void)handleDeviceToken:(NSData *)token {
    [BAPushCenter handleDeviceToken:token];
}

+ (BOOL)isBatchPush:(NSDictionary *)userInfo {
    return [BAPushCenter isBatchPush:userInfo];
}

+ (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center
             willPresentNotification:(UNNotification *)notification
       willShowSystemForegroundAlert:(BOOL)willShowSystemForegroundAlert {
    [BAPushCenter handleUserNotificationCenter:center
                       willPresentNotification:notification
                 willShowSystemForegroundAlert:willShowSystemForegroundAlert];
}

+ (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center
      didReceiveNotificationResponse:(UNNotificationResponse *)response {
    [BAPushCenter handleUserNotificationCenter:center didReceiveNotificationResponse:response];
}

+ (BOOL)isBatchNotification:(nonnull UNNotification *)notification {
    return [BAPushCenter isBatchPush:notification.request.content.userInfo];
}

+ (nullable NSString *)deeplinkFromNotification:(nonnull UNNotification *)notification {
    return [BAPushCenter deeplinkFromUserInfo:notification.request.content.userInfo];
}

@end

@implementation BatchUNUserNotificationCenterDelegate

+ (BatchUNUserNotificationCenterDelegate *)sharedInstance {
    static BatchUNUserNotificationCenterDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BatchUNUserNotificationCenterDelegate alloc] init];
    });

    return sharedInstance;
}

+ (void)registerAsDelegate {
    [UNUserNotificationCenter currentNotificationCenter].delegate = [self sharedInstance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _showForegroundNotifications = true;
    }
    return self;
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    [BAPushCenter handleUserNotificationCenter:center
                       willPresentNotification:notification
                 willShowSystemForegroundAlert:self.showForegroundNotifications];

    UNNotificationPresentationOptions options = UNNotificationPresentationOptionNone;
    if (self.showForegroundNotifications) {
        options = UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound;

        if (@available(iOS 14.0, *)) {
            options = options | UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner;
        } else {
            options = options | UNNotificationPresentationOptionAlert;
        }
    }

    if (completionHandler) {
        completionHandler(options);
    };
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(UNNotificationResponse *)response
             withCompletionHandler:(void (^)(void))completionHandler {
    [BAPushCenter handleUserNotificationCenter:center didReceiveNotificationResponse:response];

    if (completionHandler) {
        completionHandler();
    }
}

@end
