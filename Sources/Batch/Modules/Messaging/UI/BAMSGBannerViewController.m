//
//  BAMSGBannerViewController.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMSGBannerViewController.h>

@implementation BAMSGBannerViewController

- (void)loadView {
    BAMSGBaseContainerView *v;
    if (self.allowSwipeToDismiss) {
        v = [BAMSGPannableAnchoredContainerView new];
        ((BAMSGPannableAnchoredContainerView *)v).delegate = self;
    } else {
        v = [BAMSGBaseContainerView new];
    }
    v.touchPassthrough = true;

    if (self.globalTapAction != nil) {
        [v addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(didDetectGlobalTap:)]];
    }

    self.view = v;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Not sure why, but posting the notification directly does not work
    dispatch_async(dispatch_get_main_queue(), ^{
      UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.view);
    });
}

@end
