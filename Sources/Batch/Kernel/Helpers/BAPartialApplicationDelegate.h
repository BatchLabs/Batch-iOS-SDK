//
//  BAPartialApplicationDelegate.h
//  Batch
//
//  Created by arnaud on 15/09/2020.
//  Copyright © 2020 Batch.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Partial representation of UIApplicationDelegate, only implementing what we need
@protocol BAPartialApplicationDelegate <NSObject>

@required
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings NS_AVAILABLE_IOS(8_0);

#pragma clang diagnostic pop

- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(nullable NSString *)identifier
         forRemoteNotification:(NSDictionary *)userInfo
             completionHandler:(void (^)(void))completionHandler;

- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(nullable NSString *)identifier
         forRemoteNotification:(NSDictionary *)userInfo
              withResponseInfo:(NSDictionary *)responseInfo
             completionHandler:(void (^)(void))completionHandler;

@end

NS_ASSUME_NONNULL_END
