//
//  BAMSGButton.m
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGButton.h>
#import <Batch/BAMessagingCenter.h>

static void *BAMSGButtonCornerRadiusContext = &BAMSGButtonCornerRadiusContext;

@interface BAMSGButton () {
    UIView *_pressedOverlay;
    NSNumber *_savedCornerRadius;
    bool _updatingCornerRadius;
}

@end

@implementation BAMSGButton

static UIFont *sBAMSGButtonFontOverride = nil;
static UIFont *sBAMSGButtonBoldFontOverride = nil;
static UIFont *sBAMSGButtonItalicFontOverride = nil;
static UIFont *sBAMSGButtonBoldItalicFontOverride = nil;

+ (void)setFontOverride:(nullable UIFont *)font
               boldFont:(nullable UIFont *)boldFont
             italicFont:(nullable UIFont *)italicFont
         boldItalicFont:(nullable UIFont *)boldItalicFont {
    sBAMSGButtonFontOverride = font;
    sBAMSGButtonBoldFontOverride = boldFont;
    sBAMSGButtonItalicFontOverride = italicFont;
    sBAMSGButtonBoldItalicFontOverride = boldItalicFont;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _savedCornerRadius = nil;
    _updatingCornerRadius = false;

    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.titleLabel.adjustsFontForContentSizeCategory = [BAMessagingCenter instance].enableDynamicType;
    if (@available(iOS 15.0, *)) {
        self.maximumContentSizeCategory = UIContentSizeCategoryExtraExtraExtraLarge;
    }
    // a corner radius change from outside the class needs to trigger a corner radius update
    [self.layer addObserver:self forKeyPath:@"cornerRadius" options:0 context:BAMSGButtonCornerRadiusContext];

    _pressedOverlay = [UIView new];
    _pressedOverlay.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    _pressedOverlay.userInteractionEnabled = NO;
    _pressedOverlay.hidden = YES;
    _pressedOverlay.exclusiveTouch = NO;
    _pressedOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_pressedOverlay];
}

- (void)dealloc {
    @try {
        [self.layer removeObserver:self forKeyPath:@"cornerRadius"];
    } @catch (NSException *__unused exception) {
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == BAMSGButtonCornerRadiusContext) {
        if (!_updatingCornerRadius) { // don't react to changes made from within this class
            _savedCornerRadius = nil;
            [self updateCornerRadius];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];

    [self updateCornerRadius];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _pressedOverlay.frame = self.bounds;
}

- (void)updateCornerRadius {
    _updatingCornerRadius = true;

    if (_savedCornerRadius == nil) {
        _savedCornerRadius = [NSNumber numberWithDouble:self.layer.cornerRadius];
    }

    if (_savedCornerRadius != nil) {
        // corner radius that fits the current bounds. it will be maxed to half the dimension of the view.
        self.layer.cornerRadius =
            MIN(self.bounds.size.height / 2, MIN(self.bounds.size.width / 2, _savedCornerRadius.doubleValue));
    }

    _updatingCornerRadius = false;
}

- (void)setHighlighted:(BOOL)highlighted {
    [UIView transitionWithView:_pressedOverlay
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
                      self->_pressedOverlay.hidden = !highlighted;
                    }
                    completion:nil];

    if (highlighted) {
        [self bringSubviewToFront:_pressedOverlay];
    }

    [super setHighlighted:highlighted];
}

- (void)applyRules:(nonnull BACSSRules *)rules {
    [BAMSGStylableViewHelper applyCommonRules:rules toView:self];

    UIEdgeInsets padding = UIEdgeInsetsZero;

    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys]) {
        NSString *value = rules[rule];

        if ([@"color" isEqualToString:rule]) {
            UIColor *color = [BAMSGStylableViewHelper colorFromValue:value];
            if (color) {
                [self setTitleColor:color forState:UIControlStateNormal];
            }
        }
        // "padding: x x x x" rules have been splitted elsewhere for easier handling
        else if ([@"padding-top" isEqualToString:rule]) {
            padding.top = [value floatValue];
        } else if ([@"padding-bottom" isEqualToString:rule]) {
            padding.bottom = [value floatValue];
        } else if ([@"padding-left" isEqualToString:rule]) {
            padding.left = [value floatValue];
        } else if ([@"padding-right" isEqualToString:rule]) {
            padding.right = [value floatValue];
        }
    }

    // Compute and apply the padding, with respect to its label
    UIEdgeInsets titleInsets = UIEdgeInsetsMake(0.0f, padding.left, 0.0f, -padding.right);
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(padding.top, 0.0f, padding.bottom, padding.left + padding.right);
    self.titleEdgeInsets = titleInsets;
    self.contentEdgeInsets = contentInsets;

    UIFont *customFont = [BAMSGStylableViewHelper fontFromRules:rules
                                                       baseFont:sBAMSGButtonFontOverride
                                                   baseBoldFont:sBAMSGButtonBoldFontOverride];
    if (customFont) {
        self.titleLabel.font = customFont;
    }
}

@end
