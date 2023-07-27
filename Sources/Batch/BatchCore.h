//
//  BatchCore.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Batch/BatchLogger.h>
#import <Batch/BatchUserProfile.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol BatchDeeplinkDelegate;

typedef NS_ENUM(NSUInteger, BatchOptOutNetworkErrorPolicy) {

    /// Ignore the error and proceed with the opt-out.
    BatchOptOutNetworkErrorPolicyIgnore,

    /// Cancel the opt-out: please call the opt-out method again to retry.
    BatchOptOutNetworkErrorPolicyCancel,
};

/// Batch's main entry point.
@interface Batch : NSObject

/// Use the deeplink delegate object to process deeplink open requests from Batch.
///
/// Setting a delegate will disable Batch's default behaviour,
/// which is to call `[[UIApplication sharedApplication] openURL:]`.
/// This works for notifications and mobile landings/in-app messages, as opposed to disabling automatic
/// deeplink handling.
/// - Important: It is weakly retained: make sure you retain your delegate in some place, like your application
@property (class, weak, nullable, nonatomic) id<BatchDeeplinkDelegate> deeplinkDelegate;

/// Control whether Batch should enables the _FindMyInstallation_ feature (default = YES)
///
/// If enabled Batch will copy the current installation id in the clipboard when the application is foregrounded 5 times
/// within 12 seconds.
@property (class) BOOL enablesFindMyInstallation;

/// Init method
/// - Warning: Never call this method: Batch only uses static methods.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Start Batch.
///
/// You should call this method in `application:didFinishLaunchingWithOptions:` of your `UIApplicationDelegate`
///
/// - Note: This is the method that triggers the hooking or your Application to automatically handle some lifecycle
/// events. If you run into issues, you can try moving this method before other SDK initializations, or call
/// ``Batch/BatchPush/disableAutomaticIntegration`` before this method, and follow the "Manual Integration" advanced.
/// - Parameters:
///    - key: Your APP's API Key, LIVE or DEV. You can find it on your dashboard.
+ (void)startWithAPIKey:(NSString *_Nonnull)key NS_AVAILABLE_IOS(8_0);

/// Handles an URL, if applicable.
///
/// Call this method in `application:openURL:sourceApplication:annotation:` of your `UIApplicationDelegate`
/// - Parameters:
///    - url: The URL given to you by iOS
/// - Returns: YES if Batch performed an action with this URL, NO otherwise.
+ (BOOL)handleURL:(NSURL *_Nonnull)url __attribute__((warn_unused_result))NS_AVAILABLE_IOS(8_0);

/// Check if Batch is running in development mosde.
///
/// - Returns: YES if Batch is started __AND__ if it uses a development API key.
+ (BOOL)isRunningInDevelopmentMode __attribute__((warn_unused_result))NS_AVAILABLE_IOS(8_0);

/// Access the default user profile object.
///
/// - Returns: An instance of ``BatchUserProfile``, or nil
+ (BatchUserProfile *_Nullable)defaultUserProfile
    __attribute__((warn_unused_result, deprecated("Please use Batch User instead")))NS_AVAILABLE_IOS(8_0);

///  Control whether Batch should try to use the IDFA or if you forbid it to. (default = YES)
/// - Warning: If you disable this, you might not be able to use IDFA based debugging in your dashboard.
/// - Parameters:
///     - use: YES if Batch can try to use the IDFA, NO if you don't want Batch to use the IDFA.
+ (void)setUseIDFA:(BOOL)use NS_AVAILABLE_IOS(8_0);

/// Set if Batch can use advanced device identifiers (default = YES)
///
/// Advanced device identifiers include information about the device itself, but nothing that directly identify the
/// user, such as but not limited to:
/// - Device model
/// - Device brand
/// - Carrier name
/// - Important: Disabling this does not automatically disable IDFA collection, please use the appropriate methods to
/// control this.
/// - Parameters:
///   - use: YES if Batch can try to use advanced device information, NO if you don't
+ (void)setUseAdvancedDeviceInformation:(BOOL)use NS_AVAILABLE_IOS(8_0);

/// Set if Batch should send its logs to a custom object of yours.
///
/// - Important: Be careful with your implementation: setting this can impact stability and performance. You should only
/// use it if you know what you are doing.
/// - Parameter loggerDelegate: An object implementing ``Batch/BatchLoggerDelegate``. Weakly retained.
+ (void)setLoggerDelegate:(id<BatchLoggerDelegate> _Nullable)loggerDelegate NS_AVAILABLE_IOS(8_0);

/// Get the debug view controller.
///
/// For development purposes only, this contains UI with multiple debug features allowing you to debug your Batch
/// implementation more easily. If you want to make it accessible in production, you should hide it in a hard to
/// reproduce sequence.
/// - Note: Should be presented modally.
+ (UIViewController *_Nullable)debugViewController;

/// Toogle whether internal logs should be logged or not.
///
/// If you have a ``Batch/BatchLoggerDelegate``, please be careful: the internal logs are quite verbose.
/// Your logger delegate method might be called often, make sure it is performent enough and has a memory allocation
/// limit.
/// This can also be controlled using `-BatchSDKEnableInternalLogs`.
/// - Parameter enableInternalLogs: Whether to enable development logs. Default: false (unless enabled via CLI).
+ (void)setInternalLogsEnabled:(BOOL)enableInternalLogs;

/// Opt-out from Batch SDK usage.
///
/// - Important: Calling this method when Batch hasn't started does nothing: Please call
/// ``Batch/Batch/startWithAPIKey:`` beforehand.
///
/// A push opt-out command will be sent to Batch's servers if the user is connected to the internet.
/// If disconnected, notifications might not be disabled properly. Please use
/// ``Batch/Batch/optOutWithCompletionHandler:``  to handle these cases more gracefully.
///
/// Your app should be prepared to handle these cases. Some modules might behave unexpectedly when the SDK is opted out
/// from.
///
/// Opting out will:
/// - Prevent ``Batch/Batch/startWithAPIKey:``  from starting the SDK
/// - Disable any network capability from the SDK
/// - Disable all In-App campaigns
/// - Make the Inbox module return an error immediatly
/// - Make any call to ``Batch/BatchUserDataEditor/save``  do nothing
/// - Make any `track` methods from ``BatchUser`` ineffective
///
/// Even if you opt-in afterwards, data generated (such as user data or tracked events) while opted out __WILL__ be
/// lost.
///
/// If you also want to delete user data, please see ``Batch/Batch/optOutAndWipeData``.
+ (void)optOut;

/// Opt-out from Batch SDK and wipe data.
///
/// - Important: Calling this method when Batch hasn't started does nothing: Please call
/// ``Batch/Batch/startWithAPIKey:`` beforehand test.
///
/// An installation data wipe command will be sent to Batch's servers if the user is connected to the internet.
/// If disconnected, notifications might not be disabled properly. Please use
/// ``Batch/Batch/optOutAndWipeDataWithCompletionHandler:`` to handle these cases more gracefully.
///
/// See ``Batch/Batch/optOut`` documentation for details.
///
/// - Note: Once opted out, ``Batch/Batch/startWithAPIKey:`` will essentially be a no-op. Your app should be prepared to
/// handle these cases.
+ (void)optOutAndWipeData;

/// Opt-out from Batch SDK.
///
/// - Important: Calling this method when Batch hasn't started does nothing: Please call
/// ``Batch/Batch/startWithAPIKey:`` beforehand test.
///
/// See ``Batch/Batch/optOut`` documentation for details.
///
/// Use the completion handler to be informed about whether the opt-out request has been successfully sent to the server
/// or not. You'll also be able to control what to do in case of failure.
///
/// - Note: if the SDK has already been opted-out from, this method will instantly call the completion handler with a
/// *failure* state.
///
/// - Parameter handler: completion handler execetued when the opt-out request is finished.
+ (void)optOutWithCompletionHandler:(BatchOptOutNetworkErrorPolicy (^_Nonnull)(BOOL success))handler;

/// Opt-out from Batch SDK and wipe data.
///
/// - Important: Calling this method when Batch hasn't started does nothing: Please call
/// ``Batch/Batch/startWithAPIKey:`` beforehand test.
///
/// See ``Batch/Batch/optOut`` documentation for details.
///
/// Use the completion handler to be informed about whether the opt-out request has been successfully sent to the server
/// or not. You'll also be able to control what to do in case of failure.
///
/// - Note: if the SDK has already been opted-out from, this method will instantly call the completion handler with a
/// *failure* state.
///
/// - Parameter handler: Block execetued when the opt-out request is finished.
+ (void)optOutAndWipeDataWithCompletionHandler:(BatchOptOutNetworkErrorPolicy (^_Nonnull)(BOOL success))handler;

/// Opt-in to Batch SDK.
///
/// Useful if you called ``Batch/Batch/optOut``, ``Batch/Batch/optOutAndWipeData`` or opted out by default in your
/// Info.plist.
/// - Important: You will need to call ``Batch/Batch/startWithAPIKey:`` after this.
+ (void)optIn;

/// Returns whether Batch has been opted out from or not
+ (BOOL)isOptedOut;

/// Set your list of associated domains, If your app handle universal links.
///
/// If your site uses multiple subdomains (such as example.com, www.example.com, or support.example.com), each requires
/// its own entry like in the `Associated Domains Entitlement`file.
///
/// - Important: Make sure to only include the desired subdomain and the top-level domain. Don’t include path and query
/// components or a trailing slash (/).
/// - Parameter domains: An array of your supported associated domains.
+ (void)setAssociatedDomains:(NSArray<NSString *> *_Nonnull)domains NS_AVAILABLE_IOS(8_0);

@end

/// BatchDeeplinkDelegate is the protocol to adopt when you want to set a deeplink delegate on the SDK.
///
/// See ``Batch/Batch/deeplinkDelegate``  for more info.
@protocol BatchDeeplinkDelegate <NSObject>

/// Method called when Batch needs to open a deeplink.
///
/// This will be called on the main thread.
/// - Parameter deeplink: deeplink url to open.
- (void)openBatchDeeplink:(nonnull NSString *)deeplink;

@end
