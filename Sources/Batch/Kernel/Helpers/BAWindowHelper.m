//
//  BAWindowHelper.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAWindowHelper.h>

@implementation BAWindowHelper

+ (nullable UIWindowScene*)activeScene NS_AVAILABLE_IOS(13.0)
{
    NSSet<UIScene*>* connectedScenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene* scene in connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            return (UIWindowScene*)scene;
        }
    }
    return nil;
}

+ (nullable UIWindowScene*)activeWindowScene NS_AVAILABLE_IOS(13.0)
{
    NSSet<UIScene*>* connectedScenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene* scene in connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:UIWindowScene.class]) {
            return (UIWindowScene*)scene;
        }
    }
    return nil;
}

+ (UIWindow*)keyWindow
{
    if (@available(iOS 13.0, *)) {
        UIWindow* window = [self keyWindowFromSceneAPI];
        return window != nil ? window : UIApplication.sharedApplication.keyWindow;
    } else {
        return UIApplication.sharedApplication.keyWindow;
    }
}

+ (nullable UIWindow*)keyWindowFromSceneAPI NS_AVAILABLE_IOS(13.0)
{
    // Don't use activeWindowScene as we want to loop on all scenes until we get what we want
    NSSet<UIScene*>* connectedScenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene* scene in connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:UIWindowScene.class]) {
            for (UIWindow* window in [(UIWindowScene*)scene windows]) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    return nil;
}

@end
