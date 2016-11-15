//
//  BatchMessaging.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BatchActions.h"

/*!
 Represents a Batch Messaging message
 */
@interface BatchMessage : NSObject <BatchUserActionSource>

@end

/*!
 Represents a Batch Messaging message coming from a push
 */
@interface BatchPushMessage : BatchMessage

@property (nonnull, readonly) NSDictionary<NSString*, NSObject*>* pushPayload;

@end

/**
 Implement this protocol if you want to be notified of what happens to the messaging view (for example, perform some analytics on show/hide).
 You're also required to implement this if you want to add actions with a "callback" type (as opposed to deeplinks)
 */
@protocol BatchMessagingDelegate <NSObject>

@optional

/**
 Called when the message view appeared on screen.
 @param messageIdentifier Analytics message identifier string. Can be nil.
 */
- (void)batchMessageDidAppear:(NSString* _Nullable)messageIdentifier;

/**
 Called when the message view disappeared from the screen.
 @param messageIdentifier Analytics message identifier string. Can be nil.
 */
- (void)batchMessageDidDisappear:(NSString* _Nullable)messageIdentifier;

@end

/*!
 @class BatchMessaging
 @abstract Batch's messaging module
 @availability from iOS 7.0
 */
@interface BatchMessaging : NSObject

/**
 Sets Batch's messaging delegate. The delegate is used for optionaly informing your code about analytics event, and is required to implement custom actions.
 @param delegate Your messaging delegate, weakly retained. Set it to nil to remove it.
 */
+ (void)setDelegate:(id<BatchMessagingDelegate> _Nullable)delegate;

/**
 Toggles whether Batch should change the shared AVAudioSession configuration by itelf. It is used to avoid stopping the user's music when displaying a video inapp, but this may have undesirable effects on your app.
 @param canReconfigureAVAudioSession Whether or not Batch can change the AVAudioSession.
 */
+ (void)setCanReconfigureAVAudioSession:(BOOL)canReconfigureAVAudioSession;

/**
 Toggles whether Batch should display the messaging views automatically.
 Note that if automatic mode is enabled, manual integration methods will not work.
 
 @param setAutomaticMode Whether to enable automatic mode or not
 */
+ (void)setAutomaticMode:(BOOL)setAutomaticMode;

/**
 Override the font used in message views.
 Not applicable for standard alerts.
 
 @param font UIFont to use for normal text. Use 'nil' to revert to the system font.
 @param boldFont UIFont to use for bold text. Use 'nil' to revert to the system font.
 */
+ (void)setFontOverride:(nullable UIFont*)font boldFont:(nullable UIFont*)boldFont;

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
 
 Do not make assumptions about the return UIViewController subclass as it can change in a future release.
 
 @warning This method should only be called on the UI thread
 
 @param message The notification's payload. Typically the verbatim userData dictionary given to you in the app delegate.
 @param error If there is an error creating the view controller, upon return contains an NSError object that describes the problem.
 @return The view controller you should modally present. nil if an error occurred.
 */
+ (UIViewController* _Nullable)loadViewControllerForMessage:(BatchMessage* _Nonnull)message
                                                      error:(NSError * _Nullable * _Nullable)error;

@end

/*!
 @enum BatchMessagingError
 @abstract BatchMessaging error code constants.
 */
enum
{
    /*!
     The current iOS version is too old
     */
    BatchMessagingErrorIncompatibleIOSVersion = -1001,
    
    /*!
     Automatic mode hasn't been disabled
     */
    BatchMessagingErrorAutomaticModeNotDisabled = -1002,
    
    /*!
     Internal error
     */
    BatchMessagingErrorInternal = -1003,
    
    /*!
     No valid Batch message found
     */
    BatchMessagingErrorNoValidBatchMessage = -1004,
    
    /*!
     The method was called from the wrong thread
     */
    BatchMessagingErrorNotOnMainThread = -1005
};
/*!
 @typedef BatchMessagingError
 */
typedef NSInteger BatchMessagingError;
