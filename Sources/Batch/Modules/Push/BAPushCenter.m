//
//  BAPushCenter.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAPushCenter.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BAParameter.h>
#import <Batch/BAInjection.h>

#import <Batch/BAPushTokenService.h>
#import <Batch/BAQueryWebserviceClient.h>
#import <Batch/BAWebserviceClientExecutor.h>

#import <Batch/BAPushPayload.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BALogger.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAEventDispatcherCenter.h>

#import <Batch/BAOSHelper.h>
#import "NSObject+BASwizzled.h"
#import <Batch/BAStringUtils.h>

#import <Batch/BAPushSystemHelperProtocol.h>
#import <Batch/BANotificationAuthorization.h>
#import <Batch/BAApplicationLifecycle.h>

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

NSString * const kBATPushOpenedNotificationOriginatesFromUNResponseKey = @"is_un_response";

NSString * const kBATPushOpenedNotificationOriginatesFromAppDelegate = @"is_from_appdelegate";

// Internal methods and variables.
@interface BAPushCenter()

@property BatchNotificationType notificationType;

@end


@implementation BAPushCenter

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:[BAPushCenter class] selector:@selector(applicationDidFinishLaunchingNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}


#pragma mark -
#pragma mark Public methods

// Instance management.
+ (BAPushCenter *)instance
{
    static BAPushCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BAPushCenter alloc] init];
    });
    
	return sharedInstance;
}   

// Batch is about to start
+ (void)batchWillStart
{
    BAPushCenter *instance = [BAPushCenter instance];
    
    [instance registerProxy];
    // Send the stored start push notification if there is one
    NSDictionary *userInfo = [BAPushCenter instance].startPushUserInfo;
    if (userInfo)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // Sent for compatibility
        [[NSNotificationCenter defaultCenter] postNotificationName:BatchPushReceivedNotification object:nil userInfo:userInfo];
#pragma clang diagnostic pop
        
        NSDictionary *openUserInfo = @{ kBATPushOpenedNotificationOriginatesFromUNResponseKey: @(false),
                                        kBATPushOpenedNotificationOriginatesFromAppDelegate: @(true),
                                        BatchPushOpenedNotificationPayloadKey: userInfo
        };
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BatchPushOpenedNotification object:nil userInfo:openUserInfo];
        
        instance.startPushUserInfo = nil;
    }
}

// Change the used remote notification types.
+ (void)setRemoteNotificationTypes:(BatchNotificationType)type
{
    [[BAPushCenter instance] setRemoteNotificationTypes:type];
}

// Clear the application's badge on the homescreen.
+ (void)clearBadge
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

// Clear the app's notifications in the notification center. Also clears your badge.
+ (void)dismissNotifications
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

+ (void)enableAutomaticDeeplinkHandling:(BOOL)handleDeeplinks
{
    [[BAPushCenter instance] setHandleDeeplinks:handleDeeplinks];
}

+ (NSString *)deeplinkFromUserInfo:(NSDictionary *)userInfo
{
    // We could use BAPushMessage here, but it's really doing WAY too much work for what we want
    id deeplink = [[userInfo objectForKey:kWebserviceKeyPushBatchData] objectForKey:kWebserviceKeyPushDeeplink];
    
    // Sanity check, so we don't expose our (potential) madness to the developers
    if ([deeplink isKindOfClass:[NSString class]])
    {
        return deeplink;
    }
    return nil;
}

+ (void)disableAutomaticIntegration
{
    [[BAPushCenter instance] disableAutomaticIntegration];
}

+ (void)handleDeviceToken:(NSData*)token
{
    [[BAPushCenter instance] handleDeviceToken:token];
}

+ (BOOL)isBatchPush:(NSDictionary*)userInfo
{
    return [[BAPushCenter instance] isBatchPush:userInfo];
}

+ (void)handleNotification:(NSDictionary*)userInfo
{
    [[BAPushCenter instance] handleNotification:userInfo];
}

+ (void)handleNotification:(NSDictionary*)userInfo actionIdentifier:(NSString*)identifier
{
    [[BAPushCenter instance] handleNotification:userInfo actionIdentifier:identifier];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (void)handleRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [[BAPushCenter instance] handleRegisterUserNotificationSettings:notificationSettings];
}
#pragma clang diagnostic pop

#pragma mark -
#pragma mark Private methods

+ (void)applicationDidFinishLaunchingNotification:(NSNotification *)notification
{
    if ([BANullHelper isNull:notification])
    {
        return;
    }
    
    BOOL sdkInitialized = BACoreCenter.instance.status.isInitialized;
    
    // If Batch has been setup, warn if a UNUserNotificationCenterDelegate has not been set
    if (sdkInitialized) {
        if (![BAApplicationLifecycle applicationImplementsUNDelegate]) {
            [BALogger publicForDomain:@"Push"
                              message:@"⚠️ A UNUserNotificationCenterDelegate has not been set in 'application:didFinishLaunchingWithOptions:'. This can cause erratic behaviour with opens, mobile landings and other features. Please use BatchUNUserNotificationCenterDelegate or implement your own."];
            if (@available(iOS 13.0, *)) {
                if ([BAApplicationLifecycle applicationUsesUIScene]) {
                    [BALogger publicForDomain:@"Push"
                                      message:@"⚠️ App is using UIScene without a UNUserNotificationCenterDelegate: Direct Opens, Mobile Landings, Deeplinks will not work."];
                }
            }
        }
    }
    
    if (![BANullHelper isDictionaryEmpty:[notification userInfo]])
    {
        // UIApplicationLaunchOptionsRemoteNotificationKey is useless if you:
        //  - Iplement UNUserNotificationCenterDelegate. If the user doesn't implement Batch in their implementation, we'll fail, but that's to be expected
        //  - Implement fetchCompletionHandler on iOS 8/9/10. On iOS 8/9/10.1+, the fetchCompletionHandler variant will be called. iOS 10 will call the normal one, but only if both are implemented
        
        if ([[UNUserNotificationCenter currentNotificationCenter] delegate] != nil) {
            [BALogger debugForDomain:@"Push" message:@"Skipping initial push since we're on iOS 10 and the user has a UNUserNotificationCenterDelegate set"];
            return; // don't remove this
        }
        
        if ([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)])
        {
            [BALogger debugForDomain:@"Push" message:@"Skipping initial push since the delegate implments application:didReceiveRemoteNotification:fetchCompletionHandler:"];
        }
        else
        {
            [[BAPushCenter instance] parseNotification:[[notification userInfo] objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] fetchCompletionHandler:nil originatesFromUNDelegateResponse:NO];
        }
        
        // Might seem redundent, but we store it so we can broadcast this for Cordova on start
        // If the SDK wasn't initialized, 'parseNotification' won't do anything
        // and Batch will not be ready by the time "application:didReceiveRemoteNotification:fetchCompletionHandler:" is called
        if (!sdkInitialized) {
            [BAPushCenter instance].startPushUserInfo = [[notification userInfo] objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        }
    }
}


#pragma mark -
#pragma mark Instance methods

- (instancetype)init
{
    self = [super init];
    
    if ([BANullHelper isNull:self])
    {
        return self;
    }
    
    // Default is all.
    _notificationType = BatchNotificationTypeAlert | BatchNotificationTypeSound | BatchNotificationTypeBadge;
    
    _handleDeeplinks = YES;
    
    _supportsAppNotificationSettings = NO;
    
    _startPushUserInfo = nil;
    
    _shouldSwizzle = YES;
    
    return self;
}

- (void)registerProxy
{
    if (!_shouldSwizzle)
    {
        [BALogger debugForDomain:NSStringFromClass([self class]) message:@"Swizzling disabled by user. Not registering app delegate 'proxy'"];
        return;
    }
    
    @try
    {
        // Don't swizzle twice
        if (self.swizzled)
        {
            [[NSException exceptionWithName:@"Application delegate already registered" reason:@"Application delegate already set" userInfo:nil] raise];
        }
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
        // Load our UIResponder category by using a class defined in the same file
        id tmp = [BASwizzledObject new];
#pragma clang diagnostic pop
        
        // Bind self to be a UIApplicationDelegate.
        id responder = [UIResponder swizzleForDelegate:self];
        if ([BANullHelper isNull:responder])
        {
            [BALogger errorForDomain:ERROR_DOMAIN message:@"No Application delegate found: Application delegate is nil"];
            return;
        }
        
        [self setSwizzled:YES];
        
        [BALogger debugForDomain:NSStringFromClass([self class]) message:@"IS IN PRODUCTION: %@",[[BACoreCenter instance].status isLikeProduction]?@"YES":@"NO"];
    }
    @catch (NSException *exception)
    {
        [BALogger errorForDomain:ERROR_DOMAIN message:@"%@",exception];
    }
}

- (void)setRemoteNotificationTypes:(BatchNotificationType)type
{
    [self setNotificationType:type];
}

- (void)requestNotificationAuthorization
{
    id<BAPushSystemHelperProtocol> pushSystemHelper = [BAInjection injectProtocol:@protocol(BAPushSystemHelperProtocol)];
    [pushSystemHelper registerForRemoteNotificationsTypes:[self notificationType] providesNotificationSettings:self.supportsAppNotificationSettings];

    [self setShouldAutomaticallyRetreivePushToken:YES];
}

- (void)requestProvisionalNotificationAuthorization
{
    id<BAPushSystemHelperProtocol> pushSystemHelper = [BAInjection injectProtocol:@protocol(BAPushSystemHelperProtocol)];
    [pushSystemHelper registerForProvisionalNotifications:[self notificationType] providesNotificationSettings:self.supportsAppNotificationSettings];
}

- (void)openSystemNotificationSettings
{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (url != nil) {
        [BACoreCenter openURLWithUIApplication:url];
    }
}

- (void)refreshToken
{
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

+ (void)setNotificationsCategories:(NSSet *)categories
{
    id<BAPushSystemHelperProtocol> pushSystemHelper = [BAInjection injectProtocol:@protocol(BAPushSystemHelperProtocol)];
    [pushSystemHelper registerCategories:categories];
}


- (void)registerToken:(NSData *)token
{
    NSString *stringToken = [BAStringUtils hexStringValueForData:token];
    
    NSString *storedToken = [BAParameter objectForKey:kParametersPushTokenKey fallback:@""];
    NSNumber *isProduction = @([[BACoreCenter instance].status isLikeProduction]);
    [BAParameter setValue:isProduction forKey:kParametersPushTokenIsProductionKey saved:YES];
    
    
    if (![BANullHelper isStringEmpty:stringToken])
    {
        [BALogger publicForDomain:nil message:@"Push token (Apple Push %@): %@",[isProduction boolValue] ? @"Production" : @"Sandbox/Development" , stringToken];
    }
 
    if (![BANullHelper isStringEmpty:stringToken] && ![storedToken isEqualToString:stringToken])
    {
        [BAParameter setValue:stringToken forKey:kParametersPushTokenKey saved:YES];
        
        BAPushTokenServiceDatasource *service = [[BAPushTokenServiceDatasource alloc] initWithToken:stringToken usesProductionEnvironment:[isProduction boolValue]];
        
        BAQueryWebserviceClient *ws = [[BAQueryWebserviceClient alloc] initWithDatasource:service
                                                                                 delegate:nil];
        
        [BAWebserviceClientExecutor.sharedInstance addClient:ws];
    }
    else if ([BANullHelper isStringEmpty:stringToken])
    {
        [BALogger errorForDomain:@"Push" message:@"Error while encoding token to string"];
    }
}

- (void)parseNotification:(NSDictionary *)userInfo
   fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
originatesFromUNDelegateResponse:(BOOL)originatesFromUNDelegateResponse
{
    if ([BANullHelper isDictionaryEmpty:userInfo]) {
        return;
    }
    
    if ([[BAOptOut instance] isOptedOut]) {
        // Do not handle notification when opted out
        [BALogger debugForDomain:@"Push" message:@"Not handling notification: opted-out"];
        return;
    }
    
    BOOL isSDKInitialized = [BACoreCenter.instance.status isInitialized];
    UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
    
    // A background push is a push with content-available:1 that woke up the app and is being handled by the SDK
    // A push that comes from UNUserNotificationCenterDeleagte originates from a user action, so no need to get smart here
    BOOL isBackgroundPush = !originatesFromUNDelegateResponse && appState == UIApplicationStateBackground;
    
    // Try to guess if the user explicitly opened the notification after it was presented to them.
    // See BAApplicationLifecycle.h for what the different app and scene states are in various scenarios.
    BOOL userOpenedNotification;
    if (originatesFromUNDelegateResponse) {
        // If we come from UNUserNotificationCenterDelegate's didReceiveResponse, it's guaranteed to be an explicit open
        userOpenedNotification = true;
    } else if ([BAApplicationLifecycle applicationImplementsUNDelegate]) {
        // Notification didn't come from UNUserNotificationCenterDelegate, but the app implements it.
        // This must not be a direct open
        userOpenedNotification = false;
    } else {
        // Legacy behaviour, unsupported. We're trying to determine what the user did according to the app's state
        // BAApplicationLifecycle.h will help you here
        // Push users to implement UNUserNotificationCenterDelegate.
        if ([BAApplicationLifecycle applicationUsesUIScene]) {
            // Legacy callbacks are not supported with UIScene. Therefore, it means that we're in a background refresh situation
            userOpenedNotification = false;
            isBackgroundPush = true;
        } else {
            // Without UIScene, the app is in the "inactive" state when being opened from a push notification, cold or warm.
            // Background means background fetch, Active means that the app was on screen
            // If we get a push while the app is on screen, we do NOT handle it (no open, no landing, no deeplink)
            userOpenedNotification = appState == UIApplicationStateInactive;
        }
    }

    [BALogger debugForDomain:@"Push" message:@"Handling a push notification. isSDKInitialized=%d, userOpenedNotification=%d, isBackground=%d, Application state=%ld", isSDKInitialized, userOpenedNotification, isBackgroundPush, (long)appState];
    
    // Don't broadcast if batch hasn't been started at least once. This will also prevent the didFinishLaunchingWithOptions notification payload to be broadcasted, but Batch will save it and broadcast it on start.
    // iOS 13 Change: Broadcast if Batch has been started _once_ (rather than if it is currently started). This hotfix is needed due to
    // iOS 13 changing the callback order. Batch used to be started by UIApplicationWillEnterForegroundNotification
    // before this method got called, but it's not the case anymore.
    // We also now check if the push comes from background refresh: this used to be blocked by batch being stopped, but we now need to explicitly make that check
    //
    // This is deprecated and maintained for compatibility. BatchPushOpenedNotification should be much more accurate.
    if (isSDKInitialized && !isBackgroundPush) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[NSNotificationCenter defaultCenter] postNotificationName:BatchPushReceivedNotification object:nil userInfo:userInfo];
#pragma clang diagnostic pop
    }
    
    // Starting with 1.16, an open event is fired when we're almost sure that the user opened the notification
    if (isSDKInitialized && userOpenedNotification) {
        NSDictionary *openUserInfo = @{ kBATPushOpenedNotificationOriginatesFromUNResponseKey: @(originatesFromUNDelegateResponse),
                                        kBATPushOpenedNotificationOriginatesFromAppDelegate: @(false),
                                        BatchPushOpenedNotificationPayloadKey: userInfo
        };
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BatchPushOpenedNotification object:nil userInfo:openUserInfo];
    }
    
    // Extract Batch data
    BAPushPayload *message = [[BAPushPayload alloc] initWithUserInfo:userInfo];
    
    if (message == nil) {
        [BALogger debugForDomain:@"Push" message:@"Push is not a Batch push"];
        return;
    }
    
    if (userOpenedNotification) {
        [BALogger publicForDomain:@"Push" message:@"App was opened from a Batch push"];
        
        NSMutableDictionary *eventParameters = [NSMutableDictionary dictionaryWithDictionary:[message openEventData]];
        // "silent" has been deprecated in 1.16
        [eventParameters setObject:@(0) forKey:@"silent"];
        [BATrackerCenter trackPrivateEvent:@"_OPEN_PUSH" parameters:eventParameters];
        
        id<BatchEventDispatcherPayload> payload = [[BAPushEventPayload alloc] initWithUserInfo:userInfo];
        if (payload != nil) {
            [[BAInjection injectClass:BAEventDispatcherCenter.class] dispatchEventWithType:BatchEventDispatcherTypeNotificationOpen payload:payload];
        }
        
        // Mobile landings are handled by BAMessagingCenter, which listens to BatchPushOpenedNotification
    } else {
        [BALogger publicForDomain:@"Push" message:@"App triggered a remote background fetch from a Batch push, or was in foreground. Not handling it."];
    }
}

- (void)internalHandleNotification:(NSDictionary *)userInfo actionIdentifier:(NSString*)identifier
{
    // Build the received message.
    BAPushPayload *message = [[BAPushPayload alloc] initWithUserInfo:userInfo];
    
    if ([BANullHelper isNull:message])
    {
        return;
    }
    
    NSMutableDictionary *eventParameters = [NSMutableDictionary dictionaryWithDictionary:[message openEventData]];
    [eventParameters setObject:@([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) forKey:@"silent"];
    [eventParameters setObject:identifier forKey:@"actionId"];
    
    [BALogger publicForDomain:@"Push" message:@"App was opened from a notification action sent by a Batch push"];
    
    // Track open from push.
    [BATrackerCenter trackPrivateEvent:@"_PUSH_ACTION" parameters:eventParameters];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)internalHandleRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    BANotificationAuthorization *notifAuth = [BACoreCenter instance].status.notificationAuthorization;
    BOOL alertEnabled = (notificationSettings.types | UIUserNotificationTypeAlert) > 0;
    if (alertEnabled && [BANotificationAuthorization applicationSettings] == BatchPushNotificationSettingStatusUndefined)
    {
        [notifAuth setApplicationSettings:BatchPushNotificationSettingStatusEnabled skipServerEvent:true];
    }
    [notifAuth settingsMayHaveChanged];
    
    if (![[BAPushCenter instance] shouldAutomaticallyRetreivePushToken])
    {
        return;
    }
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}
#pragma clang diagnostic pop

#pragma mark -
#pragma mark Manual integration methods

- (BOOL)passesManualIntegrationPreflightChecks
{
    if ([[BAOptOut instance] isOptedOut])
    {
        [BALogger debugForDomain:@"Push" message:@"Ignoring manual integration method: Batch is opted-out from."];
        return false;
    }
    
    if (_swizzled || _shouldSwizzle)
    {
        [BALogger publicForDomain:@"Push" message:@"disableAutomaticIntegration was not called (or called after Batch has been started), so this call will be ignored."];
        return false;
    }
    
    if (![BACoreCenter.instance.status isRunning])
    {
        [BALogger debugForDomain:@"Push" message:@"Ignoring manual integration method: Batch hasn't been started"];
        return false;
    }
    
    return true;
}

- (void)disableAutomaticIntegration
{
    if (_swizzled)
    {
        [BALogger publicForDomain:nil message:@"disableAutomaticIntegration was called too late and will be ignored. Please call this before you call Batch's start method."];
        return;
    }
    
    _shouldSwizzle = NO;
}

- (void)handleDeviceToken:(NSData*)token
{
    if ([self passesManualIntegrationPreflightChecks])
    {
        if (![token isKindOfClass:[NSData class]] || [token length] == 0)
        {
            [BALogger publicForDomain:@"Push" message:@"Cannot register a device token that's null or empty. Ignoring."];
            return;
        }
        
        [self registerToken:token];
    }
}

- (BOOL)isBatchPush:(NSDictionary*)userInfo
{
    if ([BANullHelper isDictionaryEmpty:userInfo])
    {
        return FALSE;
    }
    
    NSDictionary *parameters = [userInfo objectForKey:kWebserviceKeyPushBatchData];
    if ([BANullHelper isDictionaryEmpty:parameters])
    {
        return FALSE;
    }
    return TRUE;
}

- (void)handleNotification:(NSDictionary*)userInfo
{
    if ([self passesManualIntegrationPreflightChecks])
    {
        if (![userInfo isKindOfClass:[NSDictionary class]] || [userInfo count] == 0)
        {
            [BALogger publicForDomain:@"Push" message:@"Cannot process a push payload that's null or empty. Ignoring."];
            return;
        }

        [self parseNotification:userInfo fetchCompletionHandler:nil originatesFromUNDelegateResponse:NO];
    }
}

- (void)handleNotification:(NSDictionary*)userInfo actionIdentifier:(NSString*)identifier
{
    if ([self passesManualIntegrationPreflightChecks])
    {
        if (![userInfo isKindOfClass:[NSDictionary class]] || [userInfo count] == 0)
        {
            [BALogger publicForDomain:@"Push" message:@"Cannot process a push payload that's null or empty. Ignoring."];
            return;
        }
    
        if (![identifier isKindOfClass:[NSString class]] || [identifier length] == 0)
        {
            [BALogger publicForDomain:@"Push" message:@"Cannot process a push action identifier that's null or empty. Ignoring."];
            return;
        }
    
        [self internalHandleNotification:userInfo actionIdentifier:identifier];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)handleRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    if ([self passesManualIntegrationPreflightChecks])
    {
        [self internalHandleRegisterUserNotificationSettings:notificationSettings];
    }
}
#pragma clang diagnostic pop

#pragma mark -
#pragma mark UNUserNotificationCenterDelegate

+ (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification willShowSystemForegroundAlert:(BOOL)willShowSystemForegroundAlert NS_AVAILABLE_IOS(10_0);
{
    if ([[BAOptOut instance] isOptedOut])
    {
        [BALogger debugForDomain:@"Push" message:@"Ignoring UNUserNotificationCenterDelegate method: Batch is opted-out from."];
        return;
    }
    
    // If an alert is shown, we'll end up in didReceiveNotificationResponse
    // If not, make Batch believe that we're coming from didReceiveNotificationResponse so that the any open related functionality is handled
    if (!willShowSystemForegroundAlert)
    {
        [[BAPushCenter instance] parseNotification:notification.request.content.userInfo fetchCompletionHandler:nil originatesFromUNDelegateResponse:YES];
    }
}

+ (void)handleUserNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response
{
    if ([[BAOptOut instance] isOptedOut])
    {
        [BALogger debugForDomain:@"Push" message:@"Ignoring UNUserNotificationCenterDelegate method: Batch is opted-out from."];
        return;
    }
    
    if ([UNNotificationDefaultActionIdentifier isEqualToString:response.actionIdentifier])
    {
        [[BAPushCenter instance] parseNotification:response.notification.request.content.userInfo fetchCompletionHandler:nil originatesFromUNDelegateResponse:YES];
    }
    else if (![UNNotificationDismissActionIdentifier isEqualToString:response.actionIdentifier])
    {
        [[BAPushCenter instance] internalHandleNotification:response.notification.request.content.userInfo actionIdentifier:response.actionIdentifier];
    }
}

#pragma mark -
#pragma mark UIApplicationDelegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self registerToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSDictionary *params;
    if (error)
    {
        params = @{@"localizedDescription": error.localizedDescription};
    }
    else
    {
        params = @{@"localizedDescription": @"<unknown error>", @"unknown": @(YES)};
    }
    
    [BATrackerCenter trackPrivateEvent:@"_PUSH_REGISTER_FAIL" parameters:params];
    [BALogger publicForDomain:nil message:@"Fail to register push token (%@): %@.",[[BACoreCenter instance].status isLikeProduction]?@"Production":@"Development", error != nil ? error.localizedDescription : @"Unknown error"];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
#pragma clang diagnostic pop
{
    [self parseNotification:userInfo fetchCompletionHandler:nil originatesFromUNDelegateResponse:NO];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    [self parseNotification:userInfo fetchCompletionHandler:completionHandler originatesFromUNDelegateResponse:NO];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings NS_AVAILABLE_IOS(8_0)
#pragma clang diagnostic pop
{
    [self internalHandleRegisterUserNotificationSettings:notificationSettings];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler
#pragma clang diagnostic pop
{
    [self internalHandleNotification:userInfo actionIdentifier:identifier];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler
#pragma clang diagnostic pop
{
    [self internalHandleNotification:userInfo actionIdentifier:identifier];
}

#pragma clang diagnostic pop

@end
