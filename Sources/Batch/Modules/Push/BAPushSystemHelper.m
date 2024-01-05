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
               providesNotificationSettings:(BOOL)providesSettings {
    UNAuthorizationOptions options = [self systemOptionsForBatchTypes:notifType];

    if (providesSettings) {
        options |= UNAuthorizationOptionProvidesAppNotificationSettings;
    }

    [self requestAuthorization:options];
}

- (void)registerForProvisionalNotifications:(BatchNotificationType)notifType
               providesNotificationSettings:(BOOL)providesSettings {
    UNAuthorizationOptions options = [self systemOptionsForBatchTypes:notifType];

    options |= UNAuthorizationOptionProvisional;

    if (providesSettings) {
        options |= UNAuthorizationOptionProvidesAppNotificationSettings;
    }

    [self requestAuthorization:options];
}

- (void)registerCategories:(NSSet *)categories {
    NSSet<UNNotificationCategory *> *categoriesToRegister = nil;

    if ([categories count] > 0) {
        if ([self set:categories onlyContainsElementsOfClass:[UNNotificationCategory class]]) {
            categoriesToRegister = categories;
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

        else if ([self set:categories onlyContainsElementsOfClass:[UIUserNotificationCategory class]]) {
            [BALogger debugForDomain:@"BAPushCompatUN"
                             message:@"Converting instances of UIUserNotificationCategory to UNNotificationCategory"];
            categoriesToRegister = [self convertLegacyCategoriesForSet:categories];
        }
#pragma clang diagnostic pop

        else {
            [BALogger publicForDomain:@"BatchPush"
                              message:@"Provided categories set contains more than one kind of class, Batch will NOT "
                                      @"register ANY actions, please only fill the set with UNNotificationCategory or "
                                      @"UIUserNotificationCategory instances."];
        }
    }

    if (categoriesToRegister == nil) {
        categoriesToRegister = [NSSet new];
    }

    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categoriesToRegister];
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

- (void)requestAuthorization:(UNAuthorizationOptions)options {
    BatchPushNotificationSettingStatus currentStatus = [BANotificationAuthorization applicationSettings];

    [[UNUserNotificationCenter currentNotificationCenter]
        requestAuthorizationWithOptions:options
                      completionHandler:^(BOOL granted, NSError *_Nullable error) {
                        [BAThreading performBlockOnMainThreadAsync:^{
                          [[UIApplication sharedApplication] registerForRemoteNotifications];

                          if (currentStatus == BatchPushNotificationSettingStatusUndefined) {
                              [[NSNotificationCenter defaultCenter]
                                  postNotificationName:BatchPushUserDidAnswerAuthorizationRequestNotification
                                                object:nil
                                              userInfo:@{
                                                  BatchPushUserDidAcceptKey : [NSNumber numberWithBool:granted]
                                              }];
                          }
                        }];

                        BANotificationAuthorization *notifAuth =
                            [BACoreCenter instance].status.notificationAuthorization;
                        if (granted && [BANotificationAuthorization applicationSettings] ==
                                           BatchPushNotificationSettingStatusUndefined) {
                            [notifAuth setApplicationSettings:BatchPushNotificationSettingStatusEnabled
                                              skipServerEvent:true];
                        }
                        [notifAuth settingsMayHaveChanged];
                      }];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (NSSet<UNNotificationCategory *> *)convertLegacyCategoriesForSet:
    (NSSet<UIUserNotificationCategory *> *)legacyCategories {
    NSMutableSet<UNNotificationCategory *> *retVal = nil;

    if (legacyCategories == nil) {
        return nil;
    }

    retVal = [NSMutableSet new];

    BOOL alreadyWarnedAboutContext = false;

    for (UIUserNotificationCategory *legacyCategory in legacyCategories) {
        NSArray *actions =
            [self convertLegacyActions:[legacyCategory actionsForContext:UIUserNotificationActionContextDefault]];
        NSArray *minimalActions =
            [self convertLegacyActions:[legacyCategory actionsForContext:UIUserNotificationActionContextMinimal]];

        if (!alreadyWarnedAboutContext && [actions count] > 0 && [minimalActions count] > 0) {
            alreadyWarnedAboutContext = true;
            [BALogger
                publicForDomain:@"BatchPush"
                        message:@"You're attempting to register legacy UIUserNotificationCategory instances rather "
                                @"than UNNotificationCategory instances on iOS 10. Batch usually silently converts "
                                @"them, but since you've added both actions for Default and Minimal contexts, Batch "
                                @"will only register the Default context actions to iOS, since iOS 10 does not support "
                                @"this deprecated behaviour. Only the first two actions will be displayed in a minimal "
                                @"context. In order to fix this warning, please register native UNNotificationCategory "
                                @"instances when, and only when, running on iOS 10 or higher."];
        }

        // If we don't have actions, use the minimal actions
        if ([actions count] == 0) {
            actions = minimalActions;
        }

        if (actions == nil) {
            actions = @[];
        }

        // If users want native iOS 10 functions, they should register it themselves
        [retVal addObject:[UNNotificationCategory categoryWithIdentifier:legacyCategory.identifier
                                                                 actions:actions
                                                       intentIdentifiers:@[]
                                                                 options:0]];
    }

    return retVal;
}

- (NSArray<UNNotificationAction *> *)convertLegacyActions:(NSArray<UIUserNotificationAction *> *)legacyActions {
    NSMutableArray<UNNotificationAction *> *retVal = nil;

    if (legacyActions == nil) {
        return nil;
    }

    retVal = [NSMutableArray new];

    for (UIUserNotificationAction *legacyAction in legacyActions) {
        [retVal addObject:[self convertLegacyAction:legacyAction]];
    }

    return retVal;
}

- (nonnull UNNotificationAction *)convertLegacyAction:(nonnull UIUserNotificationAction *)legacyAction {
    UNNotificationActionOptions options = UNNotificationActionOptionNone;

    if (legacyAction.destructive) {
        options |= UNNotificationActionOptionDestructive;
    }

    if (legacyAction.activationMode == UIUserNotificationActivationModeForeground) {
        options |= UNNotificationActionOptionForeground;
    }

    if (legacyAction.isAuthenticationRequired) {
        options |= UNNotificationActionOptionAuthenticationRequired;
    }

    if (legacyAction.behavior == UIUserNotificationActionBehaviorTextInput) {
        NSString *buttonTitle =
            [[legacyAction parameters] objectForKey:UIUserNotificationTextInputActionButtonTitleKey];
        if (buttonTitle == nil) {
            buttonTitle = @"Send"; // That's possibly a bad idea.
        }

        NSString *placeholder = [[legacyAction parameters] objectForKey:BatchUserActionInputTextFieldPlaceholderKey];
        if (placeholder == nil) {
            placeholder = @"";
        }

        return [UNTextInputNotificationAction actionWithIdentifier:legacyAction.identifier
                                                             title:legacyAction.title
                                                           options:options
                                              textInputButtonTitle:buttonTitle
                                              textInputPlaceholder:placeholder];
    } else {
        return [UNNotificationAction actionWithIdentifier:legacyAction.identifier
                                                    title:legacyAction.title
                                                  options:options];
    }
}

#pragma clang diagnostic pop

- (BOOL)set:(NSSet *)set onlyContainsElementsOfClass:(Class)class {
    for (NSObject *item in set) {
        if (![item isKindOfClass:class]) {
            return false;
        }
    }
    return true;
}

@end
