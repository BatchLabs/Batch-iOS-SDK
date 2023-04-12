//
//  BAApplicationLifecycle.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAApplicationLifecycle : NSObject

@property (class, readonly) BOOL applicationUsesSwiftUILifecycle;

@property (class, readonly) BOOL applicationUsesUIScene;

@property (class, readonly) BOOL applicationImplementsUNDelegate;

@property (class, readonly) BOOL isApplicationUIOnScreen;

// Does the app have a scene in Foreground Active or Foreground Inactive state?
@property (class, readonly) BOOL hasASceneInForegroundState;

// Is at least one scene in the requested state?
// Returns false if UIScene isn't enabled.
+ (BOOL)hasASceneInState:(UISceneActivationState)activationState API_AVAILABLE(ios(13.0));

@end

NS_ASSUME_NONNULL_END

// The following documents the various notifications and callbacks with their corresponding UIApplication and UIScene 

// ---------
// App is using UIScene on iOS 14
// ---------
//
// Note that "application:didReceiveRemoteNotification:"/"application:didReceiveRemoteNotification:fetchCompletionHandler:"
// are NEVER called for standard notifications (unless it's a background fetch). UNUserNotificationCenter NEEDS to be implemented.
//
// Cold open
// Lifecycle - application:didFinishLaunchingWithOptions: - State: Background - Scene: Unattached
// Lifecycle - UIApplicationDidFinishLaunchingNotification - State: Background - Scene: Unattached
// Lifecycle - UISceneWillConnectNotification - State: Background - Scene: Unattached
// Lifecycle - UISceneWillEnterForegroundNotification - State: Background - Scene: Unattached
// Lifecycle - UISceneDidActivateNotification - State: Background - Scene: Foreground Active
// Lifecycle - UIApplicationWillEnterForegroundNotification - State: Inactive - Scene: Foreground Active
// Lifecycle - UIApplicationDidBecomeActiveNotification - State: Active - Scene: Foreground Active
//
// it's a little bit different on iOS 13 (notice how the order and foreground state changes):
// Lifecycle - application:didFinishLaunchingWithOptions: - State: Background - Scene: Unattached
// Lifecycle - UIApplicationDidFinishLaunchingNotification - State: Background - Scene: Unattached
// Lifecycle - UISceneWillConnectNotification - State: Background - Scene: Unattached
// Lifecycle - UISceneWillEnterForegroundNotification - State: Background - Scene: Unattached
// Lifecycle - UIApplicationWillEnterForegroundNotification - State: Inactive - Scene: Foreground Inactive
// Lifecycle - UISceneDidActivateNotification - State: Inactive - Scene: Foreground Active
// Lifecycle - UIApplicationDidBecomeActiveNotification - State: Active - Scene: Foreground Active
//
// Notification (no bg refresh) warm open (app is in background)
// Lifecycle - userNotificationCenter:didReceive: - State: Inactive - Scene: Foreground Inactive
// Lifecycle - UISceneWillEnterForegroundNotification - State: Background - Scene: Background
// Lifecycle - UIApplicationWillEnterForegroundNotification - State: Background - Scene: Foreground Inactive
// Lifecycle - UISceneDidActivateNotification - State: Inactive - Scene: Foreground Active
// Lifecycle - UIApplicationDidBecomeActiveNotification - State: Active - Scene: Foreground Active
//
// Notification (no bg refresh) cold open (app is killed)
// Lifecycle - application:didFinishLaunchingWithOptions: - State: Background - Scene: Unattached
// Lifecycle - UIApplicationDidFinishLaunchingNotification - State: Background - Scene: Unattached
// Lifecycle - UISceneWillConnectNotification - State: Background - Scene: Unattached
// Lifecycle - userNotificationCenter:didReceive: - State: Background - Scene: Unattached
// Lifecycle - UISceneDidActivateNotification - State: Inactive - Scene: Foreground Active
// Lifecycle - UIApplicationDidBecomeActiveNotification - State: Active - Scene: Foreground Active
//
// Notification (no bg refresh) open when app is in foreground
// Lifecycle - userNotificationCenter:willPresent: - State: Active - Scene: Foreground Active
// Lifecycle - userNotificationCenter:didReceive: - State: Active - Scene: Foreground Active
//
// Notification (no bg refresh) open when app is open behind the lockscreen
// Lifecycle - UISceneWillEnterForegroundNotification - State: Background - Scene: Background
// Lifecycle - UIApplicationWillEnterForegroundNotification - State: Background - Scene: Foreground Inactive
// Lifecycle - userNotificationCenter:didReceive: - State: Inactive - Scene: Foreground Inactive
// Lifecycle - UISceneDidActivateNotification - State: Inactive - Scene: Foreground Active
// Lifecycle - UIApplicationDidBecomeActiveNotification - State: Active - Scene: Foreground Active
//
// Notification (bg refresh) with app in background
// Lifecycle - application:didReceiveRemoteNotification:fetchCompletionHandler: - State: Background - Scene: Background
//
// Notification (bg refresh) with app killed
// Lifecycle - application:didFinishLaunchingWithOptions: - State: Background - Scene: Unattached
// Lifecycle - UIApplicationDidFinishLaunchingNotification - State: Background - Scene: Unattached
// Lifecycle - UISceneWillConnectNotification - State: Background - Scene: Unattached
// Lifecycle - application:didReceiveRemoteNotification:fetchCompletionHandler: - State: Background - Scene: Background
//
// ---------
// App is NOT using UIScene on iOS 14
// ---------
//
// Cold open
// Lifecycle - application:didFinishLaunchingWithOptions: - State: Inactive - Scene: No UIScene
// Lifecycle - UIApplicationDidFinishLaunchingNotification - State: Inactive - Scene: No UIScene
// Lifecycle - UIApplicationDidBecomeActiveNotification - State: Active - Scene: No UIScene
//
// Notification (no bg refresh) warm open (app is in background)
// Lifecycle - UISceneWillEnterForegroundNotification - State: Background - Scene: No UIScene
// Lifecycle - UIApplicationWillEnterForegroundNotification - State: Background - Scene: No UIScene
// Lifecycle - userNotificationCenter:didReceive: - State: Inactive - Scene: No UIScene
// Lifecycle - application:didReceiveRemoteNotification:fetchCompletionHandler: - State: Inactive - Scene: No UIScene // (only if no UN delegate)
// Lifecycle - UISceneDidActivateNotification - State: Inactive - Scene: No UIScene
// Lifecycle - UIApplicationDidBecomeActiveNotification - State: Active - Scene: No UIScene
//
// Notification (no bg refresh) cold open (app is killed)
// Lifecycle - application:didFinishLaunchingWithOptions: - State: Inactive - Scene: No UIScene
// Lifecycle - UIApplicationDidFinishLaunchingNotification - State: Inactive - Scene: No UIScene
// Lifecycle - application:didReceiveRemoteNotification:fetchCompletionHandler: - State: Inactive - Scene: No UIScene // (only if no UN delegate)
// Lifecycle - userNotificationCenter:didReceive: - State: Inactive - Scene: No UIScene
// Lifecycle - UISceneDidActivateNotification - State: Inactive - Scene: No UIScene
// Lifecycle - UIApplicationDidBecomeActiveNotification - State: Active - Scene: No UIScene
//
// Notification (no bg refresh) open when app is in foreground
// Lifecycle - userNotificationCenter:willPresent: - State: Active - Scene: No UIScene
// Lifecycle - userNotificationCenter:didReceive: - State: Active - Scene: No UIScene
//
// Notification (no bg refresh) open when app is open behind the lockscreen
// Lifecycle - UISceneWillEnterForegroundNotification - State: Background - Scene: No UIScene
// Lifecycle - UIApplicationWillEnterForegroundNotification - State: Background - Scene: No UIScene
// Lifecycle - userNotificationCenter:didReceive: - State: Inactive - Scene: No UIScene
// Lifecycle - UISceneDidActivateNotification - State: Inactive - Scene: No UIScene
// Lifecycle - UIApplicationDidBecomeActiveNotification - State: Active - Scene: No UIScene
//
// Notification (bg refresh) with app in background
// Lifecycle - application:didReceiveRemoteNotification:fetchCompletionHandler: - State: Background - Scene: No UIScene
//
// Notification (bg refresh) with app killed
// Lifecycle - application:didFinishLaunchingWithOptions: - State: Background - Scene: No UIScene
// Lifecycle - UIApplicationDidFinishLaunchingNotification - State: Background - Scene: No UIScene
// Lifecycle - application:didReceiveRemoteNotification:fetchCompletionHandler: - State: Background - Scene: No UIScene
