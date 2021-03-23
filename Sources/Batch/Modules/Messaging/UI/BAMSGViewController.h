//
//  BAMSGViewController.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BAMSGCloseButton.h>
#import <Batch/BAPromise.h>
#import <Batch/BAMessagingAnalyticsDelegate.h>

@class BACSSDocument, BACSSDOMNode, BAMSGMessage, BAMSGCTA;

@interface BAMSGViewController : UIViewController

@property (nonnull, readonly) BACSSDocument* style;
@property (nonatomic, nullable) BAMSGCloseButton *closeButton;
@property (nonatomic, readonly) UIStatusBarStyle overridenStatusBarStyle;
@property (nonatomic, nonnull, readonly) id<BAMessagingAnalyticsDelegate> messagingAnalyticsDelegate;


- (nonnull instancetype)initWithStyleRules:(nonnull BACSSDocument*)style NS_DESIGNATED_INITIALIZER;

#pragma mark - Parent
- (BAMSGMessage *_Nonnull)message;

#pragma mark - Styling
- (BACSSRules*_Nullable)rulesForNode:(BACSSDOMNode*_Nullable)node;
- (void)setupRootStyle;
- (nonnull BACSSEnvironment*)computeCSSEnvironment;
- (CGSize)computeViewSize;

#pragma mark - Dismissal
@property (nonatomic, assign, readonly) BOOL isDismissed;
/** Call to dismiss the controller.*/
- (nonnull BAPromise*)dismiss;
/** The default implementation of this method does nothing. Must be overriden to do the actual dismiss action. */
- (nonnull BAPromise*)doDismiss;
/** Dismiss only if we're a modal AND not under another one. For subclass use only.*/
- (nonnull BAPromise*)_doDismissSelfModal;
- (void)closeButtonAction;

/**
 Call this method to track when the user asked to close the message
 isDismissed will be set to true
 Actually triggering the dismissal, if not already done, is your responsibility
 
 This is useful for iOS 13's swipe to dismiss.
 */
- (void)userDidCloseMessage;

#pragma mark - CTA

@property (nullable) NSArray<BAMSGCTA*>* ctas;

/// Perform CTA at the specified index. This will also dismiss the message.
- (void)performCtaAtIndex:(NSInteger)index;

#pragma mark - Autoclosing
@property (nonatomic, assign, readonly) NSTimeInterval autoclosingDuration;
@property (nonatomic, assign, readonly) BOOL showCloseButton;
/**
 Setup the closing behaviour of the view (close button y/n, and whether the message should auto close after a delay)
 
 These settings might be overriden for accessibility purposes
 
 Set autoclosingDuration to 0 to disable autoclose
 */
- (void)setCloseButtonEnabled:(BOOL)showCloseButton autoclosingDuration:(NSTimeInterval)autoclosingDuration;

/** Override to set up autoclosing UI elements before animation takes place. Default implementation strokes the close button. */
- (void)setupAutoclosing;
/** Default to true. Override and return NO if countdown should wait for a condition, e.g. some initial loading to finish. */
- (BOOL)automaticAutoclosingCountdown;
/** Manually start the autoclosing coundown. */
- (void)startAutoclosingCountdown;
/** Override to handle the animation your way. Default implementation configures the close button (if not nil) for animation. */
- (void)doAnimateAutoclosing;
- (NSTimeInterval)autoclosingRemainingTime;

@end
