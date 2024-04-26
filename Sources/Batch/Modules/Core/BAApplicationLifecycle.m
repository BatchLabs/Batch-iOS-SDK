//
//  BAApplicationLifecycle.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BAApplicationLifecycle.h"

#import <UserNotifications/UserNotifications.h>

@implementation BAApplicationLifecycle

+ (BOOL)applicationUsesSwiftUILifecycle {
    UIScene *scene = UIApplication.sharedApplication.connectedScenes.allObjects.firstObject;
    id<UISceneDelegate> delegate = scene.delegate;
    if (delegate == nil) {
        return false;
    }
    // Expected name is SwiftUI.AppSceneDelegate but we expect it to change
    return [NSStringFromClass([delegate class]) hasPrefix:@"SwiftUI."];
}

+ (BOOL)applicationUsesUIScene {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIApplicationSceneManifest"] != nil;
}

+ (BOOL)applicationImplementsUNDelegate {
    return [UNUserNotificationCenter currentNotificationCenter].delegate != nil;
}

+ (BOOL)isApplicationUIOnScreen {
    if ([self hasASceneInState:UISceneActivationStateForegroundActive]) {
        return true;
    }
    return UIApplication.sharedApplication.applicationState == UIApplicationStateActive;
}

+ (BOOL)hasASceneInState:(UISceneActivationState)activationState {
    if ([self applicationUsesUIScene]) {
        NSSet<UIScene *> *connectedScenes = UIApplication.sharedApplication.connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if (scene.activationState == activationState) {
                return true;
            }
        }
    }
    return false;
}

+ (BOOL)hasASceneInForegroundState {
    if ([self applicationUsesUIScene]) {
        NSSet<UIScene *> *connectedScenes = UIApplication.sharedApplication.connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive ||
                scene.activationState == UISceneActivationStateForegroundInactive) {
                return true;
            }
        }
    }
    return false;
}

@end
