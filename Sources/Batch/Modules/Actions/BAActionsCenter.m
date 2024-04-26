//
//  BAActionsCenter.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAActionsCenter.h>

#import <StoreKit/StoreKit.h>
#import <UserNotifications/UserNotifications.h>

#if !TARGET_OS_MACCATALYST
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#endif

#import <Batch/BACoreCenter.h>
#import <Batch/BALocalCampaignsCenter.h>
#import <Batch/BALogger.h>
#import <Batch/BAPushCenter.h>
#import <Batch/BAQueryWebserviceClient.h>
#import <Batch/BAUserDataBuiltinActions.h>
#import <Batch/BAUserEventBuiltinActions.h>
#import <Batch/BAWindowHelper.h>
#import <Batch/BatchPush.h>

NSString *const kBAActionsReservedIdentifierPrefix = @"batch.";
// Special cased, as we need to prevent recursion. Make sure you change it alongside the reserved prefix
NSString *const kBAActionGroupName = @"batch.group";

#define ACTIONS_ERROR_DOMAIN @"com.batch.ios.actions"
#define JSON_ERROR_DOMAIN @"com.batch.module.actions.builtin"
#define LOGGER_DOMAIN @"BatchActions"

@implementation BAActionsCenter {
    NSMutableDictionary<NSString *, BatchUserAction *> *registeredActions;
    UIPasteboard *_pasteboard;
}

+ (instancetype)instance {
    static BAActionsCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BAActionsCenter alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pasteboard = [UIPasteboard generalPasteboard];
        registeredActions = [NSMutableDictionary new];

        [self registerInternalAction:[self deeplinkAction]];
        [self registerInternalAction:[self refreshLocalCampaignsAction]];
        [self registerInternalAction:[self requestNotificationsAction]];
        [self registerInternalAction:[self redirectSettingsAction]];
        [self registerInternalAction:[self smartReoptinAction]];
        [self registerInternalAction:[self trackingConsentAction]];
        [self registerInternalAction:[self groupAction]];
        [self registerInternalAction:[self clipboardAction]];
        [self registerInternalAction:[self ratingAction]];
        [self registerInternalAction:[BAUserDataBuiltinActions tagEditAction]];
        [self registerInternalAction:[BAUserEventBuiltinActions trackEventAction]];
    }
    return self;
}

- (void)registerInternalAction:(nonnull BatchUserAction *)action {
    if (action != nil) {
        [registeredActions setObject:action forKey:action.identifier];
    }
}

- (NSError *)registerAction:(nonnull BatchUserAction *)action {
    if (action == nil) {
        return [NSError errorWithDomain:ACTIONS_ERROR_DOMAIN
                                   code:BatchActionErrorInvalidArgument
                               userInfo:@{NSLocalizedDescriptionKey : @"Cannot register a nil action"}];
    }

    if ([action.identifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length ==
        0) {
        return [NSError
            errorWithDomain:ACTIONS_ERROR_DOMAIN
                       code:BatchActionErrorInvalidArgument
                   userInfo:@{NSLocalizedDescriptionKey : @"Cannot register an empty or nil action identifier"}];
    }

    NSString *identifier = [action.identifier lowercaseString];

    if ([identifier hasPrefix:kBAActionsReservedIdentifierPrefix]) {
        return [NSError errorWithDomain:ACTIONS_ERROR_DOMAIN
                                   code:BatchActionErrorInvalidArgument
                               userInfo:@{
                                   NSLocalizedDescriptionKey :
                                       [NSString stringWithFormat:@"The action's identifier cannot start with '%@'",
                                                                  kBAActionsReservedIdentifierPrefix]
                               }];
    }

    [registeredActions setObject:action forKey:identifier];

    return nil;
}

- (void)unregisterActionIdentifier:(nonnull NSString *)identifier {
    if ([identifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Trying to unregister an empty action identifier"];
        return;
    }

    identifier = [identifier lowercaseString];

    if ([identifier hasPrefix:kBAActionsReservedIdentifierPrefix]) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Trying to unregister a reserved batch action identifier"];
        return;
    }

    [registeredActions removeObjectForKey:identifier];
}

- (BOOL)performAction:(NSString *)identifier
             withArgs:(NSDictionary<NSString *, NSObject *> *)args
            andSource:(id<BatchUserActionSource>)source {
    if (identifier == nil || args == nil) {
        return NO;
    }

    BatchUserAction *action = [registeredActions objectForKey:[identifier lowercaseString]];

    if (action) {
        if (action.actionBlock) {
            action.actionBlock(action.identifier, args, source);
            return YES;
        } else {
            [BALogger debugForDomain:LOGGER_DOMAIN
                             message:@"An action was found for '%@' but its action block was nil", identifier];
        }
    }

    [BALogger debugForDomain:LOGGER_DOMAIN message:@"No action was found for identifier '%@'", identifier];

    return NO;
}

- (BOOL)publicPerformAction:(nonnull NSString *)identifier
              withArguments:(nonnull NSDictionary<NSString *, NSObject *> *)args {
    if (identifier == nil || args == nil) {
        [BALogger publicForDomain:LOGGER_DOMAIN message:@"Cannot manually perform action: invalid arguments"];
        return NO;
    }

    if ([identifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        [BALogger debugForDomain:LOGGER_DOMAIN
                         message:@"Trying to manually perform an action from an empty identifier"];
        return NO;
    }

    identifier = [identifier lowercaseString];

    if ([identifier hasPrefix:kBAActionsReservedIdentifierPrefix]) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Trying to manually perform a reserved batch action"];
        return NO;
    }

    return [self performAction:identifier withArgs:args andSource:[BatchManualUserActionSource new]];
}

#pragma mark Builtin actions

- (BatchUserAction *)deeplinkAction {
    return [BatchUserAction
        userActionWithIdentifier:[kBAActionsReservedIdentifierPrefix stringByAppendingString:@"deeplink"]
                     actionBlock:^(NSString *_Nonnull identifier,
                                   NSDictionary<NSString *, NSObject *> *_Nonnull arguments,
                                   id<BatchUserActionSource> _Nullable source) {
                       NSObject *linkArgument = [arguments objectForKey:@"l"];
                       NSObject *inappDeeplinkArgument = [arguments objectForKey:@"li"];
                       if ([linkArgument isKindOfClass:[NSString class]]) {
                           BOOL openInApp = false;
                           if ([inappDeeplinkArgument isKindOfClass:[NSNumber class]]) {
                               openInApp = [(NSNumber *)inappDeeplinkArgument boolValue];
                           }
                           [[BACoreCenter instance] openDeeplink:(NSString *)linkArgument inApp:openInApp];
                       } else {
                           [BALogger publicForDomain:LOGGER_DOMAIN
                                             message:@"An internal error occured while trying to perform a deeplink "
                                                     @"action. (Code 1)"];
                       }
                     }];
}

- (BatchUserAction *)refreshLocalCampaignsAction {
    return [BatchUserAction
        userActionWithIdentifier:[kBAActionsReservedIdentifierPrefix stringByAppendingString:@"refresh_lc"]
                     actionBlock:^(NSString *_Nonnull identifier,
                                   NSDictionary<NSString *, NSObject *> *_Nonnull arguments,
                                   id<BatchUserActionSource> _Nullable source) {
                       [[BALocalCampaignsCenter instance] refreshCampaignsFromServer];
                     }];
}

- (BatchUserAction *)requestNotificationsAction {
    return [BatchUserAction userActionWithIdentifier:[kBAActionsReservedIdentifierPrefix
                                                         stringByAppendingString:@"ios_request_notifications"]
                                         actionBlock:^(NSString *_Nonnull identifier,
                                                       NSDictionary<NSString *, NSObject *> *_Nonnull arguments,
                                                       id<BatchUserActionSource> _Nullable source) {
                                           [BatchPush requestNotificationAuthorization];
                                         }];
}

- (BatchUserAction *)redirectSettingsAction {
    return [BatchUserAction
        userActionWithIdentifier:[kBAActionsReservedIdentifierPrefix stringByAppendingString:@"ios_redirect_settings"]
                     actionBlock:^(NSString *_Nonnull identifier,
                                   NSDictionary<NSString *, NSObject *> *_Nonnull arguments,
                                   id<BatchUserActionSource> _Nullable source) {
                       [[BAPushCenter instance] openSystemNotificationSettings];
                     }];
}

// Smart optin action checks if the user has already been asked for notifications
// If not, it calls registerForRemoteNotifications
// Otherwise, it goes to the settings
// On iOS 9, it just goes to the settings
- (BatchUserAction *)smartReoptinAction {
    return [BatchUserAction
        userActionWithIdentifier:[kBAActionsReservedIdentifierPrefix stringByAppendingString:@"ios_smart_reoptin"]
                     actionBlock:^(NSString *_Nonnull identifier,
                                   NSDictionary<NSString *, NSObject *> *_Nonnull arguments,
                                   id<BatchUserActionSource> _Nullable source) {
                       [self doSmartReoptin];
                     }];
}

// Action that asks user for tracking consent
// If the consent has already been asked for, open the App's consent settings
// If the user can't do anything about it, this does nothing
// On iOS 13 and earlier it does nothing
- (BatchUserAction *)trackingConsentAction {
    return [BatchUserAction
        userActionWithIdentifier:[kBAActionsReservedIdentifierPrefix stringByAppendingString:@"ios_tracking_consent"]
                     actionBlock:^(NSString *_Nonnull identifier, NSDictionary<NSString *, id> *_Nonnull arguments,
                                   id<BatchUserActionSource> _Nullable source) {
                       [self askForTrackingConsent];
                     }];
}

/**
 * Group action that executes multiple
 */
- (BatchUserAction *)groupAction {
    return [BatchUserAction userActionWithIdentifier:kBAActionGroupName
                                         actionBlock:^(NSString *_Nonnull identifier,
                                                       NSDictionary<NSString *, NSObject *> *_Nonnull arguments,
                                                       id<BatchUserActionSource> _Nullable source) {
                                           [self performGroupAction:arguments source:source];
                                         }];
}

/**
 * Action that copies text to clipboard
 */
- (BatchUserAction *)clipboardAction {
    return [BatchUserAction
        userActionWithIdentifier:[kBAActionsReservedIdentifierPrefix stringByAppendingString:@"clipboard"]
                     actionBlock:^(NSString *_Nonnull identifier,
                                   NSDictionary<NSString *, NSObject *> *_Nonnull arguments,
                                   id<BatchUserActionSource> _Nullable source) {
                       NSObject *text = [arguments objectForKey:@"t"];
                       if ([text isKindOfClass:[NSString class]]) {
                           self->_pasteboard.string = (NSString *)text;
                       } else {
                           [BALogger publicForDomain:LOGGER_DOMAIN
                                             message:@"An internal error occured while trying to perform a clipboard "
                                                     @"action. (Code 1)"];
                       }
                     }];
}

/**
 * Action that triggers the rating prompt
 */
- (BatchUserAction *)ratingAction {
#if TARGET_OS_VISION
    // There is no way (yet) to request a rating on visionOS
    return nil;
#else
    return
        [BatchUserAction userActionWithIdentifier:[kBAActionsReservedIdentifierPrefix stringByAppendingString:@"rating"]
                                      actionBlock:^(NSString *_Nonnull identifier,
                                                    NSDictionary<NSString *, NSObject *> *_Nonnull arguments,
                                                    id<BatchUserActionSource> _Nullable source) {
                                        if (@available(iOS 14.0, *)) {
                                            UIWindowScene *activeScene = [BAWindowHelper activeScene];
                                            if (activeScene != nil) {
                                                [SKStoreReviewController requestReviewInScene:activeScene];
                                                return;
                                            }
                                        }
                                        [SKStoreReviewController requestReview];
                                      }];
#endif
}

- (void)performGroupAction:(nonnull NSDictionary<NSString *, NSObject *> *)rawArguments
                    source:(nullable id<BatchUserActionSource>)source {
    /*
     * Arguments look like:
     * {
     *   actions: [
     *     ["batch.deeplink", {"l": "https://google.com"}],
     *     ["batch.user.tag", {"add": "..."}]
     *   ]
     * }
     */
    id rawActions = rawArguments[@"actions"];
    if (![rawActions isKindOfClass:[NSArray class]]) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not parse group action, 'actions' is not an array"];
        return;
    }

    NSUInteger executedActions = 0;
    for (NSArray *rawAction in (NSArray *)rawActions) {
        if (![rawAction isKindOfClass:[NSArray class]]) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Could not parse group action item, item is not an array"];
            continue;
        }

        if ([rawAction count] == 0) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Could not parse group action item, invalid array size"];
            continue;
        }

        NSString *identifier = rawAction[0];
        if (![identifier isKindOfClass:[NSString class]]) {
            [BALogger debugForDomain:LOGGER_DOMAIN
                             message:@"Could not parse group action item, identifier must be a string"];
            continue;
        }

        if ([kBAActionGroupName caseInsensitiveCompare:identifier] == NSOrderedSame) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Group does not allow recursion"];
            continue;
        }

        NSDictionary *args;
        if ([rawAction count] > 1) {
            args = rawAction[1];
            if (![args isKindOfClass:[NSDictionary class]]) {
                [BALogger debugForDomain:LOGGER_DOMAIN
                                 message:@"Could not parse group action item, arguments must be an object if present"];
                continue;
            }
        } else {
            args = @{};
        }

        [self performAction:identifier withArgs:args andSource:source];
        executedActions++;
        if (executedActions >= 10) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Group action cannot execure more than 10 actions."];
            break;
        }
    }
}

- (void)doSmartReoptin {
    [[UNUserNotificationCenter currentNotificationCenter]
        getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings) {
          if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined ||
              settings.authorizationStatus == UNAuthorizationStatusProvisional) {
              [BatchPush requestNotificationAuthorization];
          } else if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
              [[BAPushCenter instance] openSystemNotificationSettings];
          }
        }];
}

- (void)askForTrackingConsent {
#if !TARGET_OS_MACCATALYST
    if (@available(iOS 14.0, *)) {
        switch (ATTrackingManager.trackingAuthorizationStatus) {
            case ATTrackingManagerAuthorizationStatusDenied: {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if (url != nil) {
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                }
            } break;
            case ATTrackingManagerAuthorizationStatusNotDetermined:
                [ATTrackingManager
                    requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status){
                    }];
                break;
            default:
                break;
        }
    }
#endif
}

@end
