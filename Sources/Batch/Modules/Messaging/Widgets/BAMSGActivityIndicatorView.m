//
//  BAMSGActivityIndicatorView.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BAMSGActivityIndicatorView.h"

@implementation BAMSGActivityIndicatorView
{
    BAMSGActivityIndicatorViewSize _preferredSize;
    BAMSGActivityIndicatorViewColor _preferredColor;
}

- (instancetype)initWithPreferredSize:(BAMSGActivityIndicatorViewSize)size
{
    self = [super initWithActivityIndicatorStyle:[BAMSGActivityIndicatorView styleForPreferredSize:size]];
    if (self)
    {
        [self setDefaultPropertyValues];
        _preferredSize = size;
        [self refreshInternalStyle];
        [self setup];
    }
    return self;
}

- (instancetype)initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style
{
    self = [super initWithActivityIndicatorStyle:style];
    if (self)
    {
        [self setDefaultPropertyValues];
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setDefaultPropertyValues];
        [self setup];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setDefaultPropertyValues];
        [self setup];
    }
    return self;
}

- (void)setDefaultPropertyValues
{
    _preferredSize = BAMSGActivityIndicatorViewSizeMedium;
    _preferredColor = BAMSGActivityIndicatorViewColorDark;
}

- (void)setup
{
    [self refreshInternalStyle];
}

- (void)refreshInternalStyle
{
    // For compatibility, we need to first apply the style, and then the color
    // This allows us to control the size on iOS 12 and lower.
    
    UIColor *color;
    switch (self.preferredColor) {
        case BAMSGActivityIndicatorViewColorDark:
            color = [UIColor grayColor];
            break;
        case BAMSGActivityIndicatorViewColorLight:
        default:
            color = [UIColor whiteColor];
            break;
    }
    
    [self setActivityIndicatorViewStyle:[BAMSGActivityIndicatorView styleForPreferredSize:self.preferredSize]];
    self.color = color;
}

#pragma mark Properties

- (BAMSGActivityIndicatorViewSize)preferredSize
{
    return _preferredSize;
}

- (void)setPreferredSize:(BAMSGActivityIndicatorViewSize)preferredSize
{
    _preferredSize = preferredSize;
    [self refreshInternalStyle];
}

- (BAMSGActivityIndicatorViewColor)preferredColor
{
    return _preferredColor;
}

- (void)setPreferredColor:(BAMSGActivityIndicatorViewColor)preferredColor
{
    _preferredColor = preferredColor;
    [self refreshInternalStyle];
}

#pragma mark Helpers

+ (UIActivityIndicatorViewStyle)styleForPreferredSize:(BAMSGActivityIndicatorViewSize)preferredSize
{
    UIActivityIndicatorViewStyle style;
    if (@available(iOS 13.0, *)) {
        switch (preferredSize) {
            case BAMSGActivityIndicatorViewSizeLarge:
                style = UIActivityIndicatorViewStyleLarge;
                break;
            case BAMSGActivityIndicatorViewSizeMedium:
            default:
                style = UIActivityIndicatorViewStyleMedium;
                break;
        }
    } else {
        switch (preferredSize) {
            case BAMSGActivityIndicatorViewSizeLarge:
                style = UIActivityIndicatorViewStyleWhiteLarge;
                break;
            case BAMSGActivityIndicatorViewSizeMedium:
            default:
                style = UIActivityIndicatorViewStyleWhite;
                break;
        }
    }
    return style;
}

#pragma mark BAMSGStylableView conformance

- (void)applyRules:(nonnull BACSSRules*)rules
{
    for (NSString *rule in [rules allKeys])
    {
        NSString *value = rules[rule];
        
        if ([@"loader" isEqualToString:rule])
        {
            if ([@"light" isEqualToString:value])
            {
                self.preferredColor = BAMSGActivityIndicatorViewColorLight;
            }
            else if ([@"dark" isEqualToString:value])
            {
                self.preferredColor = BAMSGActivityIndicatorViewColorDark;
            }
        } else if ([@"loader-size" isEqualToString:rule])
        {
            if ([@"medium" isEqualToString:value])
            {
                self.preferredSize = BAMSGActivityIndicatorViewSizeMedium;
            }
            else if ([@"large" isEqualToString:value])
            {
                self.preferredSize = BAMSGActivityIndicatorViewSizeLarge;
            }
        }
    }
}

@end
