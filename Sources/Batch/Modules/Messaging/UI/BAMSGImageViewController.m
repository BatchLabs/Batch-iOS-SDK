//
//  BAMSGImageViewController.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAEventDispatcherCenter.h>
#import <Batch/BAMSGCloseButton.h>
#import <Batch/BAMSGImageDownloader.h>
#import <Batch/BAMSGImageViewController.h>
#import <Batch/BAMSGMessage.h>
#import <Batch/BAMSGPannableAlertContainerView.h>
#import <Batch/BAMSGRemoteImageView.h>
#import <Batch/BAMSGViewToolbox.h>
#import <Batch/BAMessagingCenter.h>
#import <Batch/BAUptimeProvider.h>
#import <Batch/Batch-Swift.h>
#import <Batch/BatchMessagingPrivate.h>

@interface BAMSGTapControl : UIControl
@end // A simple control that dims a little upon touch
@interface BAMSGImagePresentationController : UIPresentationController
@end
@interface BAMSGSlideInAnimationController : NSObject <UIViewControllerAnimatedTransitioning>
@end
@interface BAMSGSlideOutAnimationController : NSObject <UIViewControllerAnimatedTransitioning>
@end

@interface BAMSGImageViewController () <UIViewControllerTransitioningDelegate, BAMSGPannableContainerViewDelegate>

@property (nonatomic) BAMSGRemoteImageView *imageView;
@property (nonatomic) BAMSGBaseContainerView *contentView;
@property (nonatomic) BAMSGSlideInAnimationController *slideInAnimationcontroller;
@property (nonatomic) BAMSGSlideOutAnimationController *slideOutAnimationcontroller;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) NSLayoutConstraint *enteringBottomConstraint;
@property (nonatomic) UIControl *tapControl;
@property NSTimeInterval lastViewAppearanceUptime;
@property (nonatomic) BATNotificationFeedbackGenerator *hapticFeedbackGenerator;
@property (nonatomic) NSLayoutConstraint *ratioConstraint;
@property (nonatomic) BOOL imageIsLoaded;

@end

@implementation BAMSGImageViewController

- (instancetype)initWithMessage:(BAMSGMessageImage *)message andStyle:(BACSSDocument *)style {
    self = [super initWithStyleRules:style];
    if (self) {
        _message = message;
        _slideInAnimationcontroller = [BAMSGSlideInAnimationController new];
        _slideOutAnimationcontroller = [BAMSGSlideOutAnimationController new];
        _lastViewAppearanceUptime = 0;
        _imageIsLoaded = false;

        _hapticFeedbackGenerator = [[BATNotificationFeedbackGenerator alloc] init];
        [_hapticFeedbackGenerator prepare];

        self.modalPresentationStyle = UIModalPresentationCustom;

        if (message.isFullscreen) { // fullscreen presentation uses standard cross dissolve transition
            self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        } else { // modal style uses a custom transitioning delegate
            self.transitioningDelegate = self;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];

    _backgroundView = [UIView new];
    [self.view addSubview:_backgroundView];

    BAMSGPannableAlertContainerView *pannableContainer = nil;
    if (_message.allowSwipeToDismiss) {
        pannableContainer = [BAMSGPannableAlertContainerView new];
        _contentView = pannableContainer;
        pannableContainer.delegate = self;
        pannableContainer.resetPositionOnDismiss = NO;
        if (_message.isFullscreen) {
            pannableContainer.lockVertically = NO;
        } else {
            pannableContainer.lockVertically = YES;
        }
    } else {
        _contentView = [BAMSGBaseContainerView new];
    }

    _contentView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_contentView];

    _imageView = [BAMSGRemoteImageView new];
    _imageView.enableIntrinsicContentSize = NO;
    _imageView.clipsToBounds = YES;
    _imageView.backgroundColor = [UIColor clearColor];
    _imageView.accessibilityLabel = self.message.imageDescription;
    _imageView.isAccessibilityElement = true;
    [_contentView addSubview:_imageView];

    _tapControl = [BAMSGTapControl new];
    [_tapControl addTarget:self action:@selector(imageTapped) forControlEvents:UIControlEventTouchUpInside];

    self.closeButton = [BAMSGCloseButton new];
    self.closeButton.showBorder = true;
    [self.closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    if (pannableContainer != nil) {
        [pannableContainer setLinkedView:self.closeButton];
    }

    [self.view addSubview:self.closeButton];

    if (_message.isFullscreen) { // Default values are set here but might be overriden by styling.
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }

    [self setupColors];

    [self setupConstraints];

    [self setupImageStyle];

    // Load image
    __weak BAMSGImageViewController *weakSelf = self;
    [_imageView setImageURL:[NSURL URLWithString:self.message.imageURL]
                 completion:^(UIImage *image, NSError *error) {
                   if (!weakSelf) {
                       return;
                   }
                   BAMSGImageViewController *strongSelf = weakSelf;

                   if (error != nil) { // On error, dismiss the controller
                       if (strongSelf) {
                           [weakSelf.messagingAnalyticsDelegate
                                     message:strongSelf.message
                               closedByError:[BATMessagingCloseErrorHelper guessErrorCauseForError:error]];
                       }
                       [weakSelf dismiss];
                   } else {
                       BAMSGImageViewController *strongSelf = weakSelf;
                       if (strongSelf) {
                           strongSelf->_imageIsLoaded = true;
                           if (weakSelf.view.window != nil) { // Start countdown only after viewDidAppear
                               [weakSelf startAutoclosingCountdown];
                           }
                       }

                       if (CGSizeEqualToSize(weakSelf.message.imageSize, CGSizeZero) &&
                           !weakSelf.message.isFullscreen) { // Image ratio was unknown at display time.
                           // We can update the actual presentation ratio.
                           CGFloat actualRatio = image.size.height / image.size.width;
                           if (weakSelf.ratioConstraint.multiplier != actualRatio) {
                               [weakSelf.view layoutIfNeeded];
                               [weakSelf updateRatioConstraintWithRatio:actualRatio];
                               if (!UIAccessibilityIsReduceMotionEnabled()) { // Layout animation
                                   weakSelf.contentView.rasterizeShadow = false;
                                   [UIView animateWithDuration:0.3
                                       animations:^{
                                         [weakSelf.view layoutIfNeeded];
                                       }
                                       completion:^(BOOL finished) {
                                         weakSelf.contentView.rasterizeShadow = true;
                                       }];
                               } else { // Simple fade animation
                                   CATransition *transition = [CATransition animation];
                                   transition.duration = 0.3;
                                   [weakSelf.view.layer addAnimation:transition forKey:nil];
                                   [weakSelf.view layoutIfNeeded];
                               }
                           }
                       }
                   }
                 }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.message.globalTapDelay > 0) {
        _lastViewAppearanceUptime = [BAUptimeProvider uptime];
    }

    if (_imageIsLoaded) {
        [self startAutoclosingCountdown];
    }
}

- (void)setupConstraints {
    [_contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.closeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_backgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];

    // Add background view to view, fullframe;
    [BAMSGViewToolbox setView:_backgroundView fullframeToSuperview:self.view useSafeArea:false];
    [BAMSGViewToolbox setView:_imageView fullframeToSuperview:_contentView useSafeArea:false];
    [BAMSGViewToolbox setView:_tapControl fullframeToSuperview:_contentView useSafeArea:false];

    [self setupCloseButton];

    if (_message.isFullscreen) {
        [BAMSGViewToolbox setView:_contentView fullframeToSuperview:self.view useSafeArea:false];
        // Center close button to top right corner of content view
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1
                                                               constant:-15]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view.safeAreaLayoutGuide
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1
                                                               constant:10]];
    } else {
        // Set content view ratio to value found in message
        CGFloat imageRatio = _message.imageSize.height / _message.imageSize.width;
        // We use a 3:2 portrait ratio while image is being downloaded
        if (CGSizeEqualToSize(_message.imageSize, CGSizeZero)) {
            imageRatio = 1.5;
        }

        [self updateRatioConstraintWithRatio:imageRatio];

        // Set _contentView horizontally margins
        NSDictionary *views = NSDictionaryOfVariableBindings(_contentView);
        [self.view
            addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|->=40@1000-[_contentView]->=40@1000-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-40@750-[_contentView]-40@750-|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];

        // Set height of _contentView
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_contentView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationLessThanOrEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeHeight
                                                             multiplier:1
                                                               constant:-80]];

        // Center content view horizontally
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_contentView
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1
                                                               constant:0]];

        // Make sure that the close button doesn't go under the safe area
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_contentView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                 toItem:self.view.safeAreaLayoutGuide
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1
                                                               constant:20]];

        // Center content view vertically
        NSLayoutConstraint *verticalContentViewConstraint =
            [NSLayoutConstraint constraintWithItem:_contentView
                                         attribute:NSLayoutAttributeCenterY
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.view
                                         attribute:NSLayoutAttributeCenterY
                                        multiplier:1
                                          constant:0];
        verticalContentViewConstraint.priority = 250;
        [self.view addConstraint:verticalContentViewConstraint];

        // Center close button to top right corner of content view
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_contentView
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.closeButton
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1
                                                               constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_contentView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.closeButton
                                                              attribute:NSLayoutAttributeCenterY
                                                             multiplier:1
                                                               constant:0]];

        _enteringBottomConstraint = [NSLayoutConstraint constraintWithItem:_contentView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.view
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1
                                                                  constant:0];
        _enteringBottomConstraint.priority = 1000;
        [self.view addConstraint:_enteringBottomConstraint];
    }
}

- (void)setupCloseButton {
    BACSSDOMNode *closeNode = [BACSSDOMNode new];
    closeNode.identifier = @"close";

    BACSSRules *rules = [self rulesForNode:closeNode];
    [self.closeButton applyRules:rules];
}

- (void)setupColors {
    BACSSDOMNode *backgroundNode = [BACSSDOMNode new];
    backgroundNode.identifier = @"background";
    BACSSRules *backgroundRules = [self rulesForNode:backgroundNode];

    BACSSDOMNode *containerNode = [BACSSDOMNode new];
    containerNode.identifier = @"container";
    BACSSRules *containerRules = [self rulesForNode:containerNode];

    [BAMSGStylableViewHelper applyCommonRules:backgroundRules toView:_backgroundView];
    [BAMSGStylableViewHelper applyCommonRules:containerRules toView:_contentView];
}

- (void)setupImageStyle {
    BACSSDOMNode *imageNode = [BACSSDOMNode new];
    imageNode.identifier = @"image";
    BACSSRules *imageRules = [self rulesForNode:imageNode];

    [_imageView applyRules:imageRules];
}

- (BOOL)shouldDisplayInSeparateWindow {
    return NO;
}

- (void)updateRatioConstraintWithRatio:(CGFloat)ratio {
    // Use a safe value to avoid a crash if the image width is zero (autolayout requires multipliers to
    // be finite). It will display improperly though. Maybe we should just dismiss the view here?
    if (!isfinite(ratio)) {
        ratio = 1.5f;
    }

    if (_ratioConstraint != nil) {
        _ratioConstraint.active = false;
    }

    _ratioConstraint = [NSLayoutConstraint constraintWithItem:_contentView
                                                    attribute:NSLayoutAttributeHeight
                                                    relatedBy:NSLayoutRelationEqual
                                                       toItem:_contentView
                                                    attribute:NSLayoutAttributeWidth
                                                   multiplier:ratio
                                                     constant:0];

    [_contentView addConstraint:_ratioConstraint];
}

#pragma mark - User actions

- (void)imageTapped {
    if (self.message.globalTapDelay > 0 &&
        [BAUptimeProvider uptime] < (_lastViewAppearanceUptime + self.message.globalTapDelay)) {
        [BALogger publicForDomain:@"Messaging"
                          message:@"View was tapped on, but the accidental touch prevention delay hasn't elapsed: "
                                  @"rejecting tap."];
        return;
    }

    [_hapticFeedbackGenerator notificationOccurred:BATNotificationFeedbackTypeSuccess];

    if (self.message.globalTapAction != nil) {
        [[self _doDismissSelfModal] then:^(NSObject *_Nullable value) {
          [self.messagingAnalyticsDelegate messageGlobalTapActionTriggered:self.message
                                                                    action:self.message.globalTapAction];
          [BAMessagingCenter.instance performAction:self.message.globalTapAction
                                             source:self.message.sourceMessage
                                        actionIndex:BatchMessageGlobalActionIndex
                                  messageIdentifier:self.message.sourceMessage.devTrackingIdentifier];
        }];
    }
}

#pragma mark - BAMSGPannableContainerViewDelegate

- (void)pannableContainerWasDismissed:(BAMSGBaseContainerView *)container {
    [self closeButtonAction];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    return _slideInAnimationcontroller;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return _slideOutAnimationcontroller;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented
                                                      presentingViewController:(UIViewController *)presenting
                                                          sourceViewController:(UIViewController *)source {
    return [[BAMSGImagePresentationController alloc] initWithPresentedViewController:presented
                                                            presentingViewController:presenting];
}

#pragma mark - Autoclosing

- (BOOL)showCloseButton {
    return true;
}

- (BOOL)automaticAutoclosingCountdown {
    return false;
}

- (NSTimeInterval)autoclosingDuration {
    return _message.autoClose;
}

#pragma mark - Dismissal

- (BAPromise *)doDismiss {
    return [self _doDismissSelfModal];
}

@end

#pragma mark Custom presentation

@implementation BAMSGImagePresentationController

- (CGRect)frameOfPresentedViewInContainerView {
    CGSize sceneSize = [BAMSGViewToolbox sceneSize];
    return CGRectMake(0, 0, sceneSize.width, sceneSize.height);
}

- (void)containerViewWillLayoutSubviews {
    self.presentedView.frame = [self frameOfPresentedViewInContainerView];
}

@end

@implementation BAMSGSlideInAnimationController

- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    BAMSGImageViewController *toController =
        (BAMSGImageViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    // pre animation settings
    toController.backgroundView.alpha = 0;

    // add to controller's view to screen
    [transitionContext.containerView addSubview:[transitionContext viewForKey:UITransitionContextToViewKey]];

    // execute animations
    [UIView animateWithDuration:0.3
                     animations:^{
                       toController.backgroundView.alpha = 1;
                     }
                     completion:nil];

    [toController.enteringBottomConstraint setActive:YES];
    [toController.view layoutIfNeeded];
    [toController.enteringBottomConstraint setActive:NO];

    if (UIAccessibilityIsReduceMotionEnabled()) { // Simple fade in animation
        toController.contentView.alpha = 0;
        toController.closeButton.alpha = 0;
        [UIView animateWithDuration:0.3
            animations:^{
              toController.contentView.alpha = 1;
              toController.closeButton.alpha = 1;
            }
            completion:^(BOOL finished) {
              [transitionContext completeTransition:YES];
            }];
    } else { // Slide animation is allowed
        [UIView animateWithDuration:0.5
            delay:0
            usingSpringWithDamping:0.7
            initialSpringVelocity:0
            options:0
            animations:^{
              [toController.view layoutIfNeeded];
            }
            completion:^(BOOL finished) {
              [transitionContext completeTransition:YES];
            }];
    }
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

@end

@implementation BAMSGSlideOutAnimationController

- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    BAMSGImageViewController *fromController =
        (BAMSGImageViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];

    // execute animations
    [UIView animateWithDuration:0.2
        delay:0.1
        options:0
        animations:^{
          fromController.backgroundView.alpha = 0;
          fromController.contentView.alpha = 0;
          fromController.closeButton.alpha = 0;
        }
        completion:^(BOOL finished) {
          [transitionContext completeTransition:YES];
        }];

    if (!UIAccessibilityIsReduceMotionEnabled()) { // Slide animation is allowed
        [fromController.enteringBottomConstraint setActive:YES];
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                           [fromController.view layoutIfNeeded];
                         }
                         completion:nil];
    }
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3;
}

@end

@interface BAMSGTapControl () {
    UIView *_dimView;
}
@end

@implementation BAMSGTapControl

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        _dimView = [[UIView alloc] initWithFrame:frame];
        _dimView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _dimView.userInteractionEnabled = false;
        _dimView.alpha = 0;
        [self addSubview:_dimView];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                       self->_dimView.alpha = highlighted ? 1 : 0;
                     }
                     completion:nil];
}

@end
