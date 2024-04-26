//
//  BAPushSystemHelper.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BAPushSystemHelper.h>

#import <UserNotifications/UserNotifications.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BALogger.h>
#import <Batch/BANotificationAuthorization.h>
#import <Batch/BAThreading.h>

@implementation BAPushSystemHelper

- (void)registerForRemoteNotificationsTypes:(BatchNotificationType)notifType
               providesNotificationSettings:(BOOL)providesSettings
                          completionHandler:(void (^)(BOOL granted, NSError *error))completionHandler {
    UNAuthorizationOptions options = [self systemOptionsForBatchTypes:notifType];

    if (providesSettings) {
        options |= UNAuthorizationOptionProvidesAppNotificationSettings;
    }

    [self requestAuthorization:options completionHandler:completionHandler];
}

- (void)registerForProvisionalNotifications:(BatchNotificationType)notifType
               providesNotificationSettings:(BOOL)providesSettings
                          completionHandler:(void (^)(BOOL granted, NSError *error))completionHandler {
    UNAuthorizationOptions options = [self systemOptionsForBatchTypes:notifType];

    options |= UNAuthorizationOptionProvisional;

    if (providesSettings) {
        options |= UNAuthorizationOptionProvidesAppNotificationSettings;
    }

    [self requestAuthorization:options completionHandler:completionHandler];
}

#pragma mark Private methods

- (UNAuthorizationOptions)systemOptionsForBatchTypes:(BatchNotificationType)batchTypes {
    UNAuthorizationOptions retOptions = UNAuthorizationOptionNone;

    if (batchTypes & BatchNotificationTypeAlert) {
        retOptions |= UNAuthorizationOptionAlert;
    }
    if (batchTypes & BatchNotificationTypeBadge) {
        retOptions |= UNAuthorizationOptionBadge;
    }
    if (batchTypes & BatchNotificationTypeSound) {
        retOptions |= UNAuthorizationOptionSound;
    }
    if (batchTypes & BatchNotificationTypeCarPlay) {
        retOptions |= UNAuthorizationOptionCarPlay;
    }
    if (batchTypes & BatchNotificationTypeCritical) {
        retOptions |= UNAuthorizationOptionCriticalAlert;
    }

    return retOptions;
}

- (void)requestAuthorization:(UNAuthorizationOptions)options
           completionHandler:(void (^)(BOOL granted, NSError *error))completionHandler {
    [[UNUserNotificationCenter currentNotificationCenter]
        requestAuthorizationWithOptions:options
                      completionHandler:^(BOOL granted, NSError *_Nullable error) {
                        [BAThreading performBlockOnMainThreadAsync:^{
                          [[UIApplication sharedApplication] registerForRemoteNotifications];

                          [[NSNotificationCenter defaultCenter]
                              postNotificationName:BatchPushUserDidAnswerAuthorizationRequestNotification
                                            object:nil
                                          userInfo:@{BatchPushUserDidAcceptKey : [NSNumber numberWithBool:granted]}];
                        }];

                        BANotificationAuthorization *notifAuth =
                            [BACoreCenter instance].status.notificationAuthorization;
                        [notifAuth settingsMayHaveChanged];

                        if (completionHandler) {
                            completionHandler(granted, error);
                        }
                      }];
}

@end
