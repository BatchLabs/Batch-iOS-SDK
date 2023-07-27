#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Batch/BAPromise.h>

@interface BAMSGOverlayWindow : UIWindow

@property NSTimeInterval visibilityAnimationDuration;

- (void)presentAnimated;

- (BAPromise *)dismissAnimated;

@end
