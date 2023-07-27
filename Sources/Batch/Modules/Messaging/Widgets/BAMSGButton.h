//
//  BAMSGButton.h
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Batch/BAMSGStylableView.h>

@interface BAMSGButton : UIButton <BAMSGStylableView>

+ (void)setFontOverride:(nullable UIFont *)font
               boldFont:(nullable UIFont *)boldFont
             italicFont:(nullable UIFont *)italicFont
         boldItalicFont:(nullable UIFont *)boldItalicFont;

@end
