//
//  BAMSGStackViewItem.m
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGStackView.h>
#import <Batch/BAMSGStackViewItem.h>

@implementation BAMSGStackViewItem

- (instancetype)init {
    self = [super init];
    if (self) {
        self.rules = [NSDictionary new];
        self.attachToParentBottom = NO;
    }
    return self;
}

+ (NSArray<NSLayoutConstraint *> *)constraintsForRules:(BACSSRules *)rules
                                            targetView:(nonnull UIView *)target
                                          previousView:(nullable UIView *)previous
                                              nextView:(nullable UIView *)next
                                            parentView:(nonnull UIView *)parent
                                  attachToParentBottom:(BOOL)attachToParentBottom {
    // Dragons ahead, have fun tweaking this code :)
    // I wish it could be cleaner, but a remote controllable autolayout understandable by mere mortals is a nice
    // challenge.

    // Separator views don't get margins/content hugging and compression, as they are used to set a view's margin-bottom
    BOOL isSeparatorView = [target isKindOfClass:[BAMSGStackSeparatorView class]];

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];

    BOOL widthApplied = NO;
    BOOL maxMinWidthApplied = NO;
    BOOL heightApplied = NO;
    BOOL maxMinHeightApplied = NO;
    BOOL wantsWidthFilled = NO;

    // margin-bottom is unsupported
    UIEdgeInsets margin = UIEdgeInsetsZero;

    NSLayoutAttribute alignAttr = NSLayoutAttributeCenterX;

    // Labels and scroll views automatically fill horizontally
    if ([target isKindOfClass:[UILabel class]] || [target isKindOfClass:[UIScrollView class]]) {
        wantsWidthFilled = YES;
    }

    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys]) {
        NSString *value = rules[rule];

        if ([@"width" isEqualToString:rule]) {
            if (maxMinWidthApplied) {
                continue;
            }
            widthApplied = YES;

            if ([@"100%" isEqualToString:value]) {
                wantsWidthFilled = YES;
            } else if ([@"auto" isEqualToString:value]) {
                wantsWidthFilled = NO;
            } else {
                wantsWidthFilled = NO;
                [constraints addObject:[NSLayoutConstraint constraintWithItem:target
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:[value floatValue]]];
            }

        } else if ([@"max-width" isEqualToString:rule]) {
            if (widthApplied) {
                continue;
            }
            maxMinWidthApplied = YES;

            [constraints addObject:[NSLayoutConstraint constraintWithItem:target
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationLessThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        } else if ([@"min-width" isEqualToString:rule]) {
            if (widthApplied) {
                continue;
            }
            maxMinWidthApplied = YES;

            [constraints addObject:[NSLayoutConstraint constraintWithItem:target
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        } else if ([@"height" isEqualToString:rule]) {
            if (maxMinHeightApplied) {
                continue;
            }
            heightApplied = YES;

            [constraints addObject:[NSLayoutConstraint constraintWithItem:target
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        } else if ([@"max-height" isEqualToString:rule]) {
            if (heightApplied) {
                continue;
            }
            maxMinHeightApplied = YES;

            [constraints addObject:[NSLayoutConstraint constraintWithItem:target
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationLessThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        } else if ([@"min-height" isEqualToString:rule]) {
            if (heightApplied) {
                continue;
            }
            maxMinHeightApplied = YES;

            [constraints addObject:[NSLayoutConstraint constraintWithItem:target
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        } else if ([@"align" isEqualToString:rule]) {
            // align: center is not handled as this is the default
            if ([@"left" isEqualToString:value]) {
                alignAttr = NSLayoutAttributeLeft;
            } else if ([@"right" isEqualToString:value]) {
                alignAttr = NSLayoutAttributeRight;
            }
        } else {
            if (!isSeparatorView) {
                // "margin: x x x x" rules have been splitted elsewhere for easier handling
                if ([@"margin-top" isEqualToString:rule]) {
                    margin.top = [value floatValue];
                } else if ([@"margin-left" isEqualToString:rule]) {
                    margin.left = [value floatValue];
                } else if ([@"margin-right" isEqualToString:rule]) {
                    // Right margins are negative with Auto Layout
                    margin.right = -[value floatValue];
                } else if ([@"margin-bottom" isEqualToString:rule]) {
                    // Oh, by the way: this is negative too
                    margin.bottom = -[value floatValue];
                } else if ([@"content-hug-h" isEqualToString:rule]) {
                    [target setContentHuggingPriority:MAX(1, MIN(1000, [value integerValue]))
                                              forAxis:UILayoutConstraintAxisHorizontal];
                } else if ([@"content-hug-v" isEqualToString:rule]) {
                    [target setContentHuggingPriority:MAX(1, MIN(1000, [value integerValue]))
                                              forAxis:UILayoutConstraintAxisVertical];
                } else if ([@"compression-res-h" isEqualToString:rule]) {
                    [target setContentCompressionResistancePriority:[value integerValue]
                                                            forAxis:UILayoutConstraintAxisHorizontal];
                } else if ([@"compression-res-v" isEqualToString:rule]) {
                    [target setContentCompressionResistancePriority:[value integerValue]
                                                            forAxis:UILayoutConstraintAxisVertical];
                }
                // Other CSS cases, like padding, might be handled elsewhere
            }
        }
    }

    if (wantsWidthFilled) {
        [constraints addObject:[NSLayoutConstraint constraintWithItem:target
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:parent
                                                            attribute:NSLayoutAttributeLeft
                                                           multiplier:1.0
                                                             constant:margin.left]];

        [constraints addObject:[NSLayoutConstraint constraintWithItem:target
                                                            attribute:NSLayoutAttributeRight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:parent
                                                            attribute:NSLayoutAttributeRight
                                                           multiplier:1.0
                                                             constant:margin.right]];
    } else {
        // Margin goes before everything
        [constraints addObjectsFromArray:[NSLayoutConstraint
                                             constraintsWithVisualFormat:
                                                 [NSString stringWithFormat:@"|-(>=%f@1000)-[target]-(>=%f@1000)-|",
                                                                            margin.left, -margin.right]
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(target)]];

        // Only apply the needed margin if not filled
        float alignAttrMargin = 0;

        if (alignAttr == NSLayoutAttributeLeft) {
            alignAttrMargin = margin.left;
        } else if (alignAttr == NSLayoutAttributeRight) {
            alignAttrMargin = margin.right;
        }

        NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:target
                                                             attribute:alignAttr
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:parent
                                                             attribute:alignAttr
                                                            multiplier:1.0
                                                              constant:alignAttrMargin];
        c.priority = 700;

        [constraints addObject:c];
    }

    // Top margin
    NSLayoutConstraint *topMargin =
        [NSLayoutConstraint constraintWithItem:target
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:previous ? previous : parent
                                     attribute:previous ? NSLayoutAttributeBottom : NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:margin.top];
    // Give the top margin some room to break if the screen is too small
    topMargin.priority = 800;
    [constraints addObject:topMargin];

    if (isSeparatorView) {
        // If we're a separator view, and our previous view was asked to be attach to its parent, attach ourselves
        // instead of the original view The previous view will be attached to the separator
        if (attachToParentBottom) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:target
                                                                attribute:NSLayoutAttributeBottom
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:parent
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant:margin.bottom]];
        }
    } else {
        // Little hack to get margins to work
        // Use the separator view to support a bottom margin. Separator views don't support margin, so we can do that
        // for them If we don't have a next view (which is usually a separator), this will not work. If there's one but
        // it is not a separator we're in for some undefined behaviour!

        if (next) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:target
                                                                attribute:NSLayoutAttributeBottom
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:next
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0
                                                                 constant:margin.bottom]];
        }
    }

    return constraints;
}

- (NSArray<NSLayoutConstraint *> *)computeConstraints {
    return [BAMSGStackViewItem constraintsForRules:self.rules
                                        targetView:self.view
                                      previousView:self.previousView
                                          nextView:self.nextView
                                        parentView:self.parentView
                              attachToParentBottom:self.attachToParentBottom];
}

@end

@implementation BAMSGStackViewSeparatorItem

@end
