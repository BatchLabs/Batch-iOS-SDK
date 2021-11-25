//
//  BADelegatedApplicationDelegate.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import "BADelegatedApplicationDelegate.h"

#import <objc/runtime.h>
#import <Batch/BAPushCenter.h>

#define DEBUG_SWIZZLE NO

@implementation BADelegatedApplicationDelegate

#pragma mark Public methods

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [BADelegatedApplicationDelegate new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _didSwizzle = false;
    }
    return self;
}

- (BOOL)swizzleAppDelegate
{
    if (!_batchDelegate) {
        return false;
    }
    
    if (_didSwizzle) {
        return false;
    }
    
    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    
    if (appDelegate == nil) {
        [BALogger debugForDomain:nil message:@"Cannot swizzle a nil application delegate."];
        return false;
    }
    
    Class appDelegateClass = [appDelegate class];
    
    if (appDelegateClass == [_batchDelegate class]) {
        // Prevent an infinite loop
        [BALogger publicForDomain:nil message:@"Batch was unable to automatically integrate with your application delegate due to an internal consistency check failure."];
        return false;
    }
    
    if ([appDelegateClass isKindOfClass:[NSProxy class]]) {
        [BALogger publicForDomain:nil message:@"Batch was unable to automatically integrate with your application delegate.\nThis might be due to a conflict with your code or another SDK. Please check the documentation for more information: https://batch.com\n\nBatchPush will NOT be enabled."];
        return false;
    }

    [self swizzleMethodsOfDelegate:appDelegate];
    
    _didSwizzle = true;
    return true;
}

#pragma mark -
#pragma mark Private methods

- (nullable IMP)swizzleMethod:(nonnull SEL)selector
                    withBlock:(nonnull id)replacementBlock
                      onClass:(nonnull Class)targetClass
  skipIfTargetDoesntImplement:(BOOL)skipIfNotImplemented
{
    NSParameterAssert(selector);
    NSParameterAssert(replacementBlock);
    NSParameterAssert(targetClass);
    
#if DEBUG_SWIZZLE
    NSString *selectorString = NSStringFromSelector(selector);
#endif
    
#if DEBUG_SWIZZLE
    NSLog(@"Swizzling %@", selectorString);
#endif
    
    // If the class instance doesn't implement a selector and
    // if we're been asked not to do anything if not implemented, skip
    if (skipIfNotImplemented && ![targetClass instancesRespondToSelector:selector]) {
#if DEBUG_SWIZZLE
        NSLog(@"Not implementing method %@", selectorString);
#endif
        return NULL;
    }
    
    // Get the original method
    Method originalMethod = class_getInstanceMethod(targetClass, selector);
    IMP originalImplementation = method_getImplementation(originalMethod);
    
    IMP newImplementation = imp_implementationWithBlock(replacementBlock);
    
    // Attempt to add the method to the class, if it isn't implemented already
    // If it is (which makes class_addMethod fail), we need to replace the implementation, which the block will have to call
    if (!class_addMethod(targetClass, selector, newImplementation, method_getTypeEncoding(originalMethod))) {
        method_setImplementation(originalMethod, newImplementation);
    }
    
    return originalImplementation;
}


- (void)swizzleMethodsOfDelegate:(nonnull id<UIApplicationDelegate>)delegate {
    NSParameterAssert(delegate);
    Class class = [delegate class];
    // If you swizzle more methods, make sure that you add tests
    [self swizzle_didRegisterForRemoteNotificationsWithDeviceToken:class];
    [self swizzle_didFailToRegisterForRemoteNotificationsWithError:class];
    [self swizzle_didReceiveRemoteNotification:class];
    [self swizzle_didReceiveRemoteNotification_fetchCompletionHandler:class];
    [self swizzle_didRegisterUserNotificationSettings:class];
    [self swizzle_handleActionWithIdentifier_forRemoteNotification_completionHandler:class];
    [self swizzle_handleActionWithIdentifier_forRemoteNotification_withResponseInfo_completionHandler:class];
}

#pragma mark Swizzled method implementations

- (void)swizzle_didRegisterForRemoteNotificationsWithDeviceToken:(Class)class {
    BADelegatedApplicationDelegate *delegatedAppDelegate = self;
    SEL selector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
    id block = ^(id _self, UIApplication *application, NSData *deviceToken) {
        [delegatedAppDelegate.batchDelegate application:application
       didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
        // Make sure to call the original implementation
        // Casting is necessary for arm64
        IMP originalIMP = delegatedAppDelegate.original_didRegisterForRemoteNotificationsWithDeviceToken;
        // Skip if there was no original implementation
        if (originalIMP == NULL) { return; }
        ((void ( *)(id, SEL, UIApplication *, NSData *))originalIMP)(_self, selector, application, deviceToken);
    };
    self.original_didRegisterForRemoteNotificationsWithDeviceToken =
    [self swizzleMethod:selector
              withBlock:block
                onClass:class
skipIfTargetDoesntImplement:false];
}

- (void)swizzle_didFailToRegisterForRemoteNotificationsWithError:(Class)class {
    BADelegatedApplicationDelegate *delegatedAppDelegate = self;
    SEL selector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
    id block = ^(id _self, UIApplication *application, NSError *error) {
        [delegatedAppDelegate.batchDelegate application:application
       didFailToRegisterForRemoteNotificationsWithError:error];
        
        IMP originalIMP = delegatedAppDelegate.original_didFailToRegisterForRemoteNotificationsWithError;
        if (originalIMP == NULL) { return; }
        ((void ( *)(id, SEL, UIApplication *, NSError *))originalIMP)(_self, selector, application, error);
    };
    self.original_didFailToRegisterForRemoteNotificationsWithError =
    [self swizzleMethod:selector
              withBlock:block
                onClass:class
skipIfTargetDoesntImplement:false];
}

- (void)swizzle_didReceiveRemoteNotification:(Class)class {
    BADelegatedApplicationDelegate *delegatedAppDelegate = self;
    SEL selector = @selector(application:didReceiveRemoteNotification:);
    id block = ^(id _self, UIApplication *application, NSDictionary *userInfo) {
        [delegatedAppDelegate.batchDelegate application:application
                           didReceiveRemoteNotification:userInfo];
        
        IMP originalIMP = delegatedAppDelegate.original_didReceiveRemoteNotification;
        if (originalIMP == NULL) { return; }
        ((void ( *)(id, SEL, UIApplication *, NSDictionary *))originalIMP)(_self, selector, application, userInfo);
    };
    self.original_didReceiveRemoteNotification =
    [self swizzleMethod:selector
              withBlock:block
                onClass:class
skipIfTargetDoesntImplement:false];
}

- (void)swizzle_didReceiveRemoteNotification_fetchCompletionHandler:(Class)class {
    BADelegatedApplicationDelegate *delegatedAppDelegate = self;
    SEL selector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    id block = ^(id _self, UIApplication *application, NSDictionary *userInfo, void (^completionHandler)(UIBackgroundFetchResult result) ) {
        [delegatedAppDelegate.batchDelegate application:application
                           didReceiveRemoteNotification:userInfo
                                 fetchCompletionHandler:completionHandler];
        
        IMP originalIMP = delegatedAppDelegate.original_didReceiveRemoteNotification_fetchCompletionHandler;
        if (originalIMP == NULL) { return; }
        ((void ( *)(id, SEL, UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult result)))originalIMP)(_self, selector, application, userInfo, completionHandler);
    };
    self.original_didReceiveRemoteNotification_fetchCompletionHandler =
    [self swizzleMethod:selector
              withBlock:block
                onClass:class
skipIfTargetDoesntImplement:true];
}

- (void)swizzle_didRegisterUserNotificationSettings:(Class)class {
    BADelegatedApplicationDelegate *delegatedAppDelegate = self;
    SEL selector = @selector(application:didRegisterUserNotificationSettings:);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

    id block = ^(id _self, UIApplication *application, UIUserNotificationSettings *notificationSettings) {
        [delegatedAppDelegate.batchDelegate application:application
                    didRegisterUserNotificationSettings:notificationSettings];
        
        IMP originalIMP = delegatedAppDelegate.original_didRegisterUserNotificationSettings;
        if (originalIMP == NULL) { return; }
        ((void ( *)(id, SEL, UIApplication *, UIUserNotificationSettings *))originalIMP)(_self, selector, application, notificationSettings);
    };
    
#pragma clang diagnostic pop
    
    self.original_didRegisterUserNotificationSettings =
    [self swizzleMethod:selector
              withBlock:block
                onClass:class
skipIfTargetDoesntImplement:false];
}

- (void)swizzle_handleActionWithIdentifier_forRemoteNotification_completionHandler:(Class)class {
    BADelegatedApplicationDelegate *delegatedAppDelegate = self;
    SEL selector = @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:);
    id block = ^(id _self, UIApplication *application, NSString *identifier, NSDictionary *userInfo, void (^completionHandler)(void)) {
        [delegatedAppDelegate.batchDelegate application:application
                             handleActionWithIdentifier:identifier
                                  forRemoteNotification:userInfo
                                      completionHandler:completionHandler];
        
        IMP originalIMP = delegatedAppDelegate.original_handleActionWithIdentifier_forRemoteNotification_completionHandler;
        if (originalIMP == NULL) { return; }
        ((void ( *)(id, SEL, UIApplication *, NSString *, NSDictionary *, void (^)(void)))originalIMP)(_self, selector, application, identifier, userInfo, completionHandler);
    };
    self.original_handleActionWithIdentifier_forRemoteNotification_completionHandler =
    [self swizzleMethod:selector
              withBlock:block
                onClass:class
skipIfTargetDoesntImplement:true];
}

- (void)swizzle_handleActionWithIdentifier_forRemoteNotification_withResponseInfo_completionHandler:(Class)class {
    BADelegatedApplicationDelegate *delegatedAppDelegate = self;
    SEL selector = @selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:);
    id block = ^(id _self, UIApplication *application, NSString *identifier, NSDictionary *userInfo, NSDictionary *responseInfo, void (^completionHandler)(void)) {
        [delegatedAppDelegate.batchDelegate application:application
                             handleActionWithIdentifier:identifier
                                  forRemoteNotification:userInfo
                                       withResponseInfo:responseInfo
                                      completionHandler:completionHandler];
        
        IMP originalIMP = delegatedAppDelegate.original_handleActionWithIdentifier_forRemoteNotification_withResponseInfo_completionHandler;
        if (originalIMP == NULL) { return; }
        ((void ( *)(id, SEL, UIApplication *, NSString *, NSDictionary *, NSDictionary *, void (^)(void)))originalIMP)(_self, selector, application, identifier, userInfo, responseInfo, completionHandler);
    };
    self.original_handleActionWithIdentifier_forRemoteNotification_withResponseInfo_completionHandler =
    [self swizzleMethod:selector
              withBlock:block
                onClass:class
skipIfTargetDoesntImplement:true];
}

@end
