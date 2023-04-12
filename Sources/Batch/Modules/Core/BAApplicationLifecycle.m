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
    if (@available(iOS 13.0, *)) {
        UIScene *scene = UIApplication.sharedApplication.connectedScenes.allObjects.firstObject;
        id<UISceneDelegate> delegate = scene.delegate;
        if (delegate == nil) {
            return false;
        }
        // Expected name is SwiftUI.AppSceneDelegate but we expect it to change
        return [NSStringFromClass([delegate class]) hasPrefix:@"SwiftUI."];
    }
    return false;
}

+ (BOOL)applicationUsesUIScene {
    if (@available(iOS 13.0, *)) {
        return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIApplicationSceneManifest"] != nil;
    }
    return false;
}

+ (BOOL)applicationImplementsUNDelegate {
    return [UNUserNotificationCenter currentNotificationCenter].delegate != nil;
}

+ (BOOL)isApplicationUIOnScreen {
    if (@available(iOS 13.0, *)) {
        if ([self hasASceneInState:UISceneActivationStateForegroundActive]) {
            return true;
        }
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
    if (@available(iOS 13.0, *)) {
        if ([self applicationUsesUIScene]) {
            NSSet<UIScene *> *connectedScenes = UIApplication.sharedApplication.connectedScenes;
            for (UIScene *scene in connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive ||
                    scene.activationState == UISceneActivationStateForegroundInactive) {
                    return true;
                }
            }
        }
    }
    return false;
}

@end
