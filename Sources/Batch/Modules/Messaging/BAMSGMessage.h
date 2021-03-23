//
//  BAMSGMessage.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Batch/BAMSGCTA.h>
#import <Batch/BatchMessaging.h>
#import <Batch/BATHtmlParser.h>

/**
 Represents a parsed html text
 */
@interface BAMSGHTMLText : NSObject

@property (nullable) NSArray<BATTextTransform*>* transforms;
@property (nonnull) NSString* text;

@end


// Minimal message representation
@interface BAMSGMessage : NSObject

@property (nonnull) BatchMessage *sourceMessage;
@property (nullable) NSString *bodyText;
@property (nullable) BAMSGHTMLText *bodyHtml;

@end

@interface BAMSGMessageAlert : BAMSGMessage

@property (nullable) NSString *titleText;
@property (nonnull) NSString *cancelButtonText;
@property (nullable) BAMSGCTA *acceptCTA;

@end

@interface BAMSGMessageInterstitial : BAMSGMessage

@property (nonnull)  NSString *css;
@property (nullable) NSString *headingText;
@property (nullable) NSString *titleText;
@property (nullable) NSString *subtitleText;
@property (nonnull)  NSArray<BAMSGCTA*> *ctas;
@property (nullable) NSString *videoURL;
@property (nullable) NSString *heroImageURL;
@property (nullable) UIImage *heroImage;
@property (nullable) NSString *heroDescription;
@property            BOOL showCloseButton;
@property            BOOL attachCTAsBottom;
@property            BOOL stackCTAsHorizontally;
@property            BOOL stretchCTAsHorizontally;
@property            BOOL flipHeroVertical;
@property            BOOL flipHeroHorizontal;
@property (nullable) NSNumber *heroSplitRatio;
@property            NSTimeInterval autoClose;

@end

typedef NS_ENUM(NSUInteger, BAMSGBannerCTADirection) {
    BAMSGBannerCTADirectionHorizontal,
    BAMSGBannerCTADirectionVertical,
};

@interface BAMSGMessageBaseBanner : BAMSGMessage

@property (nonnull)  NSString *css;
@property (nullable) NSString *titleText;
@property (nullable) BAMSGAction *globalTapAction;
@property            NSTimeInterval globalTapDelay;
@property            BOOL allowSwipeToDismiss;
@property (nullable) NSString *imageURL;
@property (nullable) NSString *imageDescription;
@property (nonnull)  NSArray<BAMSGCTA*> *ctas;
@property            BOOL showCloseButton;
@property            NSTimeInterval autoClose;
@property BAMSGBannerCTADirection ctaDirection;

@end


@interface BAMSGMessageBanner : BAMSGMessageBaseBanner
@end

@interface BAMSGMessageModal : BAMSGMessageBaseBanner
@end

@interface BAMSGMessageImage : BAMSGMessage
@property            CGSize imageSize;
@property (nullable) NSString *imageURL;
@property            NSTimeInterval globalTapDelay;
@property (nonnull)  BAMSGAction *globalTapAction;
@property            BOOL isFullscreen;
@property (nullable) NSString *imageDescription;
@property (nonnull)  NSString *css;
@property            NSTimeInterval autoClose;
@property            BOOL allowSwipeToDismiss;
@end

/// Controls which kind of viewport-fit=cover bug workaround is applied
typedef NS_ENUM(NSUInteger, BAMSGWebViewLayoutWorkaround) {
    BAMSGWebViewLayoutWorkaroundDoNothing = 0,
    
    /// Call setNeedsLayout at some point in the future, after displaying the web content
    BAMSGWebViewLayoutWorkaroundRelayoutPeriodically = 1,
    
    /// Read <meta> viewport and apply it natively to the scrollview
    /// Note: only supported on iOS 11+. On iOS 10, this will fallback on BAMSGWebViewLayoutWorkaroundRelayoutPeriodically.
    BAMSGWebViewLayoutWorkaroundApplyInsetsNatively = 2,
};

@interface BAMSGMessageWebView : BAMSGMessage

@property (nonnull)  NSString *css;
@property (nonnull)  NSURL *url;
@property            BOOL developmentMode;
@property            BOOL openDeeplinksInApp;
@property            NSTimeInterval timeout;
@property            BAMSGWebViewLayoutWorkaround layoutWorkaround;

@end
