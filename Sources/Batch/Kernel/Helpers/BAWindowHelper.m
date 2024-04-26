//
//  BAWindowHelper.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAWindowHelper.h>

@implementation BAWindowHelper

+ (nullable UIWindowScene *)activeScene {
    NSSet<UIScene *> *connectedScenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene *scene in connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

+ (nullable UIWindowScene *)activeWindowScene {
    NSSet<UIScene *> *connectedScenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene *scene in connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:UIWindowScene.class]) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

+ (UIWindow *)keyWindow {
    UIWindow *window = [self keyWindowFromSceneAPI];

#if TARGET_OS_VISION

    return window;

#else

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return window != nil ? window : UIApplication.sharedApplication.keyWindow;
#pragma clang diagnostic pop

#endif
}

+ (nullable UIWindow *)keyWindowFromSceneAPI {
    // Don't use activeWindowScene as we want to loop on all scenes until we get what we want
    NSSet<UIScene *> *connectedScenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene *scene in connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:UIWindowScene.class]) {
            for (UIWindow *window in [(UIWindowScene *)scene windows]) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    return nil;
}

+ (UIViewController *)frontmostViewController {
    UIWindow *overlayedWindow = [BAWindowHelper keyWindow];
    UIViewController *presentedVC = overlayedWindow.rootViewController;
    while (presentedVC.presentedViewController) {
        presentedVC = presentedVC.presentedViewController;
    }
    return presentedVC;
}

@end
