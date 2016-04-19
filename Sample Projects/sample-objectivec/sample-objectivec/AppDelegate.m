//
//  AppDelegate.m
//  sample-objectivec
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

#import "AppDelegate.h"
#import "UnlockManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [BatchUnlock setupUnlockWithDelegate:self];
    [Batch startWithAPIKey:@"YOUR API KEY"];
    
    // Register iOS 8+ actionable notifications
    
    UIMutableUserNotificationAction *thumbsUpAction = [UIMutableUserNotificationAction new];
    thumbsUpAction.identifier = @"THUMBS_UP";
    thumbsUpAction.title = @"👍";
    thumbsUpAction.activationMode = UIUserNotificationActivationModeBackground;
    
    UIMutableUserNotificationAction *thumbsDownAction = [UIMutableUserNotificationAction new];
    thumbsDownAction.identifier = @"THUMBS_DOWN";
    thumbsDownAction.title = @"👎";
    thumbsDownAction.activationMode = UIUserNotificationActivationModeForeground;
    
    UIMutableUserNotificationAction *openAction = [UIMutableUserNotificationAction new];
    openAction.identifier = @"OPEN";
    openAction.title = @"Open";
    openAction.activationMode = UIUserNotificationActivationModeForeground;
    
    UIMutableUserNotificationCategory *thumbsCategory = [UIMutableUserNotificationCategory new];
    thumbsCategory.identifier = @"THUMBS_CATEGORY";
    [thumbsCategory setActions:@[thumbsUpAction, thumbsDownAction] forContext:UIUserNotificationActionContextDefault]; // Default = 4 actions max
    [thumbsCategory setActions:@[thumbsUpAction, thumbsDownAction, openAction] forContext:UIUserNotificationActionContextMinimal]; // Minimal = 2 actions max
    
    [BatchPush registerForRemoteNotificationsWithCategories:[NSSet setWithObject:thumbsCategory]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark BatchUnlockDelegate methods

- (void)automaticOfferRedeemed:(id<BatchOffer>)offer {
    NSLog(@"Automatically redeemed an offer: %@", [offer offerReference]);
    UnlockManager *unlockManager = [UnlockManager new];
    [unlockManager unlockItemsFromOffer:offer];
    [unlockManager showRedeemAlertForOffer:offer withViewController:self.window.rootViewController];
}
- (void)URLWithCodeFound:(NSString *)code {
    NSLog(@"Redeeming Magic Link with code: %@", code);
}

- (void)URLWithCodeRedeemed:(id<BatchOffer>)offer {
    NSLog(@"Redeemed Magic Link");
    [[UnlockManager new] unlockItemsFromOffer:offer];
}

- (void)URLWithCodeFailed:(BatchError *)error {
    NSLog(@"Failed to redeem Magic Link %@", [error localizedDescription]);
}

@end
