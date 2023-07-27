//
//  BatchPush.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

/// Notification sent by Batch Push when it gets a remote notification. (Deprecated)
///
/// This includes the one your app is started with (even though it is only sent when Batch starts)
/// - Warning: __Deprecated:__ Use ``BatchPushOpenedNotification`` which is more predictable.
FOUNDATION_EXPORT NSString *_Nonnull const BatchPushReceivedNotification
    __attribute__((deprecated("Use BatchPushOpenedNotification, which is more predictable.")));

/// Notification sent by Batch Push when a notification has been opened by the user.
///
/// Background wakeups and notifications received while in the foreground (that are not presented to the user) will not
/// trigger this notification. If your application doesn't properly call Batch in your `UNUserNotificationDelegate` or
/// doesn't setup any delegate at all, this notification __WILL__ misbehave: It might miss opens, or report background
/// fetchs as opens.
///
/// This notification's userInfo contains private keys that are not guaranteed to be the same between SDK releases, but
/// you can use ``BatchPushOpenedNotificationPayloadKey`` to get the payload.
///
/// - Note: This notification will not be sent if Batch hasn't been started or has been opted out from.
FOUNDATION_EXPORT NSString *_Nonnull const BatchPushOpenedNotification;

/// Key used to access the payload in the userInfo of a ``BatchPushOpenedNotification``.
/// The value is a NSDictionary.
FOUNDATION_EXPORT NSString *_Nonnull const BatchPushOpenedNotificationPayloadKey;

/// Key that Batch will read the placeholder from when converting a `UIUserNotificationAction` into a
/// `UNNotificationAction`
FOUNDATION_EXPORT NSString *_Nonnull const BatchUserActionInputTextFieldPlaceholderKey;

/// Notification sent by Batch Push when the alert view requesting users to allow push notifications was dismissed.
///
/// Notification's userInfo will contain a ``BatchPushUserDidAcceptKey`` regarding the choice made by the user, whose
/// value is a boolean in an NSNumber.
FOUNDATION_EXPORT NSString *_Nonnull const BatchPushUserDidAnswerAuthorizationRequestNotification;

/// Key contain in userInfo when using a ``BatchPushUserDidAnswerAuthorizationRequestNotification``
FOUNDATION_EXPORT NSString *_Nonnull const BatchPushUserDidAcceptKey;

/// Remote notification types wrapper.
/// Wraps iOS remote notification types in a compatible way.
typedef NS_OPTIONS(NSUInteger, BatchNotificationType) {
    BatchNotificationTypeNone = 0,
    BatchNotificationTypeBadge = 1 << 0,
    BatchNotificationTypeSound = 1 << 1,
    BatchNotificationTypeAlert = 1 << 2,
    BatchNotificationTypeCarPlay = 1 << 3,
    BatchNotificationTypeCritical = 1 << 4,
};

/// Notification sources
/// A notification source represents how the push was sent from Batch: via the Transactional API, or using a Push
/// Campaign.
typedef NS_ENUM(NSUInteger, BatchNotificationSource) {
    BatchNotificationSourceUnknown,
    BatchNotificationSourceCampaign,
    BatchNotificationSourceTransactional,
    BatchNotificationSourceTrigger,
};

/// Provides Batch-related Push methods.
/// Actions you can perform in BatchPush.
@interface BatchPush : NSObject

/// Controls whether Batch should tell iOS 12+ that your application supports opening in-app notification settings from
/// the system. Supporting this also requires implementing the corresponding method in
/// `UNUserNotificationCenterDelegate`.
@property (class) BOOL supportsAppNotificationSettings;

/// Do not call this method, as BatchPush only consists of static methods.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Setup Batch Push system. (Deprecated)
///
/// You can call this method from any thread.
/// - Warning: __Deprecated:__ This method is deprectaed. You don't need to do anything else besides removing this call,
/// Batch Push will still work as expected.
+ (void)setupPush NS_AVAILABLE_IOS(8_0)
    __attribute__((deprecated("setupPush is deprecated. You don't need to do anything else besides removing this call, "
                              "Batch Push will still work as expected.")));

/// Change the used remote notification types when registering.
///
/// This does __NOT__ change the user preferences once already registered: to do so, you should point them to the native
/// system settings. Default value is: `BatchNotificationTypeBadge | BatchNotificationTypeSound |
/// BatchNotificationTypeAlert`.
/// - Parameter type: A bit mask specifying the types of notifications the app accepts.
+ (void)setRemoteNotificationTypes:(BatchNotificationType)type NS_AVAILABLE_IOS(8_0);

/// Method to trigger the iOS popup that asks the user if they wants to allow notifications to be displayed, then
/// get a Push token.
///
/// The default registration is made with Badge, Sound and Alert.
/// If you want another configuration: call ``BatchPush/setRemoteNotificationTypes:``.
/// You should call this at a strategic moment, like at the end of your welcome.
///
/// Batch will automatically ask for a push token when the user replies.
+ (void)requestNotificationAuthorization NS_AVAILABLE_IOS(8_0);

/// Method to ask iOS for a provisional notification authorization.
///
/// Batch will then automatically ask for a push token.
/// Provisional authorization will __NOT__ show a popup asking for user authorization,
/// but notifications will __NOT__ be displayed on the lock screen, or as a banner when the phone is unlocked.
/// They will directly be sent to the notification center, accessible when the user swipes up on the lockscreen, or down
/// from the statusbar when unlocked.
///
/// This method does nothing on iOS 11 or lower.
+ (void)requestProvisionalNotificationAuthorization NS_AVAILABLE_IOS(8_0);

/// Ask iOS to refresh the push token. If the app didn't prompt the user for consent yet, this will not be done.
///
/// You should call this at the start of your app, to make sure Batch always gets a valid token after app updates.
+ (void)refreshToken NS_AVAILABLE_IOS(8_0);

/// Open the system settings on your applications' notification settings.
+ (void)openSystemNotificationSettings NS_AVAILABLE_IOS(8_0);

/// Method to trigger the iOS popup that asks the user if they wants to allow Push Notifications, then get a Push token.
/// (Deprecated)
///
/// The default registration is made with Badge, Sound and Alert.
/// If you want another configuration: call`setRemoteNotificationTypes:`.
/// You should call this at a strategic moment, like at the end of your welcome.
/// Equivalent to calling ``BatchPush/requestNotificationAuthorization``
/// - Warning: __Deprecated:__ This method is deprectaed. Use ``BatchPush/requestNotificationAuthorization`` and
/// ``BatchPush/refreshToken`` separately. More info in our documentation.
+ (void)registerForRemoteNotifications NS_AVAILABLE_IOS(8_0)__attribute__((
    deprecated("Use requestNotificationAuthorization and refreshToken separately. More info in our documentation.")));

/// Method to trigger the iOS popup that asks the user if they want to allow Push Notifications and register to APNS.
/// (Deprecated)
///
/// Default registration is made with Badge, Sound and Alert.
/// If you want another configuration: call ``BatchPush/setRemoteNotificationTypes:``.
/// You should call this at a strategic moment, like at the end of your welcome.
///
/// - Parameter categories: A set of `UIUserNotificationCategory` or `UNNotificationCategory` instances that define the
/// groups of actions a notification may include. If you try to register `UIUserNotificationCategory` instances on iOS
/// 10, Batch will automatically do a best effort conversion to `UNNotificationCategory`. If you don't want this
/// behaviour, please use the standard `UIApplication` methods.
/// - Warning: __Deprecated:__ Use ``BatchPush/setNotificationsCategories:`` and
/// ``BatchPush/registerForRemoteNotifications`` separately.
+ (void)registerForRemoteNotificationsWithCategories:(nullable NSSet *)categories
    NS_AVAILABLE_IOS(8_0)
        __attribute__((deprecated("Use setNotificationCategories and registerForRemoteNotifications separately.")));

/// Set the notification action categories to iOS.
///
/// You should call this every time your app starts.
/// - Important: On versions prior to iOS 10, this call __MUST__ be followed by
/// ``BatchPush/registerForRemoteNotifications``, or else the categories will __NOT__ be updated.
/// - Parameter categories:  set of `UIUserNotificationCategory` or `UNNotificationCategory` instances that define the
/// groups of actions a notification may include. If you try to register `UIUserNotificationCategory` instances on iOS
/// 10, Batch will automatically do a best effort conversion to `UNNotificationCategory`. If you don't want this
/// behaviour, please use the standard `UIApplication` methods.
+ (void)setNotificationsCategories:(nullable NSSet *)categories NS_AVAILABLE_IOS(8_0);

/// Clear the application's badge on the homescreen.
///
/// You do not need to call this if you already called ``BatchPush/dismissNotifications``.
+ (void)clearBadge NS_AVAILABLE_IOS(8_0);

/// Clear the app's notifications in the notification center. Also clears your badge.
///
/// Call this when you want to remove the notifications. Your badge is removed afterwards, so if you want one, you need
/// to set it up again.
/// - Important: Be careful, this method also clears your badge.
+ (void)dismissNotifications NS_AVAILABLE_IOS(8_0);

/// Set whether Batch Push should automatically try to handle deeplinks.
///
/// By default, this is set to __YES__. You need to call everytime your app is restarted, this option is not persisted.
///
/// If your goal is to implement a custom deeplink format, you should see ``Batch/Batch/deeplinkDelegate`` which allows
/// you to manually handle the deeplink string, but doesn't put the burden of parsing the notification payload on you.
///
/// - Note: Setting this to false will __DISABLE__ the deeplink delegate, leaving the handling of the link  entirely up
/// to you.
/// - Important: If Batch is set to handle your deeplinks, it will *automatically* call the fetch completion handler (if
/// applicable) with `UIBackgroundFetchResultNewData.
/// - Parameter handleDeeplinks: Whether Batch should handle deeplinks automatically.
+ (void)enableAutomaticDeeplinkHandling:(BOOL)handleDeeplinks NS_AVAILABLE_IOS(8_0);

/// Get Batch Push's deeplink from a notification's userInfo.
///
/// - Parameter userData The notification's payload.
/// - Returns: Batch's Deeplink, or nil if not found.
+ (nullable NSString *)deeplinkFromUserInfo:(nonnull NSDictionary *)userData NS_AVAILABLE_IOS(8_0);

/// Get the last known push token.
///
/// Your application should still register for remote notifications once per launch, in order to keep this value valid.
/// - Important: The returned token might be outdated and invalid if this method is called too early in your application
/// lifecycle.
/// - Returns: A push token, nil if unavailable.
+ (nullable NSString *)lastKnownPushToken NS_AVAILABLE_IOS(8_0);

/// Disable the push's automatic integration.
///
/// If you call this, you are responsible of forwarding your application's delegate and
/// `UNUserNotificationCenterDelegate` calls to Batch. If you don't, some parts of the SDK and Dashboard will break.
/// Calling this method automatically calls `disableAutomaticNotificationCenterIntegration`.
/// - Important: This must be called before you start Batch, or it will have no effect.
+ (void)disableAutomaticIntegration NS_AVAILABLE_IOS(8_0);

/// Registers a device token to Batch.
///
/// You should call this method in `application:didRegisterForRemoteNotificationsWithDeviceToken:`.
/// - Important: If you didn't call ``BatchPush/disableAutomaticIntegration``, this method will have no effect.
/// If you called it but don't implement this method, Batch's push features will __NOT__ work.
/// - Parameter token: The untouched `deviceToken` NSData argument given to you in the application delegate method.
+ (void)handleDeviceToken:(nonnull NSData *)token NS_AVAILABLE_IOS(8_0);

/// Check if the received push is a Batch one.
///
/// - Important: If you have a custom push implementation into your app you should call this method before doing
/// anything else.
/// - Parameter  userInfo: The untouched `userInfo` NSDictionary argument given to you in the application delegate
/// method.
/// - Returns: Wheter it is a Batch'sPush. If it returns true, you should not handle the push.
+ (BOOL)isBatchPush:(nonnull NSDictionary *)userInfo NS_AVAILABLE_IOS(8_0);

/// Make Batch process a notification. (Deprecated)
///
/// You should call this method in `application:didReceiveRemoteNotification:` or
/// `application:didReceiveRemoteNotification:fetchCompletionHandler:`.
/// - Important: If you didn't call ``BatchPush/disableAutomaticIntegration``, this method will have no effect.
/// If you called it but don't implement this method, Batch's push features will __NOT__ work.
/// - Parameter userInfo: The untouched `userInfo` NSDictionary argument given to you in the application delegate
/// method.
/// - Warning: __Deprecated:__ Implement `UNUserNotificationCenterDelegate` using
/// ``BatchUNUserNotificationCenterDelegate`` or your own implementation.
+ (void)handleNotification:(nonnull NSDictionary *)userInfo
    __attribute__((deprecated("Implement UNUserNotificationCenterDelegate using BatchUNUserNotificationCenterDelegate "
                              "or your own implementation")));

/// Make Batch process a notification action.
///
/// You should call this method in `application:handleActionWithIdentifier:forRemoteNotification:completionHandler:`
/// or `application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:`
/// - Important: If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but
/// don't implement this method, Batch's push features will NOT work.
/// - Parameters:
///   - userInfo: The untouched `userInfo` NSDictionary argument given to you in the application delegate method.
///   - identifier: The action's identifier. Used for tracking purposes: it can match your raw action name, or be a more
///   user-friendly string.
+ (void)handleNotification:(nonnull NSDictionary *)userInfo
          actionIdentifier:(nullable NSString *)identifier NS_AVAILABLE_IOS(8_0);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/// Make Batch process the user notification settings change. (Deprecated)
///
/// You should call this method in `application:didRegisterUserNotificationSettings:`.
/// - Important: If you didn't call ``BatchPush/disableAutomaticIntegration``, this method will have no effect. If you
/// called it but don't implement this method, Batch's push features will __NOT__ work.
/// - Parameter notificationSettings: The untouched `notificationSettings UIUserNotificationSettings*` argument given to
/// you in the application delegate method.
/// - Warning: __Deprecated:__ Use ``BatchPush/requestNotificationAuthorization``.
+ (void)handleRegisterUserNotificationSettings:(nonnull UIUserNotificationSettings *)notificationSettings
    __attribute__((deprecated("Use BatchPush.requestNotificationAuthorization()")));

#pragma clang diagnostic pop

#pragma mark UserNotifications methods

/// Make Batch process a foreground notification.
///
/// You should call this method if you set your own `UNUserNotificationCenterDelegate`,
/// in `userNotificationCenter:willPresentNotification:withCompletionHandler:`.
/// - Parameters:
///   - center Original center argument
///   - notification Original notification argument
///   - willShowSystemForegroundAlert Whether you will tell the framework to show this notification, or not. Batch
///   uses this value to adjust its behaviour accordingly for a better user experience. Return 'true' if you're
///   returning .alert (or more) to iOS' completion handler.
+ (void)handleUserNotificationCenter:(nonnull UNUserNotificationCenter *)center
             willPresentNotification:(nonnull UNNotification *)notification
       willShowSystemForegroundAlert:(BOOL)willShowSystemForegroundAlert
    NS_AVAILABLE_IOS(10_0)NS_SWIFT_NAME(handle(userNotificationCenter:willPresent:willShowSystemForegroundAlert:));

/// Make Batch process a background notification open/action.
///
/// You should call this method if you set your own `UNUserNotificationCenterDelegate`,
/// in `userNotificationCenter:didReceiveNotificationResponse:`.
/// - Parameters:
///   - center: Original center argument.
///   - response: Original response argument.
+ (void)handleUserNotificationCenter:(nonnull UNUserNotificationCenter *)center
      didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response NS_AVAILABLE_IOS(10_0)
                                         NS_SWIFT_NAME(handle(userNotificationCenter:didReceive:));

@end

/// Implementation of `UNUserNotificationCenterDelegate` that
/// Foreground notifications will not be displayed with the default settings.
///
/// Use the property `showForegroundNotifications` to control this.
/// This class should not be subclassed. If you want to do so, please implement `UNUserNotificationCenterDelegate`
/// directly
__attribute__((objc_subclassing_restricted))
@interface BatchUNUserNotificationCenterDelegate : NSObject<UNUserNotificationCenterDelegate>

/// Shared singleton `BatchUNUserNotificationCenterDelegate`.
///
/// Using this allows you to set the instance as `UNUserNotificationCenter`'s delegate without having to retain it
/// yourself. The shared instance is lazily loaded.
@property (class, retain, readonly, nonnull) BatchUNUserNotificationCenterDelegate *sharedInstance;

/// Registers this class' sharedInstance as `UNUserNotificationCenter's` delegate.
///
/// Equivalent to calling `[UNUserNotificationCenter currentNotificationCenter].delegate =
/// BatchUNUserNotificationCenterDelegate.sharedInstance`.
+ (void)registerAsDelegate;

/// Should iOS display notifications even if the app is in foreground?
/// Default: false
@property (assign) BOOL showForegroundNotifications;

@end
