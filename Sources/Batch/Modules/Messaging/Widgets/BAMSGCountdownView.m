#import <Batch/BAMSGCountdownView.h>

@implementation BAMSGCountdownView
{
    UIView *_progressView;
    NSLayoutConstraint *_widthPercentageConstraint;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _progressView = [UIView new];
    _progressView.backgroundColor = [UIColor blackColor];
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_progressView];
    
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[_progressView]-(0)-|"
                                                                                    options:0
                                                                                    metrics:nil
                                                                                      views:NSDictionaryOfVariableBindings(_progressView)]];
    
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[_progressView]"
                                                                                    options:0
                                                                                    metrics:nil
                                                                                      views:NSDictionaryOfVariableBindings(_progressView)]];
    
    [self setPercentage:1.0];
}

- (void)setPercentage:(float)percentage
{
    if (_widthPercentageConstraint != nil) {
        [NSLayoutConstraint deactivateConstraints:@[_widthPercentageConstraint]];
    }
    
    _widthPercentageConstraint = [NSLayoutConstraint constraintWithItem:_progressView
                                                              attribute:NSLayoutAttributeWidth
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeWidth
                                                             multiplier:percentage
                                                               constant:0];
    
    [NSLayoutConstraint activateConstraints:@[_widthPercentageConstraint]];
    [self layoutIfNeeded];
}

- (void)setColor:(UIColor*)color
{
    _progressView.backgroundColor = color;
}

- (void)applyRules:(nonnull BACSSRules*)rules
{
    [BAMSGStylableViewHelper applyCommonRules:rules toView:self];
    
    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys])
    {
        NSString *value = rules[rule];
        
        if ([@"color" isEqualToString:rule])
        {
            UIColor *color = [BAMSGStylableViewHelper colorFromValue:value];
            if (color)
            {
                [self setColor:color];
            }
        }
    }
}

@end
