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

/// Change the used remote notification types when registering.
///
/// This does __NOT__ change the user preferences once already registered: to do so, you should point them to the native
/// system settings. Default value is: `BatchNotificationTypeBadge | BatchNotificationTypeSound |
/// BatchNotificationTypeAlert`.
/// - Parameter type: A bit mask specifying the types of notifications the app accepts.
+ (void)setRemoteNotificationTypes:(BatchNotificationType)type;

/// Method to trigger the iOS popup that asks the user if they wants to allow notifications to be displayed, then
/// get a Push token.
///
/// The default registration is made with Badge, Sound and Alert.
/// If you want another configuration: call ``BatchPush/setRemoteNotificationTypes:``.
/// You should call this at a strategic moment, like at the end of your welcome.
///
/// Batch will automatically ask for a push token when the user replies.
///
/// ```swift
/// func askPermission() {
///     BatchPush.requestNotificationAuthorization()
/// }
///
/// func askPermissionAsync() async {
///     // Async methods always have to use the completionHandler variant
///     let _ = try? await BatchPush.requestNotificationAuthorization()
/// }
/// ```
///
+ (void)requestNotificationAuthorization;

/// Method to trigger the iOS popup that asks the user if they wants to allow notifications to be displayed, then
/// get a Push token.
///
/// The default registration is made with Badge, Sound and Alert.
/// If you want another configuration: call ``BatchPush/setRemoteNotificationTypes:``.
/// You should call this at a strategic moment, like at the end of your welcome.
///
/// Batch will automatically ask for a push token when the user replies and call your completion handler.
///
/// ```swift
/// func askPermission() {
///     BatchPush.requestNotificationAuthorization { success, error in
///         // Do something
///     }
/// }
///
/// func askPermissionAsync() async {
///     let _ = try? await BatchPush.requestNotificationAuthorization()
/// }
/// ```
///
/// - Parameters:
///     - completionHandler: The block to execute asynchronously with the results. This block may execute on a
///     background thread. The block has no return value and has the following parameters:
///     - completionHandler(granted): A Boolean value indicating whether the person grants authorization. The value of
///     this parameter is YES when the person grants authorization for one or more options. The value is NO when the
///     person denies authorization or authorization is undetermined. Use
///     `UNUserNotificationCenter.current().getNotificationSettings()` to check the authorization status.
///     - completionHandler(error): An object containing error information or nil if no error occurs.
+ (void)requestNotificationAuthorizationWithCompletionHandler:
    (void (^_Nullable)(BOOL granted, NSError *__nullable error))completionHandler;

/// Method to ask iOS for a provisional notification authorization.
///
/// Batch will then automatically ask for a push token.
/// Provisional authorization will __NOT__ show a popup asking for user authorization,
/// but notifications will __NOT__ be displayed on the lock screen, or as a banner when the phone is unlocked.
/// They will directly be sent to the notification center, accessible when the user swipes up on the lockscreen, or down
/// from the statusbar when unlocked.
///
/// ```swift
/// func askPermission() {
///     BatchPush.requestProvisionalNotificationAuthorization()
/// }
///
/// func askPermissionAsync() async {
///     // Async methods always have to use the completionHandler variant
///     let _ = try? await BatchPush.requestProvisionalNotificationAuthorization()
/// }
/// ```
///
+ (void)requestProvisionalNotificationAuthorization;

/// Method to ask iOS for a provisional notification authorization.
///
/// Batch will then automatically ask for a push token.
/// Provisional authorization will __NOT__ show a popup asking for user authorization,
/// but notifications will __NOT__ be displayed on the lock screen, or as a banner when the phone is unlocked.
/// They will directly be sent to the notification center, accessible when the user swipes up on the lockscreen, or down
/// from the statusbar when unlocked.
///
/// Batch will automatically ask for a push token and call your completion handler.
///
/// If a user has already refused to show notifications, this method will still call the completion handler with errors.
///
/// ```swift
/// func askPermission() {
///     BatchPush.requestProvisionalNotificationAuthorization { success, error in
///         // Do something
///     }
/// }
///
/// func askPermissionAsync() async {
///     let _ = try? await BatchPush.requestProvisionalNotificationAuthorization()
/// }
/// ```
///
/// - Parameters:
///     - completionHandler: The block to execute asynchronously with the results. This block may execute on a
///     background thread. The block has no return value and has the following parameters:
///     - completionHandler(granted): A Boolean value indicating whether the person grants authorization. The value of
///     this parameter is YES when the person grants authorization for one or more options. The value is NO when the
///     person denies authorization or authorization is undetermined. Use
///     `UNUserNotificationCenter.current().getNotificationSettings()` to check the authorization status.
///     - completionHandler(error): An object containing error information or nil if no error occurs.
+ (void)requestProvisionalNotificationAuthorizationWithCompletionHandler:
    (void (^_Nullable)(BOOL granted, NSError *__nullable error))completionHandler;

/// Ask iOS to refresh the push token. If the app didn't prompt the user for consent yet, this will not be done.
///
/// You should call this at the start of your app, to make sure Batch always gets a valid token after app updates.
+ (void)refreshToken;

/// Open the system settings on your applications' notification settings.
+ (void)openSystemNotificationSettings;

/// Clear the application's badge on the homescreen.
+ (void)clearBadge;

/// Clear the app's notifications in the notification center
+ (void)dismissNotifications;

/// Set whether Batch Push should automatically try to handle deeplinks.
///
/// By default, this is set to __true__. You need to call everytime your app is restarted, this option is not persisted.
///
/// If your goal is to implement a custom deeplink format, you should see ``Batch/BatchSDK/deeplinkDelegate`` which
/// allows you to manually handle the deeplink string, but doesn't put the burden of parsing the notification payload on
/// you. If deeplink handling is disabled, the deeplink delegate will not be called.
///
/// - Note: Setting this to false will __DISABLE__ the deeplink delegate, leaving the handling of the link  entirely up
/// to you.
/// - Parameter handleDeeplinks: Whether Batch should handle deeplinks automatically.
@property (class) BOOL enableAutomaticDeeplinkHandling;

/// Get Batch Push's deeplink from a notification's userInfo.
///
/// - Parameter userData The notification's payload.
/// - Returns: Batch's Deeplink, or nil if not found.
+ (nullable NSString *)deeplinkFromUserInfo:(nonnull NSDictionary *)userData NS_SWIFT_NAME(deeplink(from:));

/// Get the last known push token.
///
/// Your application should still register for remote notifications once per launch, in order to keep this value valid.
/// - Important: The returned token might be outdated and invalid if this method is called too early in your application
/// lifecycle.
/// - Returns: A push token, nil if unavailable.
@property (class, nullable, readonly) NSString *lastKnownPushToken;

/// Disable the push's automatic integration.
///
/// If you call this, you are responsible of forwarding your application's delegate methods to Batch.If you don't, some
/// parts of the SDK and Dashboard will break.
/// - Important: This must be called before you start Batch, or it will have no effect.
+ (void)disableAutomaticIntegration;

/// Registers a device token to Batch.
///
/// You should call this method in `application:didRegisterForRemoteNotificationsWithDeviceToken:`.
/// - Important: If you didn't call ``BatchPush/disableAutomaticIntegration``, this method will have no effect.
/// If you called it but don't implement this method, Batch's push features will __NOT__ work.
/// - Parameter token: The untouched `deviceToken` NSData argument given to you in the application delegate method.
+ (void)handleDeviceToken:(nonnull NSData *)token;

/// Check if the received push is a Batch one.
///
/// - Important: If you have a custom push implementation into your app you should call this method before doing
/// anything else.
/// - Parameter  userInfo: The untouched `userInfo` NSDictionary argument given to you in the application delegate
/// method.
/// - Returns: Wheter it is a Batch'sPush. If it returns true, you should not handle the push.
+ (BOOL)isBatchPush:(nonnull NSDictionary *)userInfo;

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
    NS_SWIFT_NAME(handle(userNotificationCenter:willPresent:willShowSystemForegroundAlert:));

/// Make Batch process a background notification open/action.
///
/// You should call this method if you set your own `UNUserNotificationCenterDelegate`,
/// in `userNotificationCenter:didReceiveNotificationResponse:`.
/// - Parameters:
///   - center: Original center argument.
///   - response: Original response argument.
+ (void)handleUserNotificationCenter:(nonnull UNUserNotificationCenter *)center
      didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response
    NS_SWIFT_NAME(handle(userNotificationCenter:didReceive:));

/// Check a notification comes from Batch
///
/// - Parameter  notification: The UNNotification got from the operating system
/// method.
/// - Returns: Wheter it is a notification coming from Batch
+ (BOOL)isBatchNotification:(nonnull UNNotification *)notification;

/// Get the Batch deeplink from a notification
///
/// - Parameter notification The notification
/// - Returns: deeplink string, or nil if not found. Warning: the deeplink might not be a valid URL.
+ (nullable NSString *)deeplinkFromNotification:(nonnull UNNotification *)userData;

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
/// Default: true
@property (assign) BOOL showForegroundNotifications;

@end
