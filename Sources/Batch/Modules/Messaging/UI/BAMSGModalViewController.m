//
//  BAMSGModalViewController.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMSGModalViewController.h>
#import <Batch/BAMSGPannableAlertContainerView.h>

@implementation BAMSGModalViewController

- (instancetype)initWithStyleRules:(nonnull BACSSDocument*)style
{
    self = [super initWithStyleRules:style];
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (UIView*)makeContentView
{
    BAMSGBaseContainerView *v;
    if (self.allowSwipeToDismiss) {
        v = [BAMSGPannableAlertContainerView new];
        ((BAMSGPannableAlertContainerView*)v).delegate = self;
    } else {
        v = [BAMSGBaseContainerView new];
    }
    
    if (self.globalTapAction != nil) {
        [v addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(didDetectGlobalTap:)]];
    }
    
    return v;
}

- (BOOL)shouldDisplayInSeparateWindow
{
    return false;
}

@end
