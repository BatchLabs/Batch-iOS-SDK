#import <UIKit/UIKit.h>
#import <Batch/BatchMessaging.h>
#import <Batch/BACSS.h>
#import <Batch/BACSSParser.h>
#import <Batch/BAMSGStackView.h>
#import <Batch/BAMSGMessage.h>
#import <Batch/BAMSGAction.h>
#import <Batch/BAMSGPannableAnchoredContainerView.h>
#import <Batch/BAMSGWindowHolder.h>
#import <Batch/BAMSGViewController.h>
#import <Batch/BatchMessagingModels.h>
#import <Batch/BAMSGOverlayWindow.h>

/**
 Handles banner display
 
 This is also the view controller used for Modal view, as they're basically a centered banner.
 Sadly, we don't have a better name for it, so we'll call it banner. Sorry.
 */
@interface BAMSGBaseBannerViewController: BAMSGViewController <BatchMessagingViewController,
BAMSGStackViewDelegate,
BAMSGPannableContainerViewDelegate,
BAMSGWindowHolder,
UIGestureRecognizerDelegate>

@property (nullable) NSString *titleText;
@property (nullable) NSString *bodyText;
@property (nullable) BAMSGHTMLText *bodyHtml;
@property            BAMSGBannerCTADirection ctaStackDirection;
@property (nullable) BAMSGAction *globalTapAction;
@property            NSTimeInterval globalTapDelay;
@property            BOOL allowSwipeToDismiss;
@property (nullable) NSString *imageURL;
@property (nullable) NSString *imageDescription;

@property (nullable, weak) BAMSGOverlayWindow *presentingWindow;
@property (nullable, weak) UIWindow *overlayedWindow;

@property (nullable) BAMSGMessageBaseBanner *messageDescription;

- (nonnull instancetype)initWithStyleRules:(nonnull BACSSDocument*)style;

- (BOOL)canBeClosed;

- (void)didDetectGlobalTap:(nullable UIGestureRecognizer*)gestureRecognizer;

@end
