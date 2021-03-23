#import <Batch/BAMSGBaseContainerView.h>

@implementation BAMSGBaseContainerView
{
    // corner radius set outside the class
    float _cornerRadius;
    // corner radius that fits the current bounds. it will be maxed to half the dimension of the view.
    float _fittingCornerRadius;
    BOOL _touchPassthrough;
    BAMSGGradientView *_contentView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _touchPassthrough = false;
    _cornerRadius = 0;
    _fittingCornerRadius = 0;
    _rasterizeShadow = true;
    
    CALayer *layer = self.layer;
    layer.masksToBounds = false;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeZero;
    layer.shadowRadius = 0;
    
    _contentView = [BAMSGGradientView new];
    _contentView.translatesAutoresizingMaskIntoConstraints = false;
    _contentView.layer.masksToBounds = true;
    [self _addRootSubview:_contentView];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[_contentView]-(0)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(_contentView)]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[_contentView]-(0)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(_contentView)]];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!_touchPassthrough) {
        return [super hitTest:point withEvent:event];
    }
    
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        return nil;
    }
    return hitView;
}

- (CALayer *)contentLayer {
    return _contentView.layer;
}

- (void)_addRootSubview:(UIView *)view {
    [super addSubview:view];
}

- (void)addSubview:(UIView *)view {
    [_contentView addSubview:view];
}

- (void)sendSubviewToBack:(UIView *)view {
    [_contentView sendSubviewToBack:view];
}

- (void)bringSubviewToFront:(UIView *)view {
    [_contentView bringSubviewToFront:view];
}

- (void)removeAllSubviews {
    [[_contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_contentView removeConstraints:[_contentView constraints]];
}

- (CGSize)intrinsicContentSize {
    return [_contentView intrinsicContentSize];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // update corner radius for current bounds
    [self setCornerRadius:_cornerRadius];

    [self regenerateShadow];
}

- (void)regenerateShadow {
    if (_rasterizeShadow) {
        if (_cornerRadius == 0) {
            self.layer.shadowPath = [UIBezierPath bezierPathWithRect:_contentView.bounds].CGPath;
        } else {
            self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_contentView.bounds cornerRadius:_fittingCornerRadius].CGPath;
        }
    } else {
        self.layer.shadowPath = nil;
    }
}

- (float)cornerRadius {
    return _cornerRadius;
}

- (void)setCornerRadius:(float)cornerRadius {
    _cornerRadius = cornerRadius;

    _fittingCornerRadius = MIN(_contentView.bounds.size.height / 2, MIN(_contentView.bounds.size.width / 2, cornerRadius));

    _contentView.layer.cornerRadius = _fittingCornerRadius;
    [self regenerateShadow];
}

- (float)shadowRadius {
    return self.layer.shadowRadius;
}

- (void)setShadowRadius:(float)shadowRadius {
    self.layer.shadowRadius = shadowRadius;
}

- (UIColor *)shadowColor {
    return [UIColor colorWithCGColor:self.layer.shadowColor];
}

- (void)setShadowColor:(UIColor *)shadowColor {
    if (shadowColor) {
        self.layer.shadowColor = shadowColor.CGColor;
    }
}

- (float)shadowOpacity {
    return self.layer.shadowOpacity;
}

- (void)setShadowOpacity:(float)shadowOpacity {
    self.layer.shadowOpacity = shadowOpacity;
}

- (BOOL)touchPassthrough {
    return _touchPassthrough;
}

- (void)setTouchPassthrough:(BOOL)touchPassthrough {
    _touchPassthrough = touchPassthrough;
    _contentView.touchPassthrough = touchPassthrough;
}

- (void)setRasterizeShadow:(BOOL)rasterizeShadow {
    _rasterizeShadow = rasterizeShadow;
    
    [self regenerateShadow];
}

#pragma mark Gradient

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [_contentView setBackgroundColor:backgroundColor];
}

- (void)setBackgroundGradient:(float)angle colors:(NSArray*)colors locations:(NSArray*)locations
{
    [_contentView setBackgroundGradient:angle colors:colors locations:locations];
}

@end
