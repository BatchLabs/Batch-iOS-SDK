//
//  BAMSGCloseButton.h
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGStylableView.h>
#import <UIKit/UIKit.h>

@interface BAMSGCloseButton : UIButton <BAMSGStylableView>

@property (nonnull, nonatomic) UIColor *glyphColor;
@property (nullable) NSNumber *glyphWidth;
@property (nullable) NSNumber *glyphPadding;
/// Default to false. Set to true to display a 1-px wide border the color of the glyph @ 75% opacity.
@property (nonatomic) BOOL showBorder;

- (void)prepareCountdown;
- (void)animateCountdownForDuration:(CFTimeInterval)duration
                  completionHandler:(nullable void (^)(void))completionHandler;

@end
