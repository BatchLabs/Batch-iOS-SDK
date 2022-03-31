//
//  BAMSGLabel.m
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGLabel.h>
#import <Batch/BAMSGStylableView.h>

@interface BAMSGLabel () {
    float lineHeightMultiply;
    float lineHeightAdd;
    float letterSpacing;

    NSArray<BATTextTransform *> *appliedTransforms;
}

@end

@implementation BAMSGLabel

static UIFont *sBAMSGLabelFontOverride = nil;
static UIFont *sBAMSGLabelBoldFontOverride = nil;
static UIFont *sBAMSGLabelItalicFontOverride = nil;
static UIFont *sBAMSGLabelBoldItalicFontOverride = nil;

+ (void)setFontOverride:(nullable UIFont *)font
               boldFont:(nullable UIFont *)boldFont
             italicFont:(nullable UIFont *)italicFont
         boldItalicFont:(nullable UIFont *)boldItalicFont {
    sBAMSGLabelFontOverride = font;
    sBAMSGLabelBoldFontOverride = boldFont;
    sBAMSGLabelItalicFontOverride = italicFont;
    sBAMSGLabelBoldItalicFontOverride = boldItalicFont;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _padding = UIEdgeInsetsZero;

        self.lineBreakMode = NSLineBreakByWordWrapping;

        lineHeightMultiply = 0;
        lineHeightAdd = 0;
        letterSpacing = 0;
    }
    return self;
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:[UIColor clearColor]];
    if (!backgroundColor) {
        backgroundColor = [UIColor clearColor];
    }
    CAGradientLayer *layer = [self gradientLayer];
    [layer setColors:@[ (id)backgroundColor.CGColor, (id)backgroundColor.CGColor ]];
    [layer setStartPoint:CGPointMake(0, 0)];
    [layer setEndPoint:CGPointMake(1, 1)];
}

- (void)setBackgroundGradient:(float)angle colors:(NSArray *)colors locations:(NSArray *)locations {
    [BAMSGGradientView setupGradientLayer:[self gradientLayer] withAngle:angle colors:colors locations:locations];
}

- (CAGradientLayer *)gradientLayer {
    return (CAGradientLayer *)self.layer;
}

- (void)applyRules:(nonnull BACSSRules *)rules {
    [BAMSGStylableViewHelper applyCommonRules:rules toView:self];

    NSTextAlignment textAlign = NSTextAlignmentCenter;

    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys]) {
        NSString *value = rules[rule];

        if ([@"color" isEqualToString:rule]) {
            UIColor *color = [BAMSGStylableViewHelper colorFromValue:value];
            if (color) {
                [self setTextColor:color];
            }
        }
        // "padding: x x x x" rules have been splitted elsewhere for easier handling
        else if ([@"padding-top" isEqualToString:rule]) {
            _padding.top = [value floatValue];
        } else if ([@"padding-bottom" isEqualToString:rule]) {
            _padding.bottom = [value floatValue];
        } else if ([@"padding-left" isEqualToString:rule]) {
            _padding.left = [value floatValue];
        } else if ([@"padding-right" isEqualToString:rule]) {
            _padding.right = [value floatValue];
        } else if ([@"text-align" isEqualToString:rule]) {
            if ([@"left" isEqualToString:value]) {
                textAlign = NSTextAlignmentLeft;
            } else if ([@"right" isEqualToString:value]) {
                textAlign = NSTextAlignmentRight;
            } else if ([@"justify" isEqualToString:value]) {
                textAlign = NSTextAlignmentJustified;
            }
        }

        else if ([@"letter-spacing" isEqualToString:rule]) {
            letterSpacing = [value floatValue];
        } else if ([@"line-height" isEqualToString:rule]) {
            lineHeightMultiply = [value floatValue];
        } else if ([@"line-spacing" isEqualToString:rule]) {
            lineHeightAdd = [value floatValue];
        }
    }

    UIFont *customFont = [BAMSGStylableViewHelper fontFromRules:rules
                                                       baseFont:sBAMSGLabelFontOverride
                                                   baseBoldFont:sBAMSGLabelBoldFontOverride];
    if (customFont) {
        self.font = customFont;
    }

    self.textAlignment = textAlign;
    [self setText:self.text transforms:appliedTransforms];
}

- (void)drawTextInRect:(CGRect)rect {
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _padding)];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];

    // Substract the padding from the asked width, so that iOS correctly reflows the text if needed
    CGFloat targetWidth = CGRectGetWidth(bounds) - _padding.left - _padding.right;
    if (self.preferredMaxLayoutWidth != targetWidth) {
        self.preferredMaxLayoutWidth = targetWidth;
        [self setNeedsUpdateConstraints];
    }
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];

    size.width = size.width + _padding.left + _padding.right;
    size.height = size.height + _padding.top + _padding.bottom;

    return size;
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [self setText:[attributedText string] transforms:nil];
}

- (void)setText:(NSString *)text {
    [self setText:text transforms:nil];
}

- (void)setText:(NSString *)text transforms:(NSArray<BATTextTransform *> *)transforms {
    if (!text) {
        text = @"";
    }

    appliedTransforms = [transforms copy];

    NSMutableAttributedString *attText =
        [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : self.font}];

    [self applyTransforms:transforms toAttributedString:attText];

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];

    if (lineHeightAdd != 0 || lineHeightMultiply != 0) {
        if (lineHeightAdd != 0) {
            [style setLineSpacing:lineHeightAdd];
        }

        if (lineHeightMultiply != 0) {
            [style setLineHeightMultiple:lineHeightMultiply];
        }

        [style setAlignment:[self textAlignment]];

        [attText addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [text length])];
    }

    if (letterSpacing != 0) {
        [attText addAttribute:NSKernAttributeName value:@(letterSpacing) range:NSMakeRange(0, [text length])];
    }

    [super setAttributedText:attText];
}

- (void)applyTransforms:(NSArray<BATTextTransform *> *)transforms
     toAttributedString:(NSMutableAttributedString *)attributedString {
    // Reversing the iterator is important, otherwise composed styles will not work
    // UIKit seems to apply the first style it comes across
    for (BATTextTransform *transform in transforms.reverseObjectEnumerator) {
        BATTextModifiers modifiers = transform.modifiers;
        if ((modifiers & BATTextModifierBold) || (modifiers & BATTextModifierItalic) ||
            (modifiers & BATTextModifierSmallerFont) || (modifiers & BATTextModifierBiggerFont)) {
            UIFontDescriptorSymbolicTraits uiFontTraits = 0;
            if (modifiers & BATTextModifierBold) {
                uiFontTraits |= UIFontDescriptorTraitBold;
            }
            if (modifiers & BATTextModifierItalic) {
                uiFontTraits |= UIFontDescriptorTraitItalic;
            }

            CGFloat fontSize = self.font.pointSize;
            if (modifiers & BATTextModifierSmallerFont) {
                fontSize *= 0.75;
            } else if (modifiers & BATTextModifierBiggerFont) {
                fontSize *= 1.25;
            }

            [attributedString addAttribute:NSFontAttributeName
                                     value:[self fontVariantForTraits:uiFontTraits size:fontSize]
                                     range:transform.range];
        }

        if (modifiers & BATTextModifierUnderline) {
            [attributedString addAttribute:NSUnderlineStyleAttributeName
                                     value:@(NSUnderlineStyleSingle)
                                     range:transform.range];
        }

        if (modifiers & BATTextModifierStrikethrough) {
            // Yes, Strikethrough reuses the underline styling enum
            [attributedString addAttribute:NSStrikethroughStyleAttributeName
                                     value:@(NSUnderlineStyleSingle)
                                     range:transform.range];
        }

        if (modifiers & BATTextModifierSpan) {
            UIColor *color = [BAMSGStylableViewHelper colorFromValue:transform.attributes[@"color"]];
            if (color != nil) {
                [attributedString addAttribute:NSForegroundColorAttributeName value:color range:transform.range];
            }
            UIColor *backgroundColor =
                [BAMSGStylableViewHelper colorFromValue:transform.attributes[@"background-color"]];
            if (backgroundColor != nil) {
                [attributedString addAttribute:NSBackgroundColorAttributeName
                                         value:backgroundColor
                                         range:transform.range];
            }
        }
    }
}

/**
 Get a variant of the font that's already set on this label for the added traits

 With support for the custom fonts
 */
- (UIFont *)fontVariantForTraits:(UIFontDescriptorSymbolicTraits)traits size:(CGFloat)size {
    UIFont *baseFont = self.font;
    if (traits) {
        if (sBAMSGLabelFontOverride != nil) {
            // We have a custom font, work with that
            UIFont *customFont = nil;

            if (traits & UIFontDescriptorTraitBold) {
                if (traits & UIFontDescriptorTraitItalic) {
                    customFont = sBAMSGLabelBoldItalicFontOverride;
                } else {
                    customFont = sBAMSGLabelBoldFontOverride;
                }
            } else if (traits & UIFontDescriptorTraitItalic) {
                customFont = sBAMSGLabelItalicFontOverride;
            }

            if (customFont == nil) {
                customFont = sBAMSGLabelFontOverride;
            }

            return [customFont fontWithSize:size];
        } else {
            // System font
            UIFontDescriptor *fontDescriptor = [baseFont.fontDescriptor fontDescriptorWithSymbolicTraits:traits];
            UIFont *computedFont = [UIFont fontWithDescriptor:fontDescriptor size:size];
            return computedFont != nil ? computedFont : baseFont;
        }
    } else {
        return [baseFont fontWithSize:size];
    }
    return baseFont;
}

@end
