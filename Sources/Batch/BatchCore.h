//
//  BatchCore.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Batch/BatchDataCollectionConfig.h>
#import <Batch/BatchLogger.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol BatchDeeplinkDelegate;

typedef NS_ENUM(NSUInteger, BatchOptOutNetworkErrorPolicy) {

    /// Ignore the error and proceed with the opt-out.
    BatchOptOutNetworkErrorPolicyIgnore,

    /// Cancel the opt-out: please call the opt-out method again to retry.
    BatchOptOutNetworkErrorPolicyCancel,
};

/// Batch migrations types
typedef NS_OPTIONS(NSUInteger, BatchMigration) {
    /// No migrations disabled
    BatchMigrationNone = 0,

    /// Whether Bath should automatically identify logged-in user when running the SDK v2 for the first time.
    /// This mean user with a custom_user_id will be automatically attached a to a Profile and can be targeted within a
    /// Project scope.
    BatchMigrationCustomID = 1 << 0,

    /// Whether Bath should automatically attach current installation's data (language/region/customDataAttributes...)
    /// to the User's Profile when running the SDK v2 for the first time.
    BatchMigrationCustomData = 1 << 1,
};

/// Batch's main entry point.
@interface BatchSDK : NSObject

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
/// You should synchronously call this method in `application:didFinishLaunchingWithOptions:` of your
/// `UIApplicationDelegate`
///
/// - Note: This is the method that triggers the hooking or your Application to automatically handle some lifecycle
/// events. If you run into issues, you can try moving this method before other SDK initializations, or call
/// ``Batch/BatchPush/disableAutomaticIntegration`` before this method, and follow the "Manual Integration" advanced.
/// - Parameters:
///    - key: Your APP's API Key, LIVE or DEV. You can find it on your dashboard.
+ (void)startWithAPIKey:(NSString *_Nonnull)key NS_SWIFT_UI_ACTOR;

/// Set if Batch should send its logs to a custom object of yours.
///
/// - Important: Be careful with your implementation: setting this can impact stability and performance. You should only
/// use it if you know what you are doing.
/// - Parameter loggerDelegate: An object implementing ``Batch/BatchLoggerDelegate``. Weakly retained.
@property (class, nullable) id<BatchLoggerDelegate> loggerDelegate;

/// Get the debug view controller.
///
/// For development purposes only, this contains UI with multiple debug features allowing you to debug your Batch
/// implementation more easily. If you want to make it accessible in production, you should hide it in a hard to
/// reproduce sequence.
/// - Note: Should be presented modally.
+ (UIViewController *_Nullable)makeDebugViewController NS_SWIFT_UI_ACTOR;

/// Toogle whether internal logs should be logged or not.
///
/// If you have a ``Batch/BatchLoggerDelegate``, please be careful: the internal logs are quite verbose.
/// Your logger delegate method might be called often, make sure it is performent enough and has a memory allocation
/// limit.
/// This can also be controlled using `-BatchSDKEnableInternalLogs`.
/// - Parameter enableInternalLogs: Whether to enable development logs. Default: false (unless enabled via CLI).
+ (void)setInternalLogsEnabled:(BOOL)enableInternalLogs;

/// Configure the SDK Automatic Data Collection.
///
/// - Parameter editor: A block that will be called with an instance of the automatic data collection configuration as a
/// parameter. Modify the instance of the config to fine-tune the data you authorize to be tracked by Batch.
/// - Note: Batch will persist the changes, so you can call this method at any time according to user consent.
///  ```swift
/// Batch.updateAutomaticDataCollection { config in
///     config.setGeoIPEnabled(false) // Deny Batch from resolving the user's region from the ip address.
///     config.setDeviceModelEnabled(true) // Authorize Batch to use the user's device model information.
/// }
/// ```
+ (void)updateAutomaticDataCollection:(_Nonnull BatchDataCollectionConfigEditor)editor;

/// Opt-out from Batch SDK usage.
///
/// - Important: Calling this method when Batch hasn't started does nothing: Please call
/// ``Batch/BatchSDK/startWithAPIKey:`` beforehand.
///
/// A push opt-out command will be sent to Batch's servers if the user is connected to the internet.
/// If disconnected, notifications might not be disabled properly. Please use
/// ``Batch/BatchSDK/optOutWithCompletionHandler:``  to handle these cases more gracefully.
///
/// Your app should be prepared to handle these cases. Some modules might behave unexpectedly when the SDK is opted out
/// from.
///
/// Opting out will:
/// - Prevent ``Batch/BatchSDK/startWithAPIKey:``  from starting the SDK
/// - Disable any network capability from the SDK
/// - Disable all In-App campaigns
/// - Make the Inbox module return an error immediatly
/// - Make any call to ``Batch/BatchUserDataEditor/save``  do nothing
/// - Make any `track` methods from ``BatchUser`` ineffective
///
/// Even if you opt-in afterwards, data generated (such as user data or tracked events) while opted out __WILL__ be
/// lost.
///
/// If you also want to delete user data, please see ``Batch/BatchSDK/optOutAndWipeData``.
+ (void)optOut;

/// Opt-out from Batch SDK and wipe data.
///
/// - Important: Calling this method when Batch hasn't started does nothing: Please call
/// ``Batch/BatchSDK/startWithAPIKey:`` beforehand test.
///
/// An installation data wipe command will be sent to Batch's servers if the user is connected to the internet.
/// If disconnected, notifications might not be disabled properly. Please use
/// ``Batch/BatchSDK/optOutAndWipeDataWithCompletionHandler:`` to handle these cases more gracefully.
///
/// See ``Batch/BatchSDK/optOut`` documentation for details.
///
/// - Note: Once opted out, ``Batch/BatchSDK/startWithAPIKey:`` will essentially be a no-op. Your app should be prepared
/// to handle these cases.
+ (void)optOutAndWipeData;

/// Opt-out from Batch SDK.
///
/// - Important: Calling this method when Batch hasn't started does nothing: Please call
/// ``Batch/BatchSDK/startWithAPIKey:`` beforehand test.
///
/// See ``Batch/BatchSDK/optOut`` documentation for details.
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
/// ``Batch/BatchSDK/startWithAPIKey:`` beforehand test.
///
/// See ``Batch/BatchSDK/optOut`` documentation for details.
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
/// Useful if you called ``Batch/BatchSDK/optOut``, ``Batch/BatchSDK/optOutAndWipeData`` or opted out by default in your
/// Info.plist.
/// - Important: You will need to call ``Batch/BatchSDK/startWithAPIKey:`` after this.
+ (void)optIn;

/// Returns whether Batch has been opted out from or not
@property (readonly, class) BOOL isOptedOut;

/// Set your list of associated domains, If your app handle universal links.
///
/// If your site uses multiple subdomains (such as example.com, www.example.com, or support.example.com), each requires
/// its own entry like in the `Associated Domains Entitlement`file.
///
/// - Important: Make sure to only include the desired subdomain and the top-level domain. Don’t include path and query
/// components or a trailing slash (/).
/// - Parameter domains: An array of your supported associated domains.
@property (class, nonnull) NSArray<NSString *> *associatedDomains;

/// Set data migrations you want to disable.
///
/// - Important: Make sure to call this method before ``Batch/BatchSDK/startWithAPIKey:``.
/// - Parameter migrations: migrations to disable
///
/// ## Examples:
/// ```swift
///     /// Swift
///     /// Disabling custom ID and Data migrations
///     BatchSDK.setDisabledMigrations([.customID, .customData])
/// ```
/// ```objc
///     /// Objective-C
///     /// Disabling custom ID and Data migrations
///     [BatchSDK setDisabledMigrations: BatchMigrationCustomID | BatchMigrationCustomData];
/// ```
+ (void)setDisabledMigrations:(BatchMigration)migrations;

@end

/// BatchDeeplinkDelegate is the protocol to adopt when you want to set a deeplink delegate on the SDK.
///
/// See ``Batch/BatchSDK/deeplinkDelegate``  for more info.
@protocol BatchDeeplinkDelegate <NSObject>

/// Method called when Batch needs to open a deeplink.
///
/// This will be called on the main thread.
/// - Parameter deeplink: deeplink url to open.
- (void)openBatchDeeplink:(nonnull NSString *)deeplink;

@end
