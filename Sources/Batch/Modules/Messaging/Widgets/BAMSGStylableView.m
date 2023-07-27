//
//  BAMSGStylableView.m
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGBaseContainerView.h>
#import <Batch/BAMSGGradientView.h>
#import <Batch/BAMSGStylableView.h>
#import <Batch/BAMessagingCenter.h>

@implementation BAMSGStylableViewHelper

+ (void)applyCommonRules:(nonnull BACSSRules *)rules toView:(nonnull UIView *)view {
    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys]) {
        NSString *value = rules[rule];

        if ([@"background-color" isEqualToString:rule]) {
            UIColor *color = [BAMSGStylableViewHelper colorFromValue:value];
            if (color) {
                [view setBackgroundColor:color];
            }
        } else if ([@"background" isEqualToString:rule]) {
            if ([value characterAtIndex:0] == '#') {
                // That's a color
                UIColor *color = [BAMSGStylableViewHelper colorFromValue:value];
                if (color) {
                    [view setBackgroundColor:color];
                }
            } else if ([value hasPrefix:@"linear-gradient("] && [value hasSuffix:@")"]) {
                if (![view conformsToProtocol:@protocol(BAMSGGradientBackgroundProtocol)]) {
                    continue;
                }
                value = [value substringWithRange:NSMakeRange(16, [value length] - 17)];
                NSArray<NSString *> *arguments = [value componentsSeparatedByString:@","];
                if ([arguments count] < 3) {
                    continue;
                }
                float gradiantAngle = [[arguments[0] stringByReplacingOccurrencesOfString:@"deg"
                                                                               withString:@""] floatValue];

                NSMutableArray *colors = [NSMutableArray new];
                NSMutableArray *locations = [NSMutableArray new];
                for (int i = 1; i < [arguments count]; i++) {
                    NSString *argument =
                        [arguments[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                    // Split on the space, to see if there's a position
                    // The position must be in [0;100]
                    // ex: linear-gradient(90, #FFBBAA 50, #FFAAEE 100)
                    // "%" will be stripped
                    argument = [argument stringByReplacingOccurrencesOfString:@"%" withString:@""];
                    NSArray<NSString *> *components = [argument componentsSeparatedByString:@" "];

                    UIColor *parsedColor = [BAMSGStylableViewHelper colorFromValue:[components objectAtIndex:0]];
                    if (parsedColor) {
                        [colors addObject:parsedColor];
                    }

                    if ([components count] > 1) {
                        float location = [components[1] floatValue] / 100;
                        if (location >= 0 && location <= 1) {
                            [locations addObject:@(location)];
                        }
                    }
                }

                if (colors.count == 0) {
                    continue;
                }

                [view setBackgroundColor:nil];

                if (locations.count != colors.count) {
                    locations = nil;
                }

                [(id<BAMSGGradientBackgroundProtocol>)view setBackgroundGradient:gradiantAngle
                                                                          colors:colors
                                                                       locations:locations];
            }
        } else if ([@"opacity" isEqualToString:rule]) {
            view.alpha = MAX(0.0, MIN(1.0, [value floatValue]));
        } else if ([@"layer-color" isEqualToString:rule]) {
            UIColor *color = [BAMSGStylableViewHelper colorFromValue:value];
            if (color) {
                [view setBackgroundColor:color];
            }
        } else if ([@"border-color" isEqualToString:rule]) {
            UIColor *color = [BAMSGStylableViewHelper colorFromValue:value];
            if (color) {
                [self layerForView:view].borderColor = [color CGColor];
            }
        } else if ([@"border-width" isEqualToString:rule]) {
            [self layerForView:view].borderWidth = [value floatValue];
        } else if ([@"border-radius" isEqualToString:rule]) {
            if ([view isKindOfClass:[BAMSGBaseContainerView class]]) {
                ((BAMSGBaseContainerView *)view).cornerRadius = [value floatValue];
            } else {
                // When adding a border radius we mask to bounds so that stuff doesn't go out
                CALayer *layer = [self layerForView:view];
                layer.masksToBounds = true;
                layer.cornerRadius = [value floatValue];
            }
        } else if ([@"shadow-layer" isEqualToString:rule]) {
            if (![view isKindOfClass:[BAMSGBaseContainerView class]]) {
                continue;
            }

            NSArray<NSString *> *arguments = [value componentsSeparatedByString:@" "];
            if ([arguments count] < 3) {
                continue;
            }

            BAMSGBaseContainerView *castedView = (BAMSGBaseContainerView *)view;

            if ([arguments count] > 0) {
                castedView.shadowRadius = [arguments[0] floatValue];
            }

            if ([arguments count] > 1) {
                castedView.shadowOpacity = [arguments[1] floatValue];
            }

            if ([arguments count] > 2) {
                UIColor *color = [BAMSGStylableViewHelper colorFromValue:arguments[2]];
                if (color) {
                    castedView.shadowColor = color;
                }
            }
        } else if ([@"content-hug-h" isEqualToString:rule]) {
            [view setContentHuggingPriority:MAX(1, MIN(1000, [value integerValue]))
                                    forAxis:UILayoutConstraintAxisHorizontal];
        } else if ([@"content-hug-v" isEqualToString:rule]) {
            [view setContentHuggingPriority:MAX(1, MIN(1000, [value integerValue]))
                                    forAxis:UILayoutConstraintAxisVertical];
        } else if ([@"compression-res-h" isEqualToString:rule]) {
            [view setContentCompressionResistancePriority:[value integerValue]
                                                  forAxis:UILayoutConstraintAxisHorizontal];
        } else if ([@"compression-res-v" isEqualToString:rule]) {
            [view setContentCompressionResistancePriority:[value integerValue] forAxis:UILayoutConstraintAxisVertical];
        }
    }
}

+ (nullable CALayer *)layerForView:(nullable UIView *)view {
    if ([view conformsToProtocol:@protocol(BAMSGContainerViewProtocol)]) {
        return [((id<BAMSGContainerViewProtocol>)view) contentLayer];
    }
    return view.layer;
}

+ (nullable UIColor *)colorFromValue:(nonnull NSString *)value {
    if ([@"transparent" isEqualToString:value]) {
        return [UIColor clearColor];
    }

    if ([value hasPrefix:@"#"]) {
        unsigned hexVal = 0;
        NSScanner *scanner = [NSScanner scannerWithString:[value substringFromIndex:1]];
        [scanner scanHexInt:&hexVal];

        if ([value length] == 9) {
            // Color is ARGB
            return [UIColor colorWithRed:((hexVal & 0xFF0000) >> 16) / 255.0
                                   green:((hexVal & 0xFF00) >> 8) / 255.0
                                    blue:(hexVal & 0xFF) / 255.0
                                   alpha:((hexVal & 0xFF000000) >> 24) / 255.0];
        } else {
            return [UIColor colorWithRed:((hexVal & 0xFF0000) >> 16) / 255.0
                                   green:((hexVal & 0xFF00) >> 8) / 255.0
                                    blue:(hexVal & 0xFF) / 255.0
                                   alpha:1.0];
        }
    } else if (value) {
        // Try to transorm the color into a native color (ex. "red" -> "[UIColor redColor]")
        SEL colorSelector = NSSelectorFromString([[value lowercaseString] stringByAppendingString:@"Color"]);
        if ([UIColor respondsToSelector:colorSelector]) {
            NSInvocation *invocation =
                [NSInvocation invocationWithMethodSignature:[UIColor methodSignatureForSelector:colorSelector]];
            [invocation setSelector:colorSelector];
            [invocation setTarget:[UIColor class]];
            [invocation invoke];
            UIColor *color;
            [invocation getReturnValue:&color];
            return color;
        }
    }

    return nil;
}

+ (nullable UIFont *)fontFromRules:(nonnull BACSSRules *)rules
                          baseFont:(UIFont *)baseFont
                      baseBoldFont:(UIFont *)baseBoldFont {
    NSString *customFontName = nil;
    float arbitraryFontWeight = 0;
    BOOL boldFont = NO;
    BOOL italicFont = NO;
    NSNumber *fontSize = nil;

    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys]) {
        NSString *value = rules[rule];

        if ([@"font-weight" isEqualToString:rule]) {
            if ([@"bold" isEqualToString:value]) {
                boldFont = YES;
            } else {
                // Maybe remove this as it only works with the system font
                arbitraryFontWeight = [value floatValue];
            }
        } else if ([@"font-style" isEqualToString:rule]) {
            if ([@"italic" isEqualToString:value]) {
                italicFont = YES;
            }
        } else if ([@"font-size" isEqualToString:rule]) {
            fontSize = @([value floatValue]);
        } else if ([@"font" isEqualToString:rule]) {
            customFontName = value;
        }
    }

    float finalFontSize = fontSize != nil ? [fontSize floatValue] : [UIFont systemFontSize];

    // If the dev overrides the font: do not try to be smart.
    // If the dev forgot to give a bold font override, use the system bold font.
    if (boldFont && baseBoldFont != nil) {
        return [baseBoldFont fontWithSize:finalFontSize];
    } else if (baseFont != nil) {
        return [baseFont fontWithSize:finalFontSize];
    }

    // Use labelFont temporarily as a base font. If customFontName isn't found, use the system one
    UIFont *labelFont;

    if (customFontName) {
        labelFont = [UIFont fontWithName:customFontName size:finalFontSize];
    }

    if (labelFont == nil) {
        if (boldFont) {
            labelFont = [UIFont boldSystemFontOfSize:finalFontSize];
        } else if (italicFont) {
            labelFont = [UIFont italicSystemFontOfSize:finalFontSize];
        } else if (arbitraryFontWeight > 0) {
            labelFont = [UIFont systemFontOfSize:finalFontSize weight:arbitraryFontWeight];
        } else {
            labelFont = [UIFont systemFontOfSize:finalFontSize];
        }
    } else {
        // Try to guess the bold/italic version of the font, but that can fail.

        UIFontDescriptorSymbolicTraits traits = 0;
        if (boldFont) {
            traits |= UIFontDescriptorTraitBold;
        } else if (italicFont) {
            traits |= UIFontDescriptorTraitItalic;
        }

        UIFont *guessedFont =
            [UIFont fontWithDescriptor:[[labelFont fontDescriptor] fontDescriptorWithSymbolicTraits:traits]
                                  size:finalFontSize];

        if (guessedFont) {
            labelFont = guessedFont;
        }
    }
    if ([BAMessagingCenter instance].enableDynamicType) {
        // Scales font if dynamic type is enabled
        labelFont = [[UIFontMetrics defaultMetrics] scaledFontForFont:labelFont];
    }
    return labelFont;
}

@end
