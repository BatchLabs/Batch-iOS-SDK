//
//  BAMSGLabel.h
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Batch/BAMSGStylableView.h>
#import <Batch/BAMSGGradientView.h>
#import <Batch/BATHtmlParser.h>

@interface BAMSGLabel : UILabel <BAMSGStylableView, BAMSGGradientBackgroundProtocol>

@property UIEdgeInsets padding;

+ (void)setFontOverride:(nullable UIFont*)font boldFont:(nullable UIFont*)boldFont italicFont:(nullable UIFont*)italicFont boldItalicFont:(nullable UIFont*)boldItalicFont;

- (void)setText:(NSString *_Nullable)text transforms:(NSArray<BATTextTransform*>*_Nullable)transforms;

@end
