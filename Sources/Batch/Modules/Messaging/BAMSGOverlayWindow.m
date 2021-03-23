#import <Batch/BAMSGOverlayWindow.h>

@implementation BAMSGOverlayWindow

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.visibilityAnimationDuration = 0;
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        return nil;
    }
    return hitView;
}

- (void)presentAnimated
{
    self.alpha = 0;
    self.windowLevel = UIWindowLevelNormal+1;
    [self setHidden:NO];
    [UIView animateWithDuration:self.visibilityAnimationDuration animations:^{
        self.alpha = 1;
    }];
}

- (BAPromise*)dismissAnimated
{
    BAPromise *dismissPromise = [BAPromise new];
    __strong __block id strongSelf = self;
    // Retain ourselves during the animation
    [UIView animateWithDuration:self.visibilityAnimationDuration
                     animations:^{
                         self.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         self.hidden = YES;
                         [self removeFromSuperview];
                         [[self.rootViewController presentedViewController] dismissViewControllerAnimated:NO completion:nil];
                         self.rootViewController = nil;
                         strongSelf = nil;
                         [dismissPromise resolve:nil];
                     }];
    return dismissPromise;
}

@end
