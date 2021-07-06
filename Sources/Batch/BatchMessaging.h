//
//  BatchMessaging.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BatchActions.h>

@class BatchInAppMessage, BatchMessage, BatchPushMessage, BatchMessageAction;

/**
 Implement this protocol if you want to be notified of what happens to the messaging view (for example, perform some analytics on show/hide).
 */
@protocol BatchMessagingDelegate <NSObject>

@optional

/**
 Called when the message view appeared on screen.
 @param messageIdentifier Analytics message identifier string. Can be nil.
 */
- (void)batchMessageDidAppear:(NSString* _Nullable)messageIdentifier;

/**
 Called when the message view was dismissed by a user interaction (close button tap, swipe gesture...)
 @param messageIdentifier Analytics message identifier string. Can be nil.
 */
- (void)batchMessageWasCancelledByUserAction:(NSString* _Nullable)messageIdentifier NS_SWIFT_NAME(batchMessageWasCancelledByUserAction(_:));

/**
 Called when the message view was dismissed automatically after the auto closing countdown.
 @param messageIdentifier Analytics message identifier string. Can be nil.
 */
- (void)batchMessageWasCancelledByAutoclose:(NSString* _Nullable)messageIdentifier NS_SWIFT_NAME(batchMessageWasCancelledByAutoclose(_:));

/**
 Called when Batch needs to present a message in automatic mode.

 Implement this method if you need to specify the view controller that will present Batch content.
 If you return nil, or don't implement this method, Batch will default to its normal presentation behaviour and use the topmost presented controller of your app's key window's root controller.
 @return The view controller to present Batch content on. Batch will display its controller modally, therefore the view controller you return must be capable of presenting a modal view controller.
 @note This method will not be called for some messages that need to be presented in their own window.
 */
- (UIViewController* _Nullable)presentingViewControllerForBatchUI;

/**
 Called when the message view will be dismissed due to the user pressing a CTA or the global tap action.
 @param action        Action that will be performed. Fields can be nil if the action was only to dismiss the message on tap.
                      DO NOT run the action yourself: the SDK will automatically do it.
 @param index         Index of the action/CTA. If the action comes from the "global tap action", the index will be BatchMessageGlobalActionIndex
                      If the index is greater than or equal to zero, you can cast the action to BatchMessageCTA to get the CTA's label.
 @param identifier    Analytics message identifier string. Can be nil.
 */
- (void)batchMessageDidTriggerAction:(BatchMessageAction * _Nonnull)action messageIdentifier:(NSString * _Nullable)identifier actionIndex:(NSInteger)index;

/**
 Called when the message view disappeared from the screen.
 @param messageIdentifier Analytics message identifier string. Can be nil.
 */
- (void)batchMessageDidDisappear:(NSString* _Nullable)messageIdentifier;

/**
 Called when an In-App message should be presented to the user.

 @param message In-App message to show.
 */
- (void)batchInAppMessageReady:(nonnull BatchInAppMessage*)message NS_SWIFT_NAME(batchInAppMessageReady(message:));

/**
 Called when the message view was closed because of an error
 @param messageIdentifier Analytics message identifier string. Can be nil.
 */
- (void)batchMessageWasCancelledByError:(NSString* _Nullable)messageIdentifier NS_SWIFT_NAME(batchMessageWasCancelledByError(_:));

/**
 Called when the WebView message view will be dismissed due to the user navigating away or triggering an action (using the Javascript SDK).
 @param action        Action that will be performed. Fields can be nil if the action was only to dismiss the message on tap.
                      DO NOT run the action yourself: the SDK will automatically do it. Can be nil.
 @param messageIdentifier    Analytics message identifier string. Can be nil.
 @param analyticsIdentifier Click analytic identifier. Matches the "analyticsID" parameter of the Javascript call,
 *                          or the 'batchAnalyticsID' query parameter of a link.
 */
- (void)batchWebViewMessageDidTriggerAction:(BatchMessageAction * _Nullable)action
                          messageIdentifier:(NSString * _Nullable)messageIdentifier
                        analyticsIdentifier:(NSString * _Nullable)analyticsIdentifier;

@end

/**
 Batch's messaging module
 */
@interface BatchMessaging : NSObject

/**
 Sets Batch's messaging delegate. The delegate is used for optionaly informing your code about analytics event, or handling In-App messages manually.
 
 
 @param delegate Your messaging delegate, weakly retained. Set it to nil to remove it.
 */
+ (void)setDelegate:(id<BatchMessagingDelegate> _Nullable)delegate;

/**
 Toggles whether Batch should change the shared AVAudioSession configuration by itelf. It is used to avoid stopping the user's music when displaying a video inapp, but this may have undesirable effects on your app.
 
 @param canReconfigureAVAudioSession Whether or not Batch can change the AVAudioSession.
 */
+ (void)setCanReconfigureAVAudioSession:(BOOL)canReconfigureAVAudioSession;

/**
 Toggles whether Batch should display the messaging views automatically when coming from a notification.
 Note that if automatic mode is enabled, manual integration methods will not work.
 In-App messaging is not affected by this. If you want to manually display the In-App message, call setDelegate: with a delegate that implement batchInAppMessageReady:
 
 @param isAutomaticModeOn Whether to enable automatic mode or not
 */
+ (void)setAutomaticMode:(BOOL)isAutomaticModeOn NS_SWIFT_NAME(setAutomaticMode(on:));

/**
 Toogles whether BatchMessaging should enter its "do not disturb" (DnD) mode or exit it.
 
 While in DnD, Batch will not display landings, not matter if they've been triggered by notifications or an In-App Campaign, even in automatic mode.
 
 This mode is useful for times where you don't want Batch to interrupt your user, such as during a splashscreen, a video or an interstitial ad.
 
 If a message should have been displayed during DnD, Batch will enqueue it, overwriting any previously enqueued message.
 When exiting DnD, Batch will not display the message automatically: you'll have to call the queue management methods to display the message, if you want to.
 
 See BatchMessaging.hasPendingMessage, popPendingMessage() or showPendingMessage() to manage enqueued messages.
 
 Note: This is only supported if automatic mode is enabled. Messages will not be enqueued, as they will be delivered to your delegate.
 */
@property (class, nonatomic) BOOL doNotDisturb;

/**
 Returns whether Batch has an enqueued message from "do not disturb" mode.
 */
@property (class, readonly) BOOL hasPendingMessage;

/**
 Gets the pending message (if any), enqueued while Batch was (or still is) in "do not disturb" mode.
 Note: Calling this will remove the pending message from Batch's queue: subsequent calls will return nil until a new message
 has been enqueued.
 
 @return A BatchMessage instance if there was a pending message.
 */
+ (BatchMessage* _Nullable)popPendingMessage;

/**
 Shows the currently enqueued message, if any.
 Removes the pending message from the queue (like if popPendingMessage was called).
 
 @return true if there was an enqueued message to show, false otherwise. Is a message was enqueued but failed to display, the return value will be true.
 */
+ (BOOL)showPendingMessage;

/**
 Override the font used in message views.
 Not applicable for standard alerts.
 
 If a variant is missing but there is a base font present, the SDK will fallback on the base fond you provided rather than the system one. This can lead to missing styles.
 Setting a nil base font override will disable all other overrides.
 
 @param font UIFont to use for normal text. Use 'nil' to revert to the system font.
 
 @param boldFont UIFont to use for bold text. Use 'nil' to revert to the system font.
 */
+ (void)setFontOverride:(nullable UIFont*)font boldFont:(nullable UIFont*)boldFont;

/**
 Override the font used in message views.
 Not applicable for standard alerts.
 
 If a variant is missing but there is a base font present, the SDK will fallback on the base fond you provided rather than the system one. This can lead to missing styles.
 Setting a nil base font override will disable all other overrides.
 
 @param font UIFont to use for normal text. Use 'nil' to revert to the system font.
 
 @param boldFont UIFont to use for bold text. Use 'nil' to revert to the system font.
 
 @param italicFont UIFont to use for italic text. Use 'nil' to revert to the system font.
 
 @param boldItalicFont UIFont to use for bolditalic text. Use 'nil' to revert to the system font.
 */
+ (void)setFontOverride:(nullable UIFont*)font boldFont:(nullable UIFont*)boldFont italicFont:(nullable UIFont*)italicFont boldItalicFont:(nullable UIFont*)boldItalicFont;

/*!
 Get a message model from the push payload, if it contains a valid Batch message.
 Note that this does not guarantee that there's a fully valid message in it, but
 it allows you to bail early and skip unnecessary work if there's nothing messaging-related in the payload.
 
 @param userData The notification's payload. Typically the verbatim userData dictionary given to you in the app delegate.
 
 @return A BatchPushMessage instance if a messaging payload was found. nil otherwise.
 */
+ (nullable BatchPushMessage*)messageFromPushPayload:(nonnull NSDictionary*)userData;

/**
 Try to load a messaging view controller for a given payload.
 
 Do not make assumptions about the returned UIViewController subclass as it can change in a future release.
 
 You can then display this view controller modally, or in a dedicated window. The view controller conforms to the BatchMessagingViewController
 protocol, you can call "shouldDisplayInSeparateWindow" to know how this VC would like to be presented.
 
 You can also use "presentMessagingViewController" to tell Batch to try to display it itself.
 
 @warning This method should only be called on the UI thread
 
 @param message The notification's payload. Typically the verbatim userData dictionary given to you in the app delegate.
 
 @param error If there is an error creating the view controller, upon return contains an NSError object that describes the problem.
 
 @return The view controller you should present. nil if an error occurred.
 */
+ (UIViewController* _Nullable)loadViewControllerForMessage:(BatchMessage* _Nonnull)message
                                                      error:(NSError * _Nullable * _Nullable)error;

/**
 Try to automatically present the given Batch Messaging View Controller, in the most appropriate way.
 
 This method will do nothing if you don't give it a UIViewController loaded by [BatchMessaging loadViewControllerForMessage:error:]
 */
+ (void)presentMessagingViewController:(nonnull UIViewController*)vc;

@end

/**
 BatchMessaging error code constants.
 */
enum
{
    /**
     The current iOS version is too old
     */
    BatchMessagingErrorIncompatibleIOSVersion = -1001,
    
    /**
     Automatic mode hasn't been disabled
     */
    BatchMessagingErrorAutomaticModeNotDisabled = -1002,
    
    /**
     Internal error
     */
    BatchMessagingErrorInternal = -1003,
    
    /**
     No valid Batch message found
     */
    BatchMessagingErrorNoValidBatchMessage = -1004,
    
    /**
     The method was called from the wrong thread
     */
    BatchMessagingErrorNotOnMainThread = -1005,
    
    /**
     Could not find a VC to display the landing on
     */
    BatchMessagingErrorNoSuitableVCForDisplay = -1006,
    
    /**
     Batch is opted-out from
     */
    BatchMessagingErrorOptedOut = -1007
};

/**
 @typedef BatchMessagingError
 */
typedef NSInteger BatchMessagingError;
