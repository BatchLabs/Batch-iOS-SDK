//
//  BatchPush.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

/**
 Notification sent by Batch Push when it gets a remote notification. This includes the one your app is started with (even though it is only sent when Batch starts)
 */
FOUNDATION_EXPORT NSString *const BatchPushReceivedNotification;

/**
 Key that Batch will read the placeholder from when converting a UIUserNotificationAction into a UNNotificationAction
 */
FOUNDATION_EXPORT NSString *const BatchUserActionInputTextFieldPlaceholderKey;

/**
 Remote notification types wrapper.
 Wraps iOS remote notification types in a compatible way.
 */
typedef NS_OPTIONS(NSUInteger, BatchNotificationType)
{
    BatchNotificationTypeNone    = 0,
    BatchNotificationTypeBadge   = 1 << 0,
    BatchNotificationTypeSound   = 1 << 1,
    BatchNotificationTypeAlert   = 1 << 2,
    BatchNotificationTypeCarPlay = 1 << 3,
    BatchNotificationTypeCritical = 1 << 4,
};

/**
 Notification sources
 A notification source represents how the push was sent from Batch: via the Transactional API, or using a Push Campaign
 */
typedef NS_ENUM(NSUInteger, BatchNotificationSource) {
    BatchNotificationSourceUnknown,
    BatchNotificationSourceCampaign,
    BatchNotificationSourceTransactional,
};

/**
 Provides Batch-related Push methods
 Actions you can perform in BatchPush.
 */
@interface BatchPush : NSObject

/**
 Controls whether Batch should tell iOS 12+ that your application supports opening in-app notification settings from the system.
 Supporting this also requires implementing the corresponding method in UNUserNotificationCenterDelegate.
 */
@property (class) BOOL supportsAppNotificationSettings;

/**
 Do not call this method, as BatchPush only consists of static methods.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Setup Batch Push system.
 You can call this method from any thread.
 
 @deprecated
 */
+ (void)setupPush NS_AVAILABLE_IOS(8_0) __attribute__((deprecated("setupPush is deprecated. You don't need to do anything else besides removing this call, Batch Push will still work as expected.")));;

/**
 Change the used remote notification types when registering.
 This does NOT change the user preferences once already registered: to do so, you should point them to the native system settings.
 Default value is: BatchNotificationTypeBadge | BatchNotificationTypeSound | BatchNotificationTypeAlert

 @param type A bit mask specifying the types of notifications the app accepts.
*/
+ (void)setRemoteNotificationTypes:(BatchNotificationType)type NS_AVAILABLE_IOS(8_0);

/**
 Call this method to trigger the iOS popup that asks the user if they wants to allow notifications to be displayed, then get a Push token.
 The default registration is made with Badge, Sound and Alert. If you want another configuration: call `setRemoteNotificationTypes:`.
 You should call this at a strategic moment, like at the end of your welcome.
 
 Batch will automatically ask for a push token when the user replies.
 */
+ (void)requestNotificationAuthorization NS_AVAILABLE_IOS(8_0);

/**
 Call this method to ask iOS for a provisional notification authorization.
 Batch will then automatically ask for a push token.
 
 Provisional authorization will NOT show a popup asking for user authorization,
 but notifications will NOT be displayed on the lock screen, or as a banner when the phone is unlocked.
 They will directly be sent to the notification center, accessible when the user swipes up on the lockscreen, or down from the statusbar when unlocked.
 
 This method does nothing on iOS 11 or lower.
 */
+ (void)requestProvisionalNotificationAuthorization NS_AVAILABLE_IOS(8_0);

/**
 Ask iOS to refresh the push token. If the app didn't prompt the user for consent yet, this will not be done.
 You should call this at the start of your app, to make sure Batch always gets a valid token after app updates.
 */
+ (void)refreshToken NS_AVAILABLE_IOS(8_0);

/**
 Open the system settings on your applications' notification settings.
 */
+ (void)openSystemNotificationSettings NS_AVAILABLE_IOS(8_0);

/**
 Call this method to trigger the iOS popup that asks the user if they wants to allow Push Notifications, then get a Push token.
 The default registration is made with Badge, Sound and Alert. If you want another configuration: call `setRemoteNotificationTypes:`.
 You should call this at a strategic moment, like at the end of your welcome.
 
 Equivalent to calling +[BatchPush requestNotificationAuthorization]
 */
+ (void)registerForRemoteNotifications NS_AVAILABLE_IOS(8_0) __attribute__((deprecated("Use requestNotificationAuthorization and refreshToken separately. More info in our documentation.")));

/**
 Call this method to trigger the iOS popup that asks the user if they want to allow Push Notifications and register to APNS.
 Default registration is made with Badge, Sound and Alert. If you want another configuration: call `setRemoteNotificationTypes:`.
 You should call this at a strategic moment, like at the end of your welcome.
 
 @param categories A set of UIUserNotificationCategory or UNNotificationCategory instances that define the groups of actions a notification may include. If you try to register UIUserNotificationCategory instances on iOS 10, Batch will automatically do a best effort conversion to UNNotificationCategory. If you don't want this behaviour, please use the standard UIApplication methods.
 
 @deprecated
 */
+ (void)registerForRemoteNotificationsWithCategories:(NSSet *)categories NS_AVAILABLE_IOS(8_0) __attribute__((deprecated("Use setNotificationCategories and registerForRemoteNotifications separately.")));

/**
 Set the notification action categories to iOS.
 You should call this every time your app starts.
 
 @warning On versions prior to iOS 10, this call MUST be followed by registerForRemoteNotifications, or else the categories will NOT be updated.
 
 @param categories A set of UIUserNotificationCategory or UNNotificationCategory instances that define the groups of actions a notification may include. If you try to register UIUserNotificationCategory instances on iOS 10, Batch will automatically do a best effort conversion to UNNotificationCategory. If you don't want this behaviour, please use the standard UIApplication methods.
 */
+ (void)setNotificationsCategories:(NSSet *)categories NS_AVAILABLE_IOS(8_0);

/**
 Clear the application's badge on the homescreen.
 You do not need to call this if you already called dismissNotifications.
 */
+ (void)clearBadge NS_AVAILABLE_IOS(8_0);

/**
 Clear the app's notifications in the notification center. Also clears your badge.
 Call this when you want to remove the notifications. Your badge is removed afterwards, so if you want one, you need to set it up again.
 
 @waning Be careful, this method also clears your badge.
 */
+ (void)dismissNotifications NS_AVAILABLE_IOS(8_0);

/**
 Set whether Batch Push should automatically try to handle deeplinks
 By default, this is set to YES. You need to call everytime your app is restarted, this option is not persisted.
 
 If your goal is to implement a custom deeplink format, you should see Batch.deeplinkDelegate which allows you to manually handle the deeplink string, but doesn't
 put the burden of parsing the notification payload on you.
 
 @warning If Batch is set to handle your deeplinks, it will *automatically* call the fetch completion handler (if applicable) with UIBackgroundFetchResultNewData.
 */
+ (void)enableAutomaticDeeplinkHandling:(BOOL)handleDeeplinks NS_AVAILABLE_IOS(8_0);

/**
 Get Batch Push's deeplink from a notification's userInfo.
 
 @return Batch's Deeplink, or nil if not found.
 */
+ (NSString *)deeplinkFromUserInfo:(NSDictionary *)userData NS_AVAILABLE_IOS(8_0);

/**
 Get the last known push token.
 
 Your application should still register for remote notifications once per launch, in order to keep this value valid.
 
 @warning The returned token might be outdated and invalid if this method is called too early in your application lifecycle.
 
 @return A push token, nil if unavailable.
 */
+ (NSString *)lastKnownPushToken NS_AVAILABLE_IOS(8_0);

/**
 Disable the push's automatic integration. If you call this, you are responsible of forwarding your application's delegate and UNUserNotificationCenterDelegate calls to Batch. If you don't, some parts of the SDK and Dashboard will break. Calling this method automatically calls disableAutomaticNotificationCenterIntegration.
 
 @warning This must be called before you start Batch, or it will have no effect.
 */
+ (void)disableAutomaticIntegration NS_AVAILABLE_IOS(8_0);

/**
 Registers a device token to Batch. You should call this method in "application:didRegisterForRemoteNotificationsWithDeviceToken:".
 
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't implement this method, Batch's push features will NOT work.
 
 @param token The untouched "deviceToken" NSData argument given to you in the application delegate method.
 */
+ (void)handleDeviceToken:(NSData*)token NS_AVAILABLE_IOS(8_0);

/**
 Make Batch process a notification. You should call this method in "application:didReceiveRemoteNotification:" or "application:didReceiveRemoteNotification:fetchCompletionHandler:".
 
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't implement this method, Batch's push features will NOT work.
 
 @param userInfo The untouched "userInfo" NSDictionary argument given to you in the application delegate method.
 */
+ (void)handleNotification:(NSDictionary*)userInfo NS_AVAILABLE_IOS(8_0);

/**
 Make Batch process a notification action. You should call this method in "application:handleActionWithIdentifier:forRemoteNotification:completionHandler:" or "application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:".
 
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't implement this method, Batch's push features will NOT work.
 
 @param userInfo The untouched "userInfo" NSDictionary argument given to you in the application delegate method.
 
 @param identifier The action's identifier. Used for tracking purposes: it can match your raw action name, or be a more user-friendly string;
 */
+ (void)handleNotification:(NSDictionary*)userInfo actionIdentifier:(NSString*)identifier NS_AVAILABLE_IOS(8_0);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/**
 Make Batch process the user notification settings change. You should call this method in "application:didRegisterUserNotificationSettings:".
 
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't implement this method, Batch's push features will NOT work.
 
 @param notificationSettings The untouched "notificationSettings" UIUserNotificationSettings* argument given to you in the application delegate method.
 */
+ (void)handleRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings NS_AVAILABLE_IOS(8_0);

#pragma clang diagnostic pop

#pragma mark UserNotifications methods (iOS 10 only)

/**
 Make Batch process a foreground notification. You should call this method if you set your own UNUserNotificationCenterDelegate, in userNotificationCenter:willPresentNotification:withCompletionHandler:

 @param center                          Original center argument
 @param notification                    Original notification argument
 @param willShowSystemForegroundAlert   Whether you will tell the framework to show this notification, or. Batch uses this value to adjust its behaviour accordingly for a better user experience.
 */
+ (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification willShowSystemForegroundAlert:(BOOL)willShowSystemForegroundAlert NS_AVAILABLE_IOS(10_0) NS_SWIFT_NAME(handle(userNotificationCenter:willPresent:willShowSystemForegroundAlert:));

/**
 Make Batch process a background notification open/action. You should call this method if you set your own UNUserNotificationCenterDelegate, in userNotificationCenter:didReceiveNotificationResponse:
 
 @param center       Original center argument
 @param response     Original response argument
 */
+ (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response NS_AVAILABLE_IOS(10_0) NS_SWIFT_NAME(handle(userNotificationCenter:didReceive:));

@end
