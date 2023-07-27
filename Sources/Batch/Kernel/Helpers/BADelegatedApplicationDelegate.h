//
//  BADelegatedApplicationDelegate.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/objc.h>

#import <Batch/BAPartialApplicationDelegate.h>

NS_ASSUME_NONNULL_BEGIN

/// Class that gets swizzled in place of the UIApplication delegate and forwards the methods to another delegate
/// before calling the original implementation
@interface BADelegatedApplicationDelegate : NSObject

/// Whether this instance has already swizzled the delegate
@property (readonly) BOOL didSwizzle;

/// Batch's delegate
@property (nonatomic, strong) id<BAPartialApplicationDelegate> batchDelegate;

/// Original implementations to retain when we swizzled the delegate

@property (nullable) IMP original_didRegisterForRemoteNotificationsWithDeviceToken;
@property (nullable) IMP original_didFailToRegisterForRemoteNotificationsWithError;
@property (nullable) IMP original_didReceiveRemoteNotification;
@property (nullable) IMP original_didReceiveRemoteNotification_fetchCompletionHandler;
@property (nullable) IMP original_didRegisterUserNotificationSettings;
@property (nullable) IMP original_handleActionWithIdentifier_forRemoteNotification_completionHandler;
@property (nullable) IMP original_handleActionWithIdentifier_forRemoteNotification_withResponseInfo_completionHandler;

+ (instancetype)sharedInstance;

/*!
 @method swizzleAppDelegate:
 @abstract Swizzle the current [UIApplication sharedApplication].delegate class. Note that calling this method multiple
 times is an error. Make sure to set a `batchDelegate` on this object to be informed of the calls.
 @return Whether the operation succeeded
 */
- (BOOL)swizzleAppDelegate;

@end

NS_ASSUME_NONNULL_END
