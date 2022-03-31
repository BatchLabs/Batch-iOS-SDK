#import <Batch/BAMSGPannableAnchoredContainerView.h>

#define DISMISS_THRESHOLD_TRANSLATE_HEIGHT_RATIO 0.5
#define DISMISS_THRESHOLD_MINIMUM_VELOCITY 100

@implementation BAMSGPannableAnchoredContainerView {
    BAMSGPannableAnchoredContainerVerticalAnchor _verticalAnchor;
    UIPanGestureRecognizer *_panGesture;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _verticalAnchor = BAMSGPannableAnchoredContainerVerticalAnchorOther;
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDetectPan:)];
        _panGesture.delaysTouchesBegan = false;
        _panGesture.delaysTouchesEnded = false;
    }
    return self;
}

- (BAMSGPannableAnchoredContainerVerticalAnchor)verticalAnchor {
    return _verticalAnchor;
}

- (void)setVerticalAnchor:(BAMSGPannableAnchoredContainerVerticalAnchor)verticalAnchor {
    _verticalAnchor = verticalAnchor;

    [self removeGestureRecognizer:_panGesture];

    if (verticalAnchor != BAMSGPannableAnchoredContainerVerticalAnchorOther) {
        [self addGestureRecognizer:_panGesture];
    }
}

- (void)didDetectPan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat translationY = [recognizer translationInView:self].y;
        if ((_verticalAnchor == BAMSGPannableAnchoredContainerVerticalAnchorBottom && translationY < 0) ||
            (_verticalAnchor == BAMSGPannableAnchoredContainerVerticalAnchorTop && translationY > 0)) {
            translationY *= 0.2;
        }

        [self translateY:translationY];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([self shouldDismissForPanEnd:recognizer]) {
            [UIView animateWithDuration:0.8
                delay:0
                usingSpringWithDamping:0.5
                initialSpringVelocity:0
                options:UIViewAnimationOptionCurveEaseInOut
                animations:^{
                  CGFloat heightToHide = 0;
                  if (self.biggestUserVisibleView) {
                      CGRect viewFrame = self.biggestUserVisibleView.frame;

                      // As the biggest user visible view might have some margin, we need to check
                      // where it actually is on the screen, and compute the distance that it is from
                      // the edge we want to make it go to and hide.

                      // Kinda hard to explain but basically this will try to figure out just how much
                      // There probably are more elegant ways to do so.

                      if (self.verticalAnchor == BAMSGPannableAnchoredContainerVerticalAnchorTop) {
                          // Straightforward here. Just take the biggest user visible view's Y position, and add the
                          // view height
                          heightToHide = viewFrame.origin.y + viewFrame.size.height;
                          NSLog(@"origin y %f, height %f", viewFrame.origin.y, viewFrame.size.height);
                      } else {
                          // Here we'll have to take the distance between the screen's height and the view's Y position
                          // No need to add the view height, as this calculation already takes it into account
                          heightToHide = [[UIScreen mainScreen] bounds].size.height - viewFrame.origin.y;
                      }

                      // Shadows are outside of the layout computation
                      heightToHide += self.biggestUserVisibleView.layer.shadowRadius;
                  }

                  // Safeguard
                  if (heightToHide <= 0) {
                      [BALogger debugForDomain:@"BAMSGPannableContentView"
                                       message:@"Negative dismiss height calculation. Something is wrong with its "
                                               @"calculation: falling back."];
                      heightToHide = self.bounds.size.height;
                  }

                  if (self.verticalAnchor == BAMSGPannableAnchoredContainerVerticalAnchorTop) {
                      heightToHide *= -1;
                  }

                  [self translateY:heightToHide];
                }
                completion:^(BOOL finished) {
                  [self.delegate pannableContainerWasDismissed:self];
                }];
        } else {
            [UIView animateWithDuration:0.5
                                  delay:0
                 usingSpringWithDamping:0.5
                  initialSpringVelocity:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                               [self translateY:0];
                             }
                             completion:nil];
        }
    }
}

- (BOOL)shouldDismissForPanEnd:(UIPanGestureRecognizer *)recognizer {
    if (self.biggestUserVisibleView) {
        CGFloat translationY = [recognizer translationInView:self].y;
        if (self.verticalAnchor == BAMSGPannableAnchoredContainerVerticalAnchorTop) {
            // If on top, we need to invert the translation
            translationY *= -1;
        }

        // If the translated pixel count is higher than the threshold, dismiss even if the velocity is small
        float pixelThreshold =
            self.biggestUserVisibleView.bounds.size.height * DISMISS_THRESHOLD_TRANSLATE_HEIGHT_RATIO;
        if (translationY >= pixelThreshold) {
            return true;
        }
    }

    CGFloat velocityY = [recognizer velocityInView:self].y;
    if (self.verticalAnchor == BAMSGPannableAnchoredContainerVerticalAnchorTop) {
        // If on top, we need to invert the velocity too
        velocityY *= -1;
    }

    return velocityY >= DISMISS_THRESHOLD_MINIMUM_VELOCITY;
}

- (void)translateY:(CGFloat)translation {
    // On iOS 13 and 13.1, applying the transform using self.setTransform removes the safe area insets
    // when the translation is anything else than 0. We absolutely do not want that.
    // Fortunately, for now, applying a transformation on the layer works.
    // This will probably make pass-through touches while translated harder to fix, but we needed a hotfix
    self.layer.transform = CATransform3DMakeTranslation(0, translation, 0);
}

@end
