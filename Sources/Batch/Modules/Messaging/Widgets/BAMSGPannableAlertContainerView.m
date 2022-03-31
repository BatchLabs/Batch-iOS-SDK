//
//  BAMSGPannableAlertContainerView.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMSGPannableAlertContainerView.h>

// Various constants that define the alert pan look & feel
#define ANIMATION_DURATION 0.5
#define ANIMATION_DURATION_FAST 0.2
#define TRANSLATION_PAN_MULTIPLIER 0.4
#define SCALE_PAN_MULTIPLIER 0.0002
#define DISMISSABLE_TARGET_ALPHA 0.6
#define DISMISS_THRESHOLD_MINIMUM_VELOCITY 1000
#define SMALLEST_SCALE_RATIO 0.85
#define SCALE_RATIO_DISMISS_THRESHOLD 0.96

@implementation BAMSGPannableAlertContainerView {
    UIPanGestureRecognizer *_panGesture;

    UIView *_linkedView;

    // Gesture recognizer state dependent variable
    BOOL _shouldDismiss;
    UIImpactFeedbackGenerator *_hapticFeedbackGenerator NS_AVAILABLE_IOS(10_0);
    CGPoint _linkedViewInitialOffset;
    CGFloat _initialAlpha;
    CGFloat _linkedViewInitialAlpha;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewDragged:)];
        _panGesture.delaysTouchesBegan = false;
        _panGesture.delaysTouchesEnded = false;
        [self addGestureRecognizer:_panGesture];
        _lockVertically = true;
        _resetPositionOnDismiss = true;
    }
    return self;
}

- (void)viewDragged:(UIPanGestureRecognizer *)recognizer {
    // TODO handle velocity
    [self configureHapticFeedbackForState:recognizer.state];

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            _initialAlpha = self.alpha;
            _linkedViewInitialAlpha = _linkedView.alpha;
            _linkedViewInitialOffset =
                CGPointMake(self.center.x - _linkedView.center.x, self.center.y - _linkedView.center.y);
            _shouldDismiss = false;
            break;
        case UIGestureRecognizerStateChanged:
            [self applyTransformForPanChange:recognizer];
            break;
        case UIGestureRecognizerStateEnded:
            [self panEnded:recognizer];
            break;
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            _shouldDismiss = false;
            break;
        default:
            break;
    }
}

- (void)configureHapticFeedbackForState:(UIGestureRecognizerState)state {
    switch (state) {
        case UIGestureRecognizerStateBegan:
            _hapticFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [_hapticFeedbackGenerator prepare];
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:
            _hapticFeedbackGenerator = nil;
            break;
        default:
            break;
    }
}

- (void)applyTransformForPanChange:(UIPanGestureRecognizer *)recognizer {
    UIView *superview = self.superview;
    if (!superview) {
        // Bail, we need a superview to calculate everything
        return;
    }

    CGPoint translation = [recognizer translationInView:superview];

    CGFloat scaleRatioVertical =
        MIN(1, MAX(SMALLEST_SCALE_RATIO, 1 + (-1 * ABS(translation.y) * SCALE_PAN_MULTIPLIER)));
    CGFloat scaleRatioHorizontal =
        MIN(1, MAX(SMALLEST_SCALE_RATIO, 1 + (-1 * ABS(translation.x) * SCALE_PAN_MULTIPLIER)));

    CGFloat scaleRatio = MIN(scaleRatioVertical, scaleRatioHorizontal);

    CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(
        _lockVertically ? 0 : translation.x * TRANSLATION_PAN_MULTIPLIER, translation.y * TRANSLATION_PAN_MULTIPLIER);
    self.transform = CGAffineTransformScale(translationTransform, scaleRatio, scaleRatio);
    _linkedView.transform = CGAffineTransformTranslate(
        self.transform, _linkedViewInitialOffset.x - (_linkedViewInitialOffset.x * scaleRatio),
        _linkedViewInitialOffset.y - (_linkedViewInitialOffset.y * scaleRatio));

    if (scaleRatio <= SCALE_RATIO_DISMISS_THRESHOLD) {
        if (_shouldDismiss == false) {
            _shouldDismiss = true;
            [self shouldDismissChanged];
        }
    } else {
        if (_shouldDismiss == true) {
            _shouldDismiss = false;
            [self shouldDismissChanged];
        }
    }
}

- (void)shouldDismissChanged {
    [_hapticFeedbackGenerator impactOccurred];
    [_hapticFeedbackGenerator prepare];

    // Copy to make sure we get the state when the animation is triggered
    BOOL shouldDismiss = _shouldDismiss;
    [UIView animateWithDuration:ANIMATION_DURATION_FAST
                     animations:^{
                       self.alpha = shouldDismiss ? DISMISSABLE_TARGET_ALPHA : self->_initialAlpha;
                       self->_linkedView.alpha =
                           shouldDismiss ? DISMISSABLE_TARGET_ALPHA : self->_linkedViewInitialAlpha;
                     }];
}

- (void)panEnded:(UIPanGestureRecognizer *)recognizer {
    BOOL willDismiss = NO;
    BOOL dismissY = ABS([recognizer velocityInView:self].y) >= DISMISS_THRESHOLD_MINIMUM_VELOCITY;
    BOOL dismissX = (ABS([recognizer velocityInView:self].x) >= DISMISS_THRESHOLD_MINIMUM_VELOCITY) && !_lockVertically;
    if (_shouldDismiss || dismissY || dismissX) {
        [_delegate pannableContainerWasDismissed:self];
        willDismiss = YES;
    }
    _shouldDismiss = false;

    if (!willDismiss || (_resetPositionOnDismiss && !UIAccessibilityIsReduceMotionEnabled())) {
        [self resetAnimated];
    }
}

- (void)resetAnimated {
    [UIView animateWithDuration:ANIMATION_DURATION_FAST
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self.alpha = self->_initialAlpha;
                       self->_linkedView.alpha = self->_linkedViewInitialAlpha;
                     }
                     completion:nil];

    if (UIAccessibilityIsReduceMotionEnabled()) { // Put back view with a simple translation
        [UIView animateWithDuration:ANIMATION_DURATION
                         animations:^{
                           self.transform = CGAffineTransformIdentity;
                           self->_linkedView.transform = CGAffineTransformIdentity;
                         }];
    } else { // Spring animation
        [UIView animateWithDuration:ANIMATION_DURATION
                              delay:0
             usingSpringWithDamping:0.5
              initialSpringVelocity:0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                           self.transform = CGAffineTransformIdentity;
                           self->_linkedView.transform = CGAffineTransformIdentity;
                         }
                         completion:nil];
    }
}

#pragma mark View linking

- (void)setLinkedView:(UIView *)linkedView {
    _linkedView = linkedView;
}

@end
