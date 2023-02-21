//
//  BACoreCenter.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/Batch.h>
#import <Batch/BatchPush.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BAPushCenter.h>
#import <Batch/BAThreading.h>
#import <Batch/BATrackerCenter.h>

#import <Batch/BABundleInfo.h>

#import <Batch/BAApplicationLifecycle.h>

#import <Batch/BAStartService.h>

#import <Batch/BAErrorHelper.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAParameter.h>

#import <Batch/BAPropertiesCenter.h>
#import <Batch/BAReachabilityHelper.h>

#import <Batch/BAStringUtils.h>

#import <Batch/BAQueryWebserviceClient.h>
#import <Batch/BAWebserviceClientExecutor.h>

#import <SafariServices/SafariServices.h>
#import <UIKit/UIKit.h>

#import <Batch/BAWindowHelper.h>

#import <Batch/BAEventDispatcherCenter.h>
#import <Batch/BAInjection.h>
#import <Batch/BAApplicationLifecycle.h>

#define LOGGER_DOMAIN @"Core"

// Internal methods and parameters.
@interface BACoreCenter () <BALoggerDelegateSource>

// Activate the whole Batch system.
- (void)excecuteStartWithAPIKey:(NSString *)key;

// Test if Batch is running in development mode.
- (BOOL)executeIsDevelopmentMode;

// Resume any activity of BA.
- (void)stop;

// Version migration.
- (void)portDataFromVersion:(NSString *)version;

@end

@implementation BACoreCenter

#pragma mark -
#pragma mark Public methods

// Instance management.
+ (BACoreCenter *)instance {
    static BACoreCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BACoreCenter alloc] init];
    });

    return sharedInstance;
}

+ (NSString *)sdkVersion {
    return BASDKVersionNSString;
}

// Activate the whole Batch system.
+ (void)startWithAPIKey:(NSString *)key {
    [[BACoreCenter instance] excecuteStartWithAPIKey:key];
}

// Give the URL to Batch systems.
+ (BOOL)handleURL:(NSURL *)url {
    return NO;
}

// Test if Batch is running in development mode.
+ (BOOL)isRunningInDevelopmentMode {
    return [[BACoreCenter instance] executeIsDevelopmentMode];
}

+ (void)setUseIDFA:(BOOL)use {
    [[BACoreCenter instance] setUseIDFA:use];
}

+ (void)setUseAdvancedDeviceInformation:(BOOL)use {
    [[BACoreCenter instance] setUseAdvancedDeviceInformation:use];
}

- (void)openDeeplink:(NSString *)deeplink inApp:(BOOL)inApp {
    id<BatchDeeplinkDelegate> developerDelegate = [self.configuration deeplinkDelegate];

    if (developerDelegate != nil) {
        [BALogger debugForDomain:LOGGER_DOMAIN
                         message:@"Forwarding deeplink '%@' to developer implementation", deeplink];

        dispatch_async(dispatch_get_main_queue(), ^{
          [developerDelegate openBatchDeeplink:deeplink];
        });
    } else {
        NSURL *deeplinkURL = [NSURL URLWithString:deeplink];
        if (deeplinkURL != nil) {
            if ([self openUniversalLinkIfPossible:deeplinkURL]) {
                // We successfully opened universal link
                return;
            }
            if (!inApp || ![self openDeeplinkURLInAppIfPossible:deeplinkURL]) { // don't open in app OR tried to open in
                                                                                // app but failed
                // then open with UIApplication
                [BACoreCenter openURLWithUIApplication:deeplinkURL];
            }
        } else {
            [BALogger debugForDomain:LOGGER_DOMAIN
                             message:@"Tried to open deeplink '%@', but failed to convert it to a NSURL", deeplink];
        }
    }
}

#pragma mark -
#pragma mark Instance methods

- (instancetype)init {
    self = [super init];
    if (self == NULL) {
        return self;
    }

    // Create a brand new status.
    _status = [[BAStatus alloc] init];

    // Create a brand new configuration.
    _configuration = [[BAConfiguration alloc] init];

    // Make itself logger delegate source of BALogger
    [BALogger setLoggerDelegateSource:self];

    return self;
}

- (void)dealloc {
    // Unsubscribe to the application events.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Private methods

- (void)excecuteStartWithAPIKey:(NSString *)key {
    NSString *apiKey =
        [key stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];

    // Try to save the developper key.
    NSError *e = [self.configuration setDevelopperKey:apiKey];
    if (e != NULL) {
        [BALogger publicForDomain:nil message:@"%@", [[BAErrorHelper errorMissingAPIKey] localizedDescription]];
        return;
    }

    // Manage initialized status.
    e = [self.status initialization];
    if (e == nil) {
        NSString *currentSdkVersion = BACoreCenter.sdkVersion;

        // Versions management.
        NSString *storedVersion = [BAParameter objectForKey:kParametersSystemCurrentAppVersionKey
                                                   fallback:currentSdkVersion];
        if ([storedVersion isEqualToString:currentSdkVersion] == YES) {
            [BAParameter setValue:currentSdkVersion forKey:kParametersSystemCurrentAppVersionKey saved:YES];
        } else {
            // Reset local storage (next version).
            [self portDataFromVersion:storedVersion];

            [BAParameter setValue:storedVersion forKey:kParametersSystemPreviousAppVersionKey saved:YES];
            [BAParameter setValue:currentSdkVersion forKey:kParametersSystemCurrentAppVersionKey saved:YES];
        }

        // Reachability engine.
        [BAReachabilityHelper reachabilityForInternetConnection];

        // Subscribe to the application events.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stop)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stop)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(restart:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }

    [self restart:nil];
}

// Activate the whole Batch system.
- (void)restart:(NSNotification *)notification {
    BOOL isRestartingFromWillEnterForeground =
        notification != nil && [UIApplicationWillEnterForegroundNotification isEqualToString:notification.name];

    __block UIApplicationState appState;

    [BAThreading performBlockOnMainThread:^{
      appState = [[UIApplication sharedApplication] applicationState];
    }];

    // If we're in Background but coming from UIApplicationWillEnterForegroundNotification, it's not background refresh
    BOOL isPotentiallyInBackgroundRefresh =
        !isRestartingFromWillEnterForeground && appState == UIApplicationStateBackground;

    // In UIScene apps, we need skip the first start WS as we can't know if the app is in background refresh or if the
    // user really opened it thus, all starts are reported as silent. We need to sacrifice silent starts for UIScene
    // apps.
    BOOL shouldWaitBeforeSendingStart = false;

    // Here be dragons, we're handling UIScene
    if (@available(iOS 13.0, *)) {
        if ([BAApplicationLifecycle applicationUsesUIScene]) {
            // Check if it's a late call (like cordova, or just a bad integration), or if we're in
            // application:didFinishLaunchingWithOptions:-ish
            if (appState ==
                    UIApplicationStateBackground && // Late starts (StateActive or StateInactive) should force a start
                notification == nil                 // Only skip if we're not coming from a lifecycle notification
            ) {
                [BALogger debugForDomain:LOGGER_DOMAIN message:@"Waiting before tracking start"];
                shouldWaitBeforeSendingStart = true;
            }

            // Update isPotentiallyInBackgroundRefresh using UIScene if we're in an ambiguous state
            // This should not be ambiguous thanks to checking for UIApplicationWillEnterForegroundNotification
            // but lets make sure we're not misreporting silent starts
            if (isPotentiallyInBackgroundRefresh) {
                isPotentiallyInBackgroundRefresh = ![BAApplicationLifecycle hasASceneInForegroundState];
            }

            // Now, we need to handle restarting
            // Don't restart if we're getting UIApplicationWillEnterForegroundNotification on the first launch
            // This only happens in UIScene apps.
            // We can't rely on the UIScene state alone, as it's the same for first foreground and following ones on iOS
            // 13 (iOS 14 fixes this, but who knows what 15 will break). Note: this is a quick hack. We should rework
            // this, and start to the session manager. This solution looks like it might break at any moment, it already
            // changed between iOS 13 and 14.
            //
            // We DO need to send the start, as we skipped it the first time.
            if (isRestartingFromWillEnterForeground && appState == UIApplicationStateInactive) {
                [BALogger
                    debugForDomain:LOGGER_DOMAIN
                           message:
                               @"Batch was asked to restart after UIApplicationWillEnterForegroundNotification but it "
                               @"looks like this is the app's first launch. Tracking start, but skipping other work."];
                [self callStartWebserviceWithSilentStart:false];
                return;
            }
        }
    }

    // Change status.
    NSError *e = [self.status start];
    if (e != NULL) {
        // If we're started but coming from WillEnterForeground, this means that we need to call the start webservice
        // before returning. This can happen when background refresh wakes up the app: Batch will be started by the
        // developer, but will never shut down because the app has been started in the background. Therefore, we'll end
        // up in this code path and no start will be tracked until the user closes and reopens the app: this is
        // incorrect! However users might rely on some stuff in the background so we can't just shut down the SDK
        // (actually we probably can because it's probably broken if the app is running in the background with Batch
        // stopped, but I'm pretty sure I'd face unforseen consequences if I tweaked this, so I'm not changing it just
        // yet)
        if (!shouldWaitBeforeSendingStart && isRestartingFromWillEnterForeground) {
            [self callStartWebserviceWithSilentStart:false];
        }

        [BALogger publicForDomain:nil message:@"%@", [[BAErrorHelper errorAlreadyStarted] localizedDescription]];
        return;
    }

    // Create start webservice.
    if (!shouldWaitBeforeSendingStart) {
        [self callStartWebserviceWithSilentStart:isPotentiallyInBackgroundRefresh];
    }

    if ([BACoreCenter isRunningInDevelopmentMode]) {
        [BALogger publicForDomain:nil message:@"Batch started with a DEV API key"];
    }

    NSString *installID = [BatchUser installationID];
    if (![BANullHelper isStringEmpty:installID]) {
        [BALogger publicForDomain:nil message:@"Installation ID: %@", installID];
    }

    [self checkForIncompatibilities];
}

- (void)callStartWebserviceWithSilentStart:(BOOL)isSilentStart {
    // Start asynchronously on the next loop.
    // This hack (usually) gives BANotificationAuthorization enough time to resynchronize itself
    // with iOS if the permission changes in the background, which leads to a more accurate "nty" in the push
    // query that goes along the start service. Otherwise, the backend would not know about a change until a second
    // start comes later.
    //
    // We removed this for 1.19 as we thought it was unneeded but this lead to some timing issues: we've brought
    // it back as a temporary hotfix. We also believe it led to some unintended opt-in/out metrics change that we
    // started seeing with 1.19. We will fix this properly at a later date by fully deprecating "nty" once the backend
    // switches to the new events.
    dispatch_async(dispatch_get_main_queue(), ^{
      [BALogger debugForDomain:LOGGER_DOMAIN message:@"Sending start webservice. Silent: %d", isSilentStart];

      BAStartServiceDatasource *startService = [[BAStartServiceDatasource alloc] init];
      startService.isSilent = isSilentStart;
      BAQueryWebserviceClient *ws = [[BAQueryWebserviceClient alloc] initWithDatasource:startService delegate:nil];
      [BAWebserviceClientExecutor.sharedInstance addClient:ws];

      NSMutableDictionary *startParameters = [NSMutableDictionary dictionary];
      startParameters[@"silent"] = @(isSilentStart);

      NSDictionary *dispatcherParameters =
          [[BAInjection injectClass:BAEventDispatcherCenter.class] dispatchersAnalyticRepresentation];
      if ([dispatcherParameters count] > 0) {
          startParameters[@"dispatchers"] = dispatcherParameters;
      }
      [BATrackerCenter trackPrivateEvent:@"_START" parameters:startParameters];
    });
}

// Test if Batch is running in development mode.
- (BOOL)executeIsDevelopmentMode {
    if ([self.status isRunning] == NO) {
        return NO;
    }

    return [self.configuration developmentMode];
}

// Set if Batch can try to use IDFA (default = YES)
- (void)setUseIDFA:(BOOL)use {
    [self.configuration setUseIDFA:use];
}

- (void)setUseAdvancedDeviceInformation:(BOOL)use {
    [self.configuration setUseAdvancedDeviceInformation:use];
}

// Resume any activity of BA.
- (void)stop {
    // Change status.
    NSError *e = [self.status stop];
    if ([BANullHelper isNull:e] == NO) {
        [NSException exceptionWithName:ERROR_DOMAIN reason:@"Batch is already stopped, stoping again." userInfo:nil];
    }
}

// Version migration.
- (void)portDataFromVersion:(NSString *)version {
    [BALogger debugForDomain:ERROR_DOMAIN message:@"Porting data from SDK version: %@", version];
}

/**
 Open a deeplink url with a SFSafariViewController if available.

 @param deeplinkURL URL to open.
 @return YES if the URL was opened, NO if it couldn't.
 */
- (BOOL)openDeeplinkURLInAppIfPossible:(NSURL *)deeplinkURL {
    @try {
        UIViewController *targetVC = [[BAWindowHelper keyWindow] rootViewController];
        if (targetVC.presentedViewController != nil) {
            targetVC = targetVC.presentedViewController;
        }

        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:deeplinkURL];
        [targetVC presentViewController:safari animated:true completion:nil];

        [BALogger debugForDomain:LOGGER_DOMAIN
                         message:@"Opening deeplink '%@' using SFSafariViewController", deeplinkURL.absoluteString];

        return YES;

    } @catch (NSException *exception) {
        [BALogger debugForDomain:LOGGER_DOMAIN
                         message:@"Deeplink '%@' is not supported by SFSafariViewController. Falling back on "
                                 @"UIApplication.openURL",
                                 deeplinkURL.absoluteString];

        return NO;
    }
}

/**
 Open a deeplink url with -UIApplication.openURL if available.
 Handles compatibility

 @param URL URL to open.
 */
+ (void)openURLWithUIApplication:(NSURL *)URL {
    [BALogger debugForDomain:LOGGER_DOMAIN message:@"Opening deeplink '%@' using UIApplication", URL.absoluteString];

    UIApplication *sharedApplication = [UIApplication sharedApplication];
    [sharedApplication openURL:URL options:@{} completionHandler:nil];
}

/**
 Try to open an url as a universal link.
 Ensure the associated domains are declared and matching and then transfert the deeplink url to
 application:continueUserActivity:restorationHandler

 @param URL URL to transfer.
 @return YES if the URL was opened, NO if it couldn't.
 */
- (BOOL)openUniversalLinkIfPossible:(NSURL *)URL {
    // Ensure associated domains are declared
    NSArray *associatedDomains = [_configuration associatedDomains];
    if (associatedDomains == nil) {
        return NO;
    }

    // Checking the url match with the associated domains
    NSString *domain = [URL host];
    if (![associatedDomains containsObject:domain]) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Domain '%@' NOT found.", domain];
        return NO;
    }

    [BALogger debugForDomain:LOGGER_DOMAIN
                     message:@"Transferring universal link '%@' to UIApplication", URL.absoluteString];

    // Transferring url to application:continueUserActivity:restorationHandler or scene:continueUserActivity:
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    userActivity.webpageURL = URL;
    
    Boolean errorAlreadyLogged = false;
    
    if (@available(iOS 13.0, *)) {
        if ([BAApplicationLifecycle applicationUsesUIScene]) {
            UIScene* scene = [[UIApplication sharedApplication].connectedScenes allObjects].firstObject;
            id<UISceneDelegate> sceneDelegate = [scene delegate];
            if ([sceneDelegate respondsToSelector:@selector(scene:continueUserActivity:)]) {
                [sceneDelegate scene:scene continueUserActivity:userActivity];
                return YES;
            } else {
                [BALogger debugForDomain:LOGGER_DOMAIN
                                 message:@"It looks like scene:continueUserActivity: is not "
                                         @"implemented, did you correctly add it to your SceneDelegate?"];
                errorAlreadyLogged = true;
            }
        }
    }
    
    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    if ([appDelegate respondsToSelector:@selector(application:continueUserActivity:restorationHandler:)]) {
        [appDelegate application:[UIApplication sharedApplication]
            continueUserActivity:userActivity
              restorationHandler:nil];
        return YES;
    }
    if (!errorAlreadyLogged) {
        [BALogger debugForDomain:LOGGER_DOMAIN
                         message:@"It looks like application:continueUserActivity:restorationHandler is not "
                                 @"implemented, did you correctly add it to your AppDelegate?"];
    }

    return NO;
    
}

// Check for potential incompatibilities/misconfigurations, and warn the developer
- (void)checkForIncompatibilities {
    // This is tightly coupled with BAPushCenter, but unfortunately putting the "disableAutomaticIntegration" there
    // was a mistake. It should have been on Batch.
    if (NSClassFromString(@"FIRApp") != nil && [BAPushCenter instance].shouldSwizzle) {
        [BALogger publicForDomain:nil
                          message:@"⚠️ Firebase has been detected in your application, but Batch's manual "
                                  @"integration has NOT been enabled."];
        [BALogger publicForDomain:nil message:@"⚠️ This can cause issues with Batch's handling of notifications:"];
        [BALogger publicForDomain:nil message:@"⚠️ Direct Opens, Mobile Landings and Deeplinks might not work"];
        [BALogger publicForDomain:nil
                          message:@"⚠️ More info about the manual integration here: "
                                  @"https://batch.com/doc/ios/advanced/manual-integration.html"];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      if (![BABundleInfo isSharedGroupConfigured]) {
          [BALogger publicForDomain:nil
                            message:@"⚠️ The App Group '%@' hasn't been configured. See the documentation for more "
                                    @"info: https://doc.batch.com/ios/advanced/app-groups",
                                    [BABundleInfo sharedGroupId]];
      }
    });
}

- (id<BatchLoggerDelegate>)loggerDelegate {
    return self.configuration.loggerDelegate;
}

@end
