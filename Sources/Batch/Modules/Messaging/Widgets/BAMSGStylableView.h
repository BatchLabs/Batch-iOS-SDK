//
//  BAMSGStylableView.h
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BACSS.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol BAMSGStylableView <NSObject>

- (void)applyRules:(nonnull BACSSRules *)rules;

@end

@interface BAMSGStylableViewHelper : NSObject

+ (void)applyCommonRules:(nonnull BACSSRules *)rules toView:(nonnull UIView *)view;

+ (nullable UIColor *)colorFromValue:(nonnull NSString *)value;

+ (nullable UIFont *)fontFromRules:(nonnull BACSSRules *)rules
                          baseFont:(nullable UIFont *)baseFont
                      baseBoldFont:(nullable UIFont *)baseBoldFont;

@end
