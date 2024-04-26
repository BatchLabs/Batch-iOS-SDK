//
//  BADelegatedApplicationDelegate.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import "BADelegatedApplicationDelegate.h"

#import <Batch/BAPushCenter.h>
#import <objc/runtime.h>

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

- (instancetype)init {
    self = [super init];
    if (self) {
        _didSwizzle = false;
    }
    return self;
}

- (BOOL)swizzleAppDelegate {
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
        [BALogger publicForDomain:nil
                          message:@"Batch was unable to automatically integrate with your application delegate due to "
                                  @"an internal consistency check failure."];
        return false;
    }

    if ([appDelegateClass isKindOfClass:[NSProxy class]]) {
        [BALogger
            publicForDomain:nil
                    message:@"Batch was unable to automatically integrate with your application delegate.\nThis might "
                            @"be due to a conflict with your code or another SDK. Please check the documentation for "
                            @"more information: https://batch.com\n\nBatchPush will NOT be enabled."];
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
    skipIfTargetDoesntImplement:(BOOL)skipIfNotImplemented {
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
    // If it is (which makes class_addMethod fail), we need to replace the implementation, which the block will have to
    // call
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
      if (originalIMP == NULL) {
          return;
      }
      ((void (*)(id, SEL, UIApplication *, NSData *))originalIMP)(_self, selector, application, deviceToken);
    };
    self.original_didRegisterForRemoteNotificationsWithDeviceToken =
        [self swizzleMethod:selector withBlock:block onClass:class skipIfTargetDoesntImplement:false];
}

- (void)swizzle_didFailToRegisterForRemoteNotificationsWithError:(Class)class {
    BADelegatedApplicationDelegate *delegatedAppDelegate = self;
    SEL selector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
    id block = ^(id _self, UIApplication *application, NSError *error) {
      [delegatedAppDelegate.batchDelegate application:application
          didFailToRegisterForRemoteNotificationsWithError:error];

      IMP originalIMP = delegatedAppDelegate.original_didFailToRegisterForRemoteNotificationsWithError;
      if (originalIMP == NULL) {
          return;
      }
      ((void (*)(id, SEL, UIApplication *, NSError *))originalIMP)(_self, selector, application, error);
    };
    self.original_didFailToRegisterForRemoteNotificationsWithError =
        [self swizzleMethod:selector withBlock:block onClass:class skipIfTargetDoesntImplement:false];
}

@end
