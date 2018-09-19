//
//  BatchCore.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BatchUserProfile.h"
#import "BatchLogger.h"

@protocol BatchDeeplinkDelegate;

typedef NS_ENUM(NSUInteger, BatchOptOutNetworkErrorPolicy) {
    /**
     Ignore the error and proceed with the opt-out.
     */
    BatchOptOutNetworkErrorPolicyIgnore,
    
    /**
     Cancel the opt-out: please call the opt-out method again to retry.
     */
    BatchOptOutNetworkErrorPolicyCancel,
};

/**
 Batch's main entry point.
 
 @version v1.13.0
 
 @availability iOS 8.0
 */
@interface Batch : NSObject

/**
 Use the deeplink delegate object to process deeplink open requests from Batch.
 
 Setting a delegate will disable Batch's default behaviour, which is to call [[UIApplication sharedApplication] openURL:].
 This works for notifications and mobile landings/in-app messages, as opposed to disabling automatic deeplink handling.
 It is weakly retained: make sure you retain your delegate in some place, like your application delegate.
 
 */
@property (class, weak, nullable, nonatomic) id<BatchDeeplinkDelegate> deeplinkDelegate;

/**
 @warning Never call this method: Batch only uses static methods.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 Start Batch.
 You should call this method in application:didFinishLaunchingWithOptions: of your UIApplicationDelegate
 
 Note: This is the method that triggers the hooking or your Application to automatically handle some lifecycle events.
 If you run into issues, you can try moving this method before other SDK initializations, or call [BatchPush disableAutomaticIntegration] before this method, and follow the "Manual Integration" advanced documentation.
 
 @param key Your APP's API Key, LIVE or DEV. You can find it on your dashboard.
 */
+ (void)startWithAPIKey:(NSString *_Nonnull)key NS_AVAILABLE_IOS(8_0);

/**
 Handles a URL, if applicable.
 Call this method in application:openURL:sourceApplication:annotation: of your UIApplicationDelegate
 
 @param url The URL given to you by iOS
 
 @return YES if Batch performed an action with this URL, NO otherwise.
 */
+ (BOOL)handleURL:(NSURL * _Nonnull)url __attribute__((warn_unused_result)) NS_AVAILABLE_IOS(8_0);

/**
 Check if Batch is running in development mode.
 
 @return YES if Batch is started AND if it uses a development API key.
 */
+ (BOOL)isRunningInDevelopmentMode __attribute__((warn_unused_result)) NS_AVAILABLE_IOS(8_0);

/**
 Access the default user profile object.
 
 @return An instance of BatchUserProfile, or nil
 */
+ (BatchUserProfile * _Nullable)defaultUserProfile __attribute__((warn_unused_result, deprecated("Please use Batch User instead"))) NS_AVAILABLE_IOS(8_0);

/**
 Control whether Batch should try to use the IDFA or if you forbid it to. (default = YES)
 
 @param use YES if Batch can try to use the IDFA, NO if you don't want Batch to use the IDFA.
 
 @warning If you disable this, you might not be able to use IDFA based debugging in your dashboard.
 */
+ (void)setUseIDFA:(BOOL)use NS_AVAILABLE_IOS(8_0);

/**
 Set if Batch can use advanced device identifiers (default = YES)
 
 Advanced device identifiers include information about the device itself, but nothing that
 directly identify the user, such as but not limited to:
 
 - Device model
 
 - Device brand
 
 - Carrier name
 
 - IDFV

 Setting this to false have a negative impact on core Batch features
 You should only use it if you know what you are doing.
 
 @param use YES if Batch can try to use advanced device information, NO if you don't
 
 @warning Disabling this does not automatically disable IDFA collection, please use the appropriate methods to control this.
 */
+ (void)setUseAdvancedDeviceInformation:(BOOL)use NS_AVAILABLE_IOS(8_0);

/**
 Set if Batch should send its logs to a custom object of yours.
 Be careful with your implementation: setting this can impact stability and performance
 
 @param loggerDelegate An object implementing BatchLoggerDelegate. Weakly retained.
 
 @warning You should only use it if you know what you are doing.
 */
+ (void)setLoggerDelegate:(id<BatchLoggerDelegate> _Nullable)loggerDelegate NS_AVAILABLE_IOS(8_0);

/**
 Get the debug view controller.
 For development purposes only, this contains UI with multiple debug features allowing you to debug your Batch implementation more easily.
 If you want to make it accessible in production, you should hide it in a hard to reproduce sequence.
 
 Should be presented modally.
 */
+ (UIViewController* _Nullable)debugViewController;

/**
 Opt-out from Batch SDK usage.
 A push opt-out command will be sent to Batch's servers if the user is connected to the internet.
 If disconnected, notifications might not be disabled properly. Please use [Batch optOutWithCompletionHandler:] to handle
 these cases more gracefully.
 
 Your app should be prepared to handle these cases. Some modules might behave unexpectedly
 when the SDK is opted out from.
 
 Opting out will:
  - Prevent [Batch startWithAPIKey:] from starting the SDK
  - Disable any network capability from the SDK
  - Disable all In-App campaigns
  - Make the Inbox module return an error immediatly
  - Make any call to -[BatchUserDataEditor save] do nothing
  - Make any "track" methods from BatchUser ineffective
 
 Even if you opt-in afterwards, data generated (such as user data or tracked events) while opted out WILL be lost.
 
 If you also want to delete user data, please see [Batch optOutAndWipeData].
 */
+ (void)optOut;

/**
 Opt-out from Batch SDK and wipe data.
 An installation data wipe command will be sent to Batch's servers if the user is connected to the internet.
 If disconnected, notifications might not be disabled properly. Please use [Batch optOutAndWipeDataWithCompletionHandler:] to handle
 these cases more gracefully.
 
 See [Batch optOut] documentation for details
 Note that once opted out, [Batch startWithAPIKey:] will essentially be a no-op
 Your app should be prepared to handle these cases.
 */
+ (void)optOutAndWipeData;

/**
 Opt-out from Batch SDK.
 
 See [Batch optOut] documentation for details.

 Use the completion handler to be informed about whether the opt-out request has been successfully sent to the server or not.
 You'll also be able to control what to do in case of failure.
 
 Note: if the SDK has already been opted-out from, this method will instantly call the completion handler with a *failure* state.
 */
+ (void)optOutWithCompletionHandler:(BatchOptOutNetworkErrorPolicy(^ _Nonnull)(BOOL success))handler;

/**
 Opt-out from Batch SDK and wipe data.
 
 See [Batch optOutAndWipeData] documentation for details.
 
 Use the completion handler to be informed about whether the opt-out request has been successfully sent to the server or not.
 You'll also be able to control what to do in case of failure.
 
 Note: if the SDK has already been opted-out from, this method will instantly call the completion handler with a *failure* state.
 */
+ (void)optOutAndWipeDataWithCompletionHandler:(BatchOptOutNetworkErrorPolicy(^ _Nonnull)(BOOL success))handler;

/**
 Opt-in to Batch SDK.
 
 Useful if you called [Batch optOut], [Batch optOutAndWipeData] or opted out by default in your Info.plist
 Some features might not fully work until the next app restart. You will need to call [Batch startWithAPIKey:@""] after this.
 */
+ (void)optIn;

/**
 Returns whether Batch has been opted out from or not
 */
+ (BOOL)isOptedOut;

@end

/**
 BatchDeeplinkDelegate is the protocol to adopt when you want to set a deeplink delegate on the SDK.
 
 See Batch.deeplinkDelegate for more info.
 */
@protocol BatchDeeplinkDelegate <NSObject>

/**
 Method called when Batch needs to open a deeplink.
 
 This will be called on the main thread.
 */
- (void)openBatchDeeplink:(nonnull NSString*)deeplink;

@end
