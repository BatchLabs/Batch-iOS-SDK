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

/*!
 @const BatchPushReceivedNotification
 @abstract Notification send by Batch Push when it gets a remote notification. This includes the one your app is started with (even though it is only sent when Batch starts)
 */
FOUNDATION_EXPORT NSString *const BatchPushReceivedNotification;

/*!
 @const BatchUserActionInputTextFieldPlaceholderKey
 @abstract Key that Batch will read the placeholder from when converting a UIUserNotificationAction into a UNNotificationAction
 */
FOUNDATION_EXPORT NSString *const BatchUserActionInputTextFieldPlaceholderKey;

/*!
 @enum BatchNotificationType
 @abstract Remote notification types wrapper.
 @discussion Wrap iOS 8 and inferior remote notification types.
 */
typedef NS_OPTIONS(NSUInteger, BatchNotificationType)
{
    BatchNotificationTypeNone    = 0,
    BatchNotificationTypeBadge   = 1 << 0,
    BatchNotificationTypeSound   = 1 << 1,
    BatchNotificationTypeAlert   = 1 << 2,
};

/*!
 @class BatchPush
 @abstract Provides the Batch-related Push methods
 @discussion Actions you can perform in BatchPush.
 */
@interface BatchPush : NSObject

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method setupPush
 @abstract Activate Batch Push system.
 @discussion You can call this method from any thread.
 */
+ (void)setupPush NS_AVAILABLE_IOS(8_0) __attribute__((deprecated("setupPush is deprecated. You don't need to do anything else besides removing this call, Batch Push will still work as expected.")));;

/*!
@method setRemoteNotificationTypes:
@abstract Change the used remote notification types.
@discussion Default value is: BatchNotificationTypeBadge | BatchNotificationTypeSound | BatchNotificationTypeAlert
@param type : A bit mask specifying the types of notifications the app accepts.
*/
+ (void)setRemoteNotificationTypes:(BatchNotificationType)type NS_AVAILABLE_IOS(8_0);

/*!
 @method registerForRemoteNotifications
 @abstract Call to trigger the iOS popup that asks the user if he wants to allow Push Notifications and register to APNS.
 @discussion Default registration is made with Badge, Sound and Alert. If you want another configuration: call `setRemoteNotificationTypes:`.
 @discussion You should call this at a strategic moment, like at the end of your welcome.
 */
+ (void)registerForRemoteNotifications NS_AVAILABLE_IOS(8_0);

/*!
 @method registerForRemoteNotificationsWithCategories:
 @abstract Call to trigger the iOS popup that asks the user if he wants to allow Push Notifications and register to APNS.
 @discussion Default registration is made with Badge, Sound and Alert. If you want another configuration: call `setRemoteNotificationTypes:`.
 @discussion You should call this at a strategic moment, like at the end of your welcome.
 @param categories  : A set of UIUserNotificationCategory or UNNotificationCategory instances that define the groups of actions a notification may include. If you try to register UIUserNotificationCategory instances on iOS 10, Batch will automatically do a best effort conversion to UNNotificationCategory. If you don't want this behaviour, please use the standard UIApplication methods.
 */
+ (void)registerForRemoteNotificationsWithCategories:(NSSet *)categories NS_AVAILABLE_IOS(8_0) __attribute__((deprecated("Use setNotificationCategories and registerForRemoteNotifications separately.")));

/*!
 @method setNotificationsCategories:
 @abstract Set the notification action categories to iOS.
 @discussion You should call this every time your app starts
 @warning On versions prior to iOS 10, this call MUST be followed by registerForRemoteNotifications, or else the categories will NOT be updated.
 @param categories  : A set of UIUserNotificationCategory or UNNotificationCategory instances that define the groups of actions a notification may include. If you try to register UIUserNotificationCategory instances on iOS 10, Batch will automatically do a best effort conversion to UNNotificationCategory. If you don't want this behaviour, please use the standard UIApplication methods.
 */
+ (void)setNotificationsCategories:(NSSet *)categories NS_AVAILABLE_IOS(8_0);

/*!
 @method clearBadge
 @abstract Clear the application's badge on the homescreen.
 @discussion You do not need to call this if you already call dismissNotifications.
 */
+ (void)clearBadge NS_AVAILABLE_IOS(8_0);

/*!
 @method dismissNotifications
 @abstract Clear the app's notifications in the notification center. Also clears your badge.
 @discussion Call this when you want to remove the notifications. Your badge is removed afterwards, so if you want one, you need to set it up again.
 */
+ (void)dismissNotifications NS_AVAILABLE_IOS(8_0);

/*!
 @method enableAutomaticDeeplinkHandling:
 @abstract Set whether Batch Push should automatically try to handle deeplinks
 @discussion By default, this is set to YES. You need to call everytime your app is restarted, this option is not persisted.
 @warning If Batch is set to handle your deeplinks, it will *automatically* call the fetch completion handler (if applicable) with UIBackgroundFetchResultNewData.
 */
+ (void)enableAutomaticDeeplinkHandling:(BOOL)handleDeeplinks NS_AVAILABLE_IOS(8_0);

/*!
 @method deeplinkFromUserInfo:
 @abstract Get Batch Push's deeplink from a notification's userInfo.
 @return Batch's Deeplink, or nil if not found.
 */
+ (NSString *)deeplinkFromUserInfo:(NSDictionary *)userData NS_AVAILABLE_IOS(8_0);

/*!
 @method lastKnownPushToken
 @abstract Get the last known push token.
 @warning The returned token might be outdated and invalid if this method is called too early in your application lifecycle.
 @discussion Your application should still register for remote notifications once per launch, in order to keep this value valid.
 @return A push token, nil if unavailable.
 */
+ (NSString *)lastKnownPushToken NS_AVAILABLE_IOS(8_0);

/*!
 @method disableAutomaticIntegration
 @abstract Disable the push's automatic integration. If you call this, you are responsible of forwarding your application's delegate and UNUserNotificationCenterDelegate calls to Batch. If you don't, some parts of the SDK and Dashboard will break. Calling this method automatically calls disableAutomaticNotificationCenterIntegration.
 @warning This must be called before you start Batch, or it will have no effect.
 */
+ (void)disableAutomaticIntegration NS_AVAILABLE_IOS(8_0);

/*!
 @method handleDeviceToken:
 @abstract Registers a device token to Batch. You should call this method in "application:didRegisterForRemoteNotificationsWithDeviceToken:".
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't implement this method, Batch's push features will NOT work.
 @param token : The untouched "deviceToken" NSData argument given to you in the application delegate method.
 */
+ (void)handleDeviceToken:(NSData*)token NS_AVAILABLE_IOS(8_0);

/*!
 @method handleNotification:
 @abstract Make Batch process a notification. You should call this method in "application:didReceiveRemoteNotification:" or "application:didReceiveRemoteNotification:fetchCompletionHandler:".
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't implement this method, Batch's push features will NOT work.
 @param userInfo : The untouched "userInfo" NSDictionary argument given to you in the application delegate method.
 */
+ (void)handleNotification:(NSDictionary*)userInfo NS_AVAILABLE_IOS(8_0);

/*!
 @method handleNotification:actionIdentifier:
 @abstract Make Batch process a notification action. You should call this method in "application:handleActionWithIdentifier:forRemoteNotification:completionHandler:" or "application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:".
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't implement this method, Batch's push features will NOT work.
 @param userInfo : The untouched "userInfo" NSDictionary argument given to you in the application delegate method.
 @param identifier : The action's identifier. Used for tracking purposes: it can match your raw action name, or be a more user-friendly string;
 */
+ (void)handleNotification:(NSDictionary*)userInfo actionIdentifier:(NSString*)identifier NS_AVAILABLE_IOS(8_0);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

/*!
 @method handleNotification
 @abstract Make Batch process the user notification settings change. You should call this method in "application:didRegisterUserNotificationSettings:".
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't implement this method, Batch's push features will NOT work.
 @param notificationSettings : The untouched "notificationSettings" UIUserNotificationSettings* argument given to you in the application delegate method.
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
