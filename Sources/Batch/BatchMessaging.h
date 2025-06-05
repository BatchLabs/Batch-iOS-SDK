//
//  BatchMessaging.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BatchActions.h>
#import <Batch/BatchMessagingCloseReason.h>

@class BatchInAppMessage, BatchMessage, BatchPushMessage, BatchMessageAction;

@protocol BatchInAppDelegate <NSObject>

@optional

/// Called when an In-App message should be presented to the user.
///
/// - Parameter message: In-App message to show.
- (void)batchInAppMessageReady:(BatchInAppMessage *_Nonnull)message NS_SWIFT_NAME(batchInAppMessageReady(message:));

@end

/// Implement this protocol if you want to be notified of what happens to the messaging view (for example, perform some
/// analytics on show/hide).
@protocol BatchMessagingDelegate <NSObject>

@optional

/// Called when the message view appeared on screen.
///
/// - Parameter messageIdentifier: Analytics message identifier string. Can be nil.
- (void)batchMessageDidAppear:(NSString *_Nullable)messageIdentifier;

/// Called when Batch needs to present a message in automatic mode.
///
/// Implement this method if you need to specify the view controller that will present Batch content.
/// If you return nil, or don't implement this method, Batch will default to its normal presentation behaviour and use
/// the topmost presented controller of your app's key window's root controller.
/// - Note:This method will not be called for some messages that need to be presented in their own window.
/// - Returns: The view controller to present Batch content on. Batch will display its controller modally, therefore the
/// view
///   controller you return must be capable of presenting a modal view controller.
- (UIViewController *_Nullable)presentingViewControllerForBatchUI;

/// Called when the message view will be dismissed due to the user pressing a CTA or the global tap action.
///
/// - Parameters:
///   - action: Action that will be performed. Fields can be nil if the action was only to dismiss the message on tap.
///     __DO NOT__ run the action yourself: the SDK will automatically do it.
///   - identifier: Analytics message identifier string. Can be nil.
///   - ctaIdentifier: Identifier of the action/CTA. If the action comes from the "global tap action", the identifier
///     will be ``BatchMessageGlobalActionIndex``,
///     you can cast the action to ``BatchMessageCTA``
- (void)batchMessageDidTriggerAction:(BatchMessageAction *_Nonnull)action
                   messageIdentifier:(NSString *_Nullable)identifier
                       ctaIdentifier:(NSString *_Nonnull)ctaIdentifier;

/// Called when the message view disappeared from the screen.
///
/// - Parameters:
///  - messageIdentifier: Analytics message identifier string. Can be nil.
///  - reason: Enum for the different reasons why an In-App message can be closed
- (void)batchMessageDidDisappear:(NSString *_Nullable)messageIdentifier reason:(BatchMessagingCloseReason)reason;

@end

/// Batch's messaging module
@interface BatchMessaging : NSObject

/// Sets Batch's messaging delegate. The delegate is used for optionaly informing your code about analytics event, or
/// handling In-App messages manually.
@property (class, nullable) id<BatchMessagingDelegate> delegate;

/// Sets Batch's In-App delegate. The delegate is used for handling In-App messages manually
@property (class, nullable) id<BatchInAppDelegate> inAppDelegate;

/// Toggles whether Batch should change the shared `AVAudioSession` configuration by itelf.
///
/// It is used to avoid stopping the user's music when displaying a video inapp,
/// but this may have undesirable effects on your app.
@property (class) BOOL canReconfigureAVAudioSession;

/// Toggles whether Batch should display the messaging views automatically when coming from a notification.
/// Default: true
///
/// In-App messaging is not affected by this. If you want to manually display the In-App message, call
/// ``BatchMessaging/setDelegate:`` with a delegate that implement
/// ``BatchInAppDelegate/batchInAppMessageReady:``.
/// - Note: If automatic mode is enabled, manual integration methods will not work.
@property (class) BOOL automaticMode;

/// Toogles whether BatchMessaging should enter its "do not disturb" (DnD) mode or exit it.
///
/// While in DnD, Batch will not display landings, not matter if they've been triggered by notifications or an In-App
/// Campaign, even in automatic mode.
///
/// This mode is useful for times where you don't want Batch to interrupt your user, such as during a splashscreen, a
/// video or an interstitial ad.
///
/// If a message should have been displayed during DnD, Batch will enqueue it, overwriting any previously enqueued
/// message. When exiting DnD, Batch will not display the message automatically: you'll have to call the queue
/// management methods to display the message, if you want to.
///
/// See ``BatchMessaging/hasPendingMessage`` ``BatchMessaging/popPendingMessage`` or
/// ``BatchMessaging/showPendingMessage`` to manage enqueued messages.
///
/// - Note: This is only supported if automatic mode is enabled. Messages will not be enqueued, as they will be
/// delivered to your delegate.
@property (class, nonatomic) BOOL doNotDisturb;

/// Returns whether Batch has an enqueued message from "do not disturb" mode.
@property (class, readonly) BOOL hasPendingMessage;

/// Gets the pending message (if any), enqueued while Batch was (or still is) in "do not disturb" mode.
///
/// - Note: Calling this will remove the pending message from Batch's queue: subsequent calls will return nil until a
/// new message has been enqueued.
/// - Returns: A ``BatchMessage`` instance if there was a pending message.
+ (BatchMessage *_Nullable)popPendingMessage;

/// Shows the currently enqueued message, if any.
///
/// Removes the pending message from the queue (like if ``BatchMessaging/popPendingMessage`` was called).
/// - Returns: True if there was an enqueued message to show, false otherwise. Is a message was enqueued but failed to
/// display, the return value will be true.
+ (BOOL)showPendingMessage;

/// Override the font used in message views.
///
/// Not applicable for standard alerts.
/// If a variant is missing but there is a base font present, the SDK will fallback on the base fond you provided rather
/// than the system one. This can lead to missing styles. Setting a nil base font override will disable all other
/// overrides.
/// - Parameters:
///   - font: UIFont to use for normal text. Use 'nil' to revert to the system font.
///   - boldFont: UIFont to use for bold text. Use 'nil' to revert to the system font.
+ (void)setFontOverride:(nullable UIFont *)font boldFont:(nullable UIFont *)boldFont;

/// Override the font used in message views.
///
/// Not applicable for standard alerts.
/// If a variant is missing but there is a base font present, the SDK will fallback on the base fond you provided rather
/// than the system one. This can lead to missing styles. Setting a nil base font override will disable all other
/// overrides.
/// - Parameters:
///   - font: UIFont to use for normal text. Use 'nil' to revert to the system font.
///   - boldFont: UIFont to use for bold text. Use 'nil' to revert to the system font.
///   - italicFont: UIFont to use for italic text. Use 'nil' to revert to the system font.
///   - boldItalicFont: UIFont to use for bolditalic text. Use 'nil' to revert to the system font.
+ (void)setFontOverride:(nullable UIFont *)font
               boldFont:(nullable UIFont *)boldFont
             italicFont:(nullable UIFont *)italicFont
         boldItalicFont:(nullable UIFont *)boldItalicFont;

/// Toggles whether Batch should use dynamic type, adapting textual content to honor the user's font size settings.
///
/// - Parameter enableDynamicType: Whether to enable dynamic type. (default = true).
+ (void)setEnableDynamicType:(BOOL)enableDynamicType;

/// Get a message model from the push payload, if it contains a valid Batch message.
///
/// - Note: This does not guarantee that there's a fully valid message in it, but it allows you to bail early and skip
/// unnecessary work if there's nothing messaging-related in the payload.
/// - Parameter userData: The notification's payload. Typically the verbatim `userData` dictionary given to you in the
/// app delegate.
/// - Returns: A ``BatchPushMessage`` instance if a messaging payload was found. nil otherwise.
+ (nullable BatchPushMessage *)messageFromPushPayload:(nonnull NSDictionary *)userData;

/// Try to load a messaging view controller for a given payload.
///
/// Do not make assumptions about the returned UIViewController subclass as it can change in a future release.
///
/// You can then display this view controller modally, or in a dedicated window. The view controller conforms to the
/// ``BatchMessagingViewController`` protocol, you can call "shouldDisplayInSeparateWindow" to know how this VC would
/// like to be presented.
///
/// You can also use ``BatchMessaging/presentMessagingViewController:`` to tell Batch to try to display it itself.
///
/// - Parameters:
///   - message: The notification's payload. Typically the verbatim userData dictionary given to you in the app
///   delegate.
///   - error: If there is an error creating the view controller, upon return contains an NSError object that describes
///     the problem.
/// - Returns: The view controller you should present. nil if an error occurred.
+ (UIViewController *_Nullable)loadViewControllerForMessage:(BatchMessage *_Nonnull)message
                                                      error:(NSError *_Nullable *_Nullable)error;

/// Try to automatically present the given Batch Messaging View Controller, in the most appropriate way.
///
///  This method will do nothing if you don't give it a `UIViewController` loaded by
///  ``BatchMessaging/loadViewControllerForMessage:error:``
/// - Parameter vc: The ViewController to present.
+ (void)presentMessagingViewController:(nonnull UIViewController *)vc;

@end

/// BatchMessaging error code constants.
typedef NS_ENUM(NSInteger, BatchMessagingError) {

    /// The current iOS version is too old
    BatchMessagingErrorIncompatibleIOSVersion = -1001,

    /// Automatic mode hasn't been disabled
    BatchMessagingErrorAutomaticModeNotDisabled = -1002,

    /// Internal error
    BatchMessagingErrorInternal = -1003,

    /// No valid Batch message found
    BatchMessagingErrorNoValidBatchMessage = -1004,

    /// The method was called from the wrong thread
    BatchMessagingErrorNotOnMainThread = -1005,

    /// Could not find a VC to display the landing on
    BatchMessagingErrorNoSuitableVCForDisplay = -1006,

    /// Batch is opted-out from
    BatchMessagingErrorOptedOut = -1007
};
