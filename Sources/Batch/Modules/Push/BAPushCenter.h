//
//  BAPushCenter.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

#import <Batch/BACenterMulticastDelegate.h>
#import <Batch/BAPartialApplicationDelegate.h>
#import <Batch/BatchPush.h>

// Is the push open coming from UNUserNotificationCenterDelegate's didResponse callback?
extern NSString *const kBATPushOpenedNotificationOriginatesFromUNResponseKey;

// Is the push open coming from application:didFinishLaunchingWithOptions?
extern NSString *const kBATPushOpenedNotificationOriginatesFromAppDelegate;

/*!
 @class BAPushCenter
 @abstract Central control point of Batch push services.
 @discussion Used for managing all push features.
 */
@interface BAPushCenter : NSObject <BACenterProtocol, BAPartialApplicationDelegate>

/*!
 @property shouldAutomaticallyRetreivePushToken
 @abstract YES registerForRemoteNotifications should be called after the notificaiton user popup. Only YES if user
 called "[BatchPush registerForRemoteNotifications]"
 */
@property (assign, nonatomic) BOOL shouldAutomaticallyRetreivePushToken;

/*!
 @property handleDeeplinks
 @abstract YES (default value) if Batch should handle deeplinks
 */
@property BOOL handleDeeplinks;

/*!
 @property supportsAppNotificationSettings
 @abstract YES (default value) if Batch should tell iOS 12+ that the app supports notification settings
 */
@property BOOL supportsAppNotificationSettings;

/*!
 @property swizzled
 @abstract Swizzling state.
 */
@property BOOL swizzled;

/*!
 @property shouldSwizzle
 @abstract Whether the SDK should swizzle the app delegate or not. Default YES, can be changed by the user.
 */
@property BOOL shouldSwizzle;

/*!
 @property startPushUserInfo
 @abstract userInfo of the push the app was started with, if it was.
 */
@property NSDictionary *startPushUserInfo;

/*!
 @method instance
 @abstract Instance method.
 @return BAPushCenter singleton.
 */
+ (BAPushCenter *)instance __attribute__((warn_unused_result));

/*!
 @method batchWillStart
 @abstract Called before Batch runtime begins its process.
 @discussion Implements anything that deserve it before all the process starts, like subscribing to events or watever.
 */
+ (void)batchWillStart;

/*!
 @method setRemoteNotificationTypes:
 @abstract Change the used remote notification types.
 @discussion Default value is: BatchNotificationTypeBadge | BatchNotificationTypeSound | BatchNotificationTypeAlert
 @param type : A bit mask specifying the types of notifications the app accepts.
 */
+ (void)setRemoteNotificationTypes:(BatchNotificationType)type;

/**
 Ask for the permission to display notifications
 */
- (void)requestNotificationAuthorization;

/**
 Ask for the permission to display provisional notifications
 */
- (void)requestProvisionalNotificationAuthorization;

/**
 Equivalent to [UIApplication.sharedApplication registerForRemoteNotifications]
 */
- (void)refreshToken;

/**
 Open iOS' settings on the app's notification page
 */
- (void)openSystemNotificationSettings;

/*!
 @method setNotificationsCategories:
 @abstract Set the notification action categories to iOS.
 @discussion You should call this every time your app starts
 @param categories  : A set of UIUserNotificationCategory or UNNotificationCategory instances that define the groups of
 actions a notification may include. If you try to register UIUserNotificationCategory instances on iOS 10, Batch will
 automatically do a best effort conversion to UNNotificationCategory. If you don't want this behaviour, please use the
 standard UIApplication methods.
 */
+ (void)setNotificationsCategories:(NSSet *)categories;

/*!
 @method clearBadge
 @abstract Clear the application's badge on the homescreen.
 @discussion You do not need to call this if you already call dismissNotifications.
 */
+ (void)clearBadge;

/*!
 @method dismissNotifications
 @abstract Clear the app's notifications in the notification center. Also clears your badge.
 @discussion Call this when you want to remove the notifications. Your badge is removed afterwards, so if you want one,
 you need to set it up again.
 */
+ (void)dismissNotifications;

/*!
 @method enableAutomaticDeeplinkHandling:
 @abstract Set whether Batch Push should automatically try to handle deeplinks
 @discussion By default, this is set to YES. You need to call everytime your app is restarted, this option is not
 persisted.
 */
+ (void)enableAutomaticDeeplinkHandling:(BOOL)handleDeeplinks;

/*!
 @method deeplinkFromUserInfo:
 @abstract Get Batch Push's deeplink from a notification's userInfo.
 @return Batch's Deeplink, or nil if not found.
 */
+ (NSString *)deeplinkFromUserInfo:(NSDictionary *)userData NS_AVAILABLE_IOS(8_0);

/*!
 @method disableAutomaticIntegration
 @abstract Disable the push's automatic integration. If you call this, you are responsible of forwarding your
 application's delegate calls to Batch. If you don't, some parts of the SDK and Dashboard will break.
 @warning This must be called before you start Batch, or it will have no effect.
 */
+ (void)disableAutomaticIntegration;

/*!
 @method handleDeviceToken
 @abstract Registers a device token to Batch. You should call this method in
 "application:didRegisterForRemoteNotificationsWithDeviceToken:".
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't
 implement this method, Batch's push features will NOT work.
 @param token : The untouched "deviceToken" NSData argument given to you in the application delegate method.
 */
+ (void)handleDeviceToken:(NSData *)token;

/*!
 @method isBatchPush
 @abstract Check if the received push is a Batch one.
 @warning If you have a custom push implementation into your app you should call this method before doing anything else.
 @param userInfo : The untouched "userInfo" NSDictionary argument given to you in the application delegate method.
 @return If it returns true, you should not handle the push.
 */
+ (BOOL)isBatchPush:(NSDictionary *)userInfo;

/*!
 @method handleNotification
 @abstract Make Batch process a notification. You should call this method in "application:didReceiveRemoteNotification:"
 or "application:didReceiveRemoteNotification:fetchCompletionHandler:".
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't
 implement this method, Batch's push features will NOT work.
 @param userInfo : The untouched "userInfo" NSDictionary argument given to you in the application delegate method.
 */
+ (void)handleNotification:(NSDictionary *)userInfo;

/*!
 @method handleNotification
 @abstract Make Batch process a notification action. You should call this method in
 "application:handleActionWithIdentifier:forRemoteNotification:completionHandler:" or
 "application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:".
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't
 implement this method, Batch's push features will NOT work.
 @param userInfo : The untouched "userInfo" NSDictionary argument given to you in the application delegate method.
 @param identifier : The action's identifier. Used for tracking purposes: it can match your raw action name, or be a
 more user-friendly string;
 */
+ (void)handleNotification:(NSDictionary *)userInfo actionIdentifier:(NSString *)identifier;

/*!
 @method handleNotification
 @abstract Make Batch process the user notification settings change. You should call this method in
 "application:didRegisterUserNotificationSettings:".
 @warning If you didn't call "disableAutomaticIntegration", this method will have no effect. If you called it but don't
 implement this method, Batch's push features will NOT work.
 @param notificationSettings : The untouched "notificationSettings" UIUserNotificationSettings* argument given to you in
 the application delegate method.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (void)handleRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings NS_AVAILABLE_IOS(8_0);
#pragma clang diagnostic pop

/**
 Make Batch process a foreground notification. You should call this method if you set your own
 UNUserNotificationCenterDelegate, in userNotificationCenter:willPresentNotification:withCompletionHandler:

 @param center                          Original center argument
 @param notification                    Original notification argument
 @param willShowSystemForegroundAlert   Whether you will tell the framework to show this notification, or. Batch uses
 this value to adjust its behaviour accordingly for a better user experience.
 */
+ (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center
             willPresentNotification:(UNNotification *)notification
       willShowSystemForegroundAlert:(BOOL)willShowSystemForegroundAlert NS_AVAILABLE_IOS(10_0);

/**
 Make Batch process a background notification open/action. You should call this method if you set your own
 UNUserNotificationCenterDelegate, in userNotificationCenter:didReceiveNotificationResponse:

 @param center       Original center argument
 @param response     Original response argument
 */
+ (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center
      didReceiveNotificationResponse:(UNNotificationResponse *)response NS_AVAILABLE_IOS(10_0);

/**
 Make Batch process a notification payload

 Most code should use handleUserNotificationCenter:didReceiveNotificationResponse: but getting an instance of
 UNNotificationResponse isn't doable manually
 */
- (void)parseNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
    originatesFromUNDelegateResponse:(BOOL)originatesFromUNDelegateResponse;

@end
