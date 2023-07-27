#import <UIKit/UIKit.h>

#import <Batch/BAMSGStylableView.h>

@interface BAMSGCountdownView : UIView <BAMSGStylableView>

/**
 Set the progression percentage, between 0 and 1
 */
- (void)setPercentage:(float)percentage;

- (void)setColor:(nonnull UIColor *)color;

@end
