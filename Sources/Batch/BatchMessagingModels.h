//
//  BatchMessagingModels.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2019 Batch SDK. All rights reserved.
//

FOUNDATION_EXPORT NSString *_Nonnull const BatchMessageGlobalActionIndex;

typedef NS_ENUM(NSUInteger, BatchMessagingContentType) {

    /// The message is invalid and does not contain any displayable message,
    /// or that the format is unknown to this version of the SDK, and might be available in a newer one.
    BatchMessagingContentTypeUnknown,

    /// A simple system alert.
    /// Corresponding content class is BatchAlertMessageContent.
    BatchMessagingContentTypeAlert,

    /// A fullscreen format.
    /// Corresponding content class is BatchInterstitialMessageContent.
    BatchMessagingContentTypeInterstitial,

    /// A banner that can be attached on top or bottom of your screen.
    /// Corresponding content class is BatchBannerMessageContent.
    BatchMessagingContentTypeBanner,

    /// A popup that takes over the screen modally, like a system alert but with a custom style.
    /// Corresponding content class is BatchMessageModalContent.
    BatchMessagingContentTypeModal,

    /// A modal popup that simply shows an image in an alert (detached) or fullscreen (attached) style.
    /// Corresponding content class is BatchMessageImageContent.
    BatchMessagingContentTypeImage,

    /// A fullscreen WKWebView that shows a remote URL.
    /// Corresponding content class is BatchMessageWebViewContent.
    BatchMessagingContentTypeWebView
};

/// Represents an In-App Message content
///
/// This protocol itself isn't really useful: you will need to safely cast it to an instance, such as
/// ``BatchInterstitialMessageContent`` or ``BatchAlertMessageContent``
@protocol BatchInAppMessageContent <NSObject>

@end

/// Model describing an alert message's CTA
@interface BatchAlertMessageCTA : NSObject

@property (nullable, readonly) NSString *label;
@property (nullable, readonly) NSString *action;
@property (nullable, readonly) NSDictionary *args;

@end

/// Model describing the content of an alert message
@interface BatchAlertMessageContent : NSObject <BatchInAppMessageContent>

@property (nullable, readonly) NSString *trackingIdentifier;
@property (nullable, readonly) NSString *title;
@property (nullable, readonly) NSString *body;
@property (nullable, readonly) NSString *cancelLabel;
@property (nullable, readonly) BatchAlertMessageCTA *acceptCTA;

@end

/// Model describing an interstitial message's CTA
@interface BatchInterstitialMessageCTA : NSObject

@property (nullable, readonly) NSString *label;
@property (nullable, readonly) NSString *action;
@property (nullable, readonly) NSDictionary *args;

@end

/// Model describing the content of an interstitial message
@interface BatchInterstitialMessageContent : NSObject <BatchInAppMessageContent>

@property (nullable, readonly) NSString *trackingIdentifier;
@property (nullable, readonly) NSString *header;
@property (nullable, readonly) NSString *title;
@property (nullable, readonly) NSString *body;
@property (nullable, readonly) NSArray<BatchInterstitialMessageCTA *> *ctas;
@property (nullable, readonly) NSString *mediaURL;
@property (nullable, readonly) NSString *mediaAccessibilityDescription;
@property (readonly) BOOL showCloseButton;

@end

@interface BatchMessageAction : NSObject

@property (nullable, readonly) NSString *action;
@property (nullable, readonly) NSDictionary<NSString *, id> *args;

- (BOOL)isDismissAction;

@end

@interface BatchMessageCTA : BatchMessageAction

@property (readonly, nullable) NSString *label;

@end

/// Model describing a banner message's global tap action
@interface BatchBannerMessageAction : BatchMessageAction
@end

/// Model describing an image message's global tap action
@interface BatchImageMessageAction : BatchMessageAction
@end

/// Model describing a banner message's CTA
@interface BatchBannerMessageCTA : NSObject

@property (nullable, readonly) NSString *label;
@property (nullable, readonly) NSString *action;
@property (nullable, readonly) NSDictionary *args;

@end

/// Model describing the content of a banner message
@interface BatchBannerMessageContent : NSObject <BatchInAppMessageContent>

@property (nullable, readonly) NSString *trackingIdentifier;
@property (nullable, readonly) NSString *title;
@property (nullable, readonly) NSString *body;
@property (nullable, readonly) NSArray<BatchBannerMessageCTA *> *ctas;
@property (nullable, readonly) BatchBannerMessageAction *globalTapAction;
@property (nullable, readonly) NSString *mediaURL;
@property (nullable, readonly) NSString *mediaAccessibilityDescription;
@property (readonly) BOOL showCloseButton;

/// Expressed in seconds, 0 if should not automatically dismiss
@property (readonly) NSTimeInterval automaticallyDismissAfter;

@end

/// Model describing the content of an image message
@interface BatchMessageImageContent : NSObject <BatchInAppMessageContent>

@property CGSize imageSize;
@property (nullable) NSString *imageURL;
@property NSTimeInterval globalTapDelay;
@property (nonnull) BatchImageMessageAction *globalTapAction;
@property BOOL isFullscreen;
@property (nullable) NSString *imageDescription;
@property NSTimeInterval autoClose;
@property BOOL allowSwipeToDismiss;

@end

/// Model describing the content of a modal message
@interface BatchMessageModalContent : NSObject <BatchInAppMessageContent>

@property (nullable, readonly) NSString *trackingIdentifier;
@property (nullable, readonly) NSString *title;
@property (nullable, readonly) NSString *body;
@property (nullable, readonly) NSArray<BatchBannerMessageCTA *> *ctas;
@property (nullable, readonly) BatchBannerMessageAction *globalTapAction;
@property (nullable, readonly) NSString *mediaURL;
@property (nullable, readonly) NSString *mediaAccessibilityDescription;
@property (readonly) BOOL showCloseButton;

/// Expressed in seconds, 0 if should not automatically dismiss
@property (readonly) NSTimeInterval automaticallyDismissAfter;

@end

/// Model describing the content of a webview message
@interface BatchMessageWebViewContent : NSObject <BatchInAppMessageContent>

@property (nullable, readonly) NSURL *URL;
@property (nullable, readonly) NSString *trackingIdentifier;

@end

/// Protocol representing a Batch Messaging VC.
@protocol BatchMessagingViewController <NSObject>

@property (readonly) BOOL shouldDisplayInSeparateWindow;

@end

/// Represents a Batch Messaging message
@interface BatchMessage : NSObject <NSCopying, BatchUserActionSource>

@end

/// Represents a Batch Messaging message coming from an In-App Campaign
@interface BatchInAppMessage : BatchMessage

/// User defined custom payload
@property (nullable, readonly) NSDictionary<NSString *, NSObject *> *customPayload;

/// In-App message's visual contents
///
/// Since the content can greatly change between formats, you will need to cast it to one of the classes
/// conforming to the ``BatchInAppMessageContent`` protocol, such as ``BatchAlertMessageContent`` or
/// ``BatchInterstitialMessageContent``.
///
/// Use `-contentType` to help you in that task.
///
/// More types might be added in the future, so don't make any assuptions on the kind of class returned by this
/// property.
///
/// Can be nil if an error occurred or if not applicable
/// This method will return null and `contentType` property will return `BatchMessagingContentTypeUnknown` for messages
/// coming from the CEP (Customer Engagement Platform).
@property (nullable, readonly) id<BatchInAppMessageContent> mepContent;

/// Get the campaign token. This is the same token as you see when opening the In-App Campaign in your browser, when on
/// the dashboard. Can be nil.
@property (nullable, readonly) NSString *campaignToken;

/// The type of the content, used to cast to the right content class.
@property (readonly) BatchMessagingContentType contentType;

@end

/// Represents a Batch Messaging message coming from a push
@interface BatchPushMessage : BatchMessage

/// Original push payload
@property (nonnull, readonly) NSDictionary<NSString *, NSObject *> *pushPayload;

/// Property indicating whether this landing message has been triggered from an inbox notification.
@property (readonly) BOOL isDisplayedFromInbox;

@end
