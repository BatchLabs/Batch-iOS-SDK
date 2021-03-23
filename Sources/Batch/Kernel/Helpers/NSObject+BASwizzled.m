//
//  NSObject+BASwizzled.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import "NSObject+BASwizzled.h"

#import <objc/runtime.h>
#import <Batch/BAPushCenter.h>

#define DEBUG_SWIZZLE   NO

// Dummy class to force this to stay linked

@implementation BASwizzledObject
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

@implementation NSObject (BASwizzled)

// Swizzle the current [UIApplication sharedApplication].delegate class for many UIApplicationDelegate methods.
+ (instancetype)swizzleForDelegate:(id<UIApplicationDelegate>)delegate
{
    if (!delegate)
    {
        return nil;
    }
    
    __block BOOL ok = NO;
    
    static id appDelegate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        appDelegate = [UIApplication sharedApplication].delegate;
        Class class = [appDelegate class];
        
        if ([class isKindOfClass:[NSProxy class]])
        {
            [BALogger publicForDomain:nil message:@"Batch was unable to automatically integrate with your application delegate.\nThis might be due to a conflict with your code or another SDK. Please check the documentation for more information: https://batch.com\n\nBatchPush will NOT be enabled."];
            ok = NO;
            return;
            
            /* // Find another delegate.
            int numClasses = objc_getClassList(NULL, 0);
            Class* list = (Class*)malloc(sizeof(Class) * numClasses);
            objc_getClassList(list, numClasses);
            
            for (int i = 0; i < numClasses; i++)
            {
                if (class_conformsToProtocol(list[i], @protocol(UIApplicationDelegate)) &&
                    ![list[i] isKindOfClass:[NSProxy class]] &&
                    ![list[i] isMemberOfClass:[NSProxy class]] &&
                    !(list[i] == [NSProxy class]) &&
                    ![list[i] isKindOfClass:[delegate class]] &&
                    ![list[i] isMemberOfClass:[delegate class]] &&
                    !(list[i] == [delegate class]))
                {
                    NSLog(@"Class: %@",list[i]);
                    class = list[i];
                }
            }
             */
        }
        
        if (DEBUG_SWIZZLE) NSLog(@"Class: %@",NSStringFromClass(class));

        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);

        NSArray *methods = @[@"BA_applicationDidFinishLaunching:",
                             @"BA_applicationDidBecomeActive:",
                             @"BA_applicationWillResignActive:",
                             @"BA_applicationDidReceiveMemoryWarning:",
                             @"BA_applicationWillTerminate:",
                             @"BA_applicationSignificantTimeChange:",
                             @"BA_application:willChangeStatusBarOrientation:duration:",
                             @"BA_application:didChangeStatusBarOrientation:",
                             @"BA_application:willChangeStatusBarFrame:",
                             @"BA_application:didChangeStatusBarFrame:",
                             @"BA_application:didRegisterUserNotificationSettings:",
                             @"BA_application:didRegisterForRemoteNotificationsWithDeviceToken:",
                             @"BA_application:didFailToRegisterForRemoteNotificationsWithError:",
                             @"BA_application:didReceiveRemoteNotification:",
                             @"BA_application:didReceiveLocalNotification:",
                             @"BA_application:handleActionWithIdentifier:forLocalNotification:completionHandler:",
                             @"BA_application:handleActionWithIdentifier:forRemoteNotification:completionHandler:",
                             @"BA_application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:",
                             @"BA_application:didReceiveRemoteNotification:fetchCompletionHandler:",
                             @"BA_application:performFetchWithCompletionHandler:",
                             @"BA_application:handleEventsForBackgroundURLSession:completionHandler:",
                             @"BA_applicationDidEnterBackground:",
                             @"BA_applicationWillEnterForeground:",
                             @"BA_applicationProtectedDataWillBecomeUnavailable:",
                             @"BA_applicationProtectedDataDidBecomeAvailable:",
                             @"BA_application:didFailToContinueUserActivityWithType:error:",
                             @"BA_application:didUpdateUserActivity:"];
        
        NSArray *conditionalMethods = @[@"BA_application:didReceiveRemoteNotification:fetchCompletionHandler:",
                                        @"BA_application:handleActionWithIdentifier:forRemoteNotification:completionHandler:",
                                        @"BA_application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:"];
        
        for (NSString *selectorString in methods)
        {
            SEL originalSelector = NSSelectorFromString([selectorString stringByReplacingOccurrencesOfString:@"BA_" withString:@""]);
            SEL swizzledSelector = NSSelectorFromString(selectorString);
            
            // Method to test on responder.
            if ([conditionalMethods containsObject:selectorString])
            {
                if (![appDelegate respondsToSelector:originalSelector])
                {
                    // Do not swizzle the conditional implementation methods.
                    continue;
                }
            }
            
            Method originalMethod = class_getInstanceMethod(class, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
                        
            BOOL didAddMethod = class_addMethod(class,
                                                originalSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod));
            
            if (didAddMethod)
            {
                if (DEBUG_SWIZZLE) NSLog(@"Add Method %@", selectorString);
                
                class_replaceMethod(class,
                                    swizzledSelector,
                                    imp_implementationWithBlock(^(){}),
                                    method_getTypeEncoding(originalMethod));
            }
            else
            {
                if (DEBUG_SWIZZLE) NSLog(@"Ext Method %@ for %p", selectorString, [UIApplication sharedApplication].delegate);
              
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
        
        ok = YES;
    });
    
    if (!ok)
    {
        return nil;
    }
    
    [appDelegate setAdditionalDelegate:delegate];
    
    return appDelegate;
}


#pragma mark -
#pragma mark additionalDelegate property

- (id<UIApplicationDelegate>)additionalDelegate
{
    return objc_getAssociatedObject(self, @selector(additionalDelegate));
}

- (void)setAdditionalDelegate:(id<UIApplicationDelegate>)additionalDelegate
{
    objc_setAssociatedObject(self, @selector(additionalDelegate), additionalDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


#pragma mark -
#pragma mark UIApplicationDelegate

// We swizzle a lot of deprecated stuff, so Ignore them for this part of the file
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)BA_applicationDidFinishLaunching:(UIApplication *)application
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(applicationDidFinishLaunching:)])
    {
        [self.additionalDelegate applicationDidFinishLaunching:application];
    }
    
    if ([self respondsToSelector:@selector(BA_applicationDidFinishLaunching:)])
    {
        [self BA_applicationDidFinishLaunching:application];
    }
}

- (void)BA_applicationDidBecomeActive:(UIApplication *)application
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(applicationDidBecomeActive:)])
    {
        [self.additionalDelegate applicationDidBecomeActive:application];
    }
   
    if ([self respondsToSelector:@selector(BA_applicationDidBecomeActive:)])
    {
        [self BA_applicationDidBecomeActive:application];
    }
}

- (void)BA_applicationWillResignActive:(UIApplication *)application
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(applicationWillResignActive:)])
    {
        [self.additionalDelegate applicationWillResignActive:application];
    }
    
    if ([self respondsToSelector:@selector(BA_applicationWillResignActive:)])
    {
        [self BA_applicationWillResignActive:application];
    }
}

- (void)BA_applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(applicationDidReceiveMemoryWarning:)])
    {
        [self.additionalDelegate applicationDidReceiveMemoryWarning:application];
    }
   
    if ([self respondsToSelector:@selector(BA_applicationDidReceiveMemoryWarning:)])
    {
        [self BA_applicationDidReceiveMemoryWarning:application];
    }
}

- (void)BA_applicationWillTerminate:(UIApplication *)application
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(applicationWillTerminate:)])
    {
        [self.additionalDelegate applicationWillTerminate:application];
    }
    
    if ([self respondsToSelector:@selector(BA_applicationWillTerminate:)])
    {
        [self BA_applicationWillTerminate:application];
    }
}

- (void)BA_applicationSignificantTimeChange:(UIApplication *)application
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(applicationSignificantTimeChange:)])
    {
        [self.additionalDelegate applicationSignificantTimeChange:application];
    }
    
    if ([self respondsToSelector:@selector(BA_applicationSignificantTimeChange:)])
    {
        [self BA_applicationSignificantTimeChange:application];
    }
}

- (void)BA_application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:willChangeStatusBarOrientation:duration:)])
    {
        [self.additionalDelegate application:application willChangeStatusBarOrientation:newStatusBarOrientation duration:duration];
    }
    
    if ([self respondsToSelector:@selector(BA_application:willChangeStatusBarOrientation:duration:)])
    {
        [self BA_application:application willChangeStatusBarOrientation:newStatusBarOrientation duration:duration];
    }
}

- (void)BA_application:(UIApplication *)application didChangeStatusBarOrientation:(UIInterfaceOrientation)oldStatusBarOrientation
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:didChangeStatusBarOrientation:)])
    {
        [self.additionalDelegate application:application didChangeStatusBarOrientation:oldStatusBarOrientation];
    }
    
    if ([self respondsToSelector:@selector(BA_application:didChangeStatusBarOrientation:)])
    {
        [self BA_application:application didChangeStatusBarOrientation:oldStatusBarOrientation];
    }
}

- (void)BA_application:(UIApplication *)application willChangeStatusBarFrame:(CGRect)newStatusBarFrame
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:willChangeStatusBarFrame:)])
    {
        [self.additionalDelegate application:application willChangeStatusBarFrame:newStatusBarFrame];
    }
    
    if ([self respondsToSelector:@selector(BA_application:willChangeStatusBarFrame:)])
    {
        [self BA_application:application willChangeStatusBarFrame:newStatusBarFrame];
    }
}

- (void)BA_application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)oldStatusBarFrame
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:didChangeStatusBarFrame:)])
    {
        [self.additionalDelegate application:application didChangeStatusBarFrame:oldStatusBarFrame];
    }
    
    if ([self respondsToSelector:@selector(BA_application:didChangeStatusBarFrame:)])
    {
        [self BA_application:application didChangeStatusBarFrame:oldStatusBarFrame];
    }
}

- (void)BA_application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:didRegisterUserNotificationSettings:)])
    {
        [self.additionalDelegate application:application didRegisterUserNotificationSettings:notificationSettings];
    }
    
    if ([self respondsToSelector:@selector(BA_application:didRegisterUserNotificationSettings:)])
    {
        [self BA_application:application didRegisterUserNotificationSettings:notificationSettings];
    }
}

- (void)BA_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)])
    {
        [self.additionalDelegate application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
    
    if ([self respondsToSelector:@selector(BA_application:didRegisterForRemoteNotificationsWithDeviceToken:)])
    {
        [self BA_application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)BA_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)])
    {
        [self.additionalDelegate application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
    
    if ([self respondsToSelector:@selector(BA_application:didFailToRegisterForRemoteNotificationsWithError:)])
    {
        [self BA_application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

- (void)BA_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)])
    {
        [self.additionalDelegate application:application didReceiveRemoteNotification:userInfo];
    }
    
    if ([self respondsToSelector:@selector(BA_application:didReceiveRemoteNotification:)])
    {
        [self BA_application:application didReceiveRemoteNotification:userInfo];
    }
}

- (void)BA_application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:didReceiveLocalNotification:)])
    {
        [self.additionalDelegate application:application didReceiveLocalNotification:notification];
    }
    
    if ([self respondsToSelector:@selector(BA_application:didReceiveLocalNotification:)])
    {
        [self BA_application:application didReceiveLocalNotification:notification];
    }
}

- (void)BA_application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void(^)())completionHandler
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:)])
    {
        [self.additionalDelegate application:application handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:completionHandler];
    }
    
    if ([self respondsToSelector:@selector(BA_application:handleActionWithIdentifier:forLocalNotification:completionHandler:)])
    {
        [self BA_application:application handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:completionHandler];
    }
}

- (void)BA_application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)])
    {
        [self.additionalDelegate application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
    }
    
    if ([self respondsToSelector:@selector(BA_application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)])
    {
        [self BA_application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
    }
}

- (void)BA_application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void(^)())completionHandler
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)])
    {
        [self.additionalDelegate application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];
    }
    
    if ([self respondsToSelector:@selector(BA_application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)])
    {
        [self BA_application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];
    }
}

- (void)BA_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)])
    {
        [self.additionalDelegate application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
    
    if ([self respondsToSelector:@selector(BA_application:didReceiveRemoteNotification:fetchCompletionHandler:)])
    {
        [self BA_application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
    else if ([self respondsToSelector:@selector(BA_application:didReceiveRemoteNotification:)])
    {
        [self BA_application:application didReceiveRemoteNotification:userInfo];
        completionHandler(UIBackgroundFetchResultNoData);
    }
    else
    {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (void)BA_application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:performFetchWithCompletionHandler:)])
    {
        [self.additionalDelegate application:application performFetchWithCompletionHandler:completionHandler];
    }
    
    if ([self respondsToSelector:@selector(BA_application:performFetchWithCompletionHandler:)])
    {
        [self BA_application:application performFetchWithCompletionHandler:completionHandler];
    }
}

- (void)BA_application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:handleEventsForBackgroundURLSession:completionHandler:)])
    {
        [self.additionalDelegate application:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
    }
    
    if ([self respondsToSelector:@selector(BA_application:handleEventsForBackgroundURLSession:completionHandler:)])
    {
        [self BA_application:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
    }
}

- (void)BA_applicationDidEnterBackground:(UIApplication *)application
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(applicationDidEnterBackground:)])
    {
        [self.additionalDelegate applicationDidEnterBackground:application];
    }
    
    if ([self respondsToSelector:@selector(BA_applicationDidEnterBackground:)])
    {
        [self BA_applicationDidEnterBackground:application];
    }
}

- (void)BA_applicationWillEnterForeground:(UIApplication *)application
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(applicationWillEnterForeground:)])
    {
        [self.additionalDelegate applicationWillEnterForeground:application];
    }
    
    if ([self respondsToSelector:@selector(BA_applicationWillEnterForeground:)])
    {
        [self BA_applicationWillEnterForeground:application];
    }
}

- (void)BA_applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(applicationProtectedDataWillBecomeUnavailable:)])
    {
        [self.additionalDelegate applicationProtectedDataWillBecomeUnavailable:application];
    }
    
    if ([self respondsToSelector:@selector(BA_applicationProtectedDataWillBecomeUnavailable:)])
    {
        [self BA_applicationProtectedDataWillBecomeUnavailable:application];
    }
}

- (void)BA_applicationProtectedDataDidBecomeAvailable:(UIApplication *)application
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(applicationProtectedDataDidBecomeAvailable:)])
    {
        [self.additionalDelegate applicationProtectedDataDidBecomeAvailable:application];
    }
    
    if ([self respondsToSelector:@selector(BA_applicationProtectedDataDidBecomeAvailable:)])
    {
        [self BA_applicationProtectedDataDidBecomeAvailable:application];
    }
}

- (void)BA_application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:didFailToContinueUserActivityWithType:error:)])
    {
        [self.additionalDelegate application:application didFailToContinueUserActivityWithType:userActivityType error:error];
    }
    
    if ([self respondsToSelector:@selector(BA_application:didFailToContinueUserActivityWithType:error:)])
    {
        [self BA_application:application didFailToContinueUserActivityWithType:userActivityType error:error];
    }
}

- (void)BA_application:(UIApplication *)application didUpdateUserActivity:(NSUserActivity *)userActivity
{
    if (DEBUG_SWIZZLE) NSLog(@"Swizzled %s",__PRETTY_FUNCTION__);
    
    if ([self.additionalDelegate respondsToSelector:@selector(application:didUpdateUserActivity:)])
    {
        [self.additionalDelegate application:application didUpdateUserActivity:userActivity];
    }
    
    if ([self respondsToSelector:@selector(BA_application:didUpdateUserActivity:)])
    {
        [self BA_application:application didUpdateUserActivity:userActivity];
    }
}

#pragma clang diagnostic pop

@end

#pragma clang diagnostic pop
