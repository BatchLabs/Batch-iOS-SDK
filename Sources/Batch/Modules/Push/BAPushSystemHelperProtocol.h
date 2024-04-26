//
//  BAPushSystemHelperProtocol.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BatchPush.h>

@protocol BAPushSystemHelperProtocol

// Register for remote notifications for the given types and whether the app should declare that it supports a settings
// deeplink or not
- (void)registerForRemoteNotificationsTypes:(BatchNotificationType)notifType
               providesNotificationSettings:(BOOL)providesSettings
                          completionHandler:(void (^)(BOOL granted, NSError *error))completionHandler;

// Register for provisional notifications for the given types and whether the app should declare that it supports a
// settings deeplink or not
- (void)registerForProvisionalNotifications:(BatchNotificationType)notifType
               providesNotificationSettings:(BOOL)providesSettings
                          completionHandler:(void (^)(BOOL granted, NSError *error))completionHandler;

@end
