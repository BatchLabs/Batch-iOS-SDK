//
//  BAMSGLabel.h
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGGradientView.h>
#import <Batch/BAMSGStylableView.h>
#import <Batch/BATHtmlParser.h>
#import <UIKit/UIKit.h>

@interface BAMSGLabel : UILabel <BAMSGStylableView, BAMSGGradientBackgroundProtocol>

@property UIEdgeInsets padding;

+ (void)setFontOverride:(nullable UIFont *)font
               boldFont:(nullable UIFont *)boldFont
             italicFont:(nullable UIFont *)italicFont
         boldItalicFont:(nullable UIFont *)boldItalicFont;

- (void)setText:(NSString *_Nullable)text transforms:(NSArray<BATTextTransform *> *_Nullable)transforms;

@end
