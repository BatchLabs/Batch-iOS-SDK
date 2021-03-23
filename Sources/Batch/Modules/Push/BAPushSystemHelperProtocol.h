//
//  BAPushSystemHelperProtocol.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BatchPush.h>

@protocol BAPushSystemHelperProtocol

// Register for remote notifications for the given types and whether the app should declare that it supports a settings deeplink or not
- (void)registerForRemoteNotificationsTypes:(BatchNotificationType)notifType providesNotificationSettings:(BOOL)providesSettings;

// Register for provisional notifications for the given types and whether the app should declare that it supports a settings deeplink or not
- (void)registerForProvisionalNotifications:(BatchNotificationType)notifType providesNotificationSettings:(BOOL)providesSettings;

// Register the given categories to iOS. The set is not typed so the user can give us either iOS 8+ or 10+ classes (or any class, you must check the input beforehand)
- (void)registerCategories:(NSSet*)categories;

@end
