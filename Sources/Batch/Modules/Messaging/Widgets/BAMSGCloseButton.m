//
//  BAMSGCloseButton.m
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGCloseButton.h>
#import <QuartzCore/QuartzCore.h>

#define BAMSGCLOSE_DEFAULT_SIZE 32
#define BAMSGCLOSE_GLYPH_BASE_PADDING 10
#define BAMSGCLOSE_GLYPH_BASE_WIDTH 2

@interface BAMSGCloseButton ()
{
    CALayer *_pressedLayer;
    CAShapeLayer *_progressLayer;
    CAShapeLayer *_borderLayer;
    
    float _computedGlyphPadding;
    float _computedGlyphWidth;
}

@end

@implementation BAMSGCloseButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    // Do not move this after self.glyphColor's assignation, as it relies on the property's setter
    [self setupExtraLayers];
    
    self.layer.masksToBounds = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [UIColor blackColor];
    self.glyphColor = [UIColor whiteColor];
    self.accessibilityHint = @"Close";
    self.showBorder = false;

    _computedGlyphPadding = 0;
    _computedGlyphWidth = 0;
    
    _pressedLayer = [CALayer layer];
    _pressedLayer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6].CGColor;
    _pressedLayer.hidden = YES;
    [self.layer addSublayer:_pressedLayer];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGSize minimumHitArea = CGSizeMake(60, 60);

    // if the button is hidden/disabled/transparent it can't be hit
    if (self.isHidden || !self.enabled || !self.userInteractionEnabled || self.alpha < 0.01) { return nil; }

    CGSize buttonSize = self.bounds.size;
    CGFloat widthToAdd = MAX(minimumHitArea.width - buttonSize.width, 0);
    CGFloat heightToAdd = MAX(minimumHitArea.height - buttonSize.height, 0);
    CGRect largerBounds = CGRectInset(self.bounds, -widthToAdd / 2, -heightToAdd / 2);

    // perform hit test on larger bounds
    return CGRectContainsPoint(largerBounds, point) ? self : nil;
}

- (void)setupExtraLayers
{
    _progressLayer = [CAShapeLayer layer];
    
    // For some reason, the stroke starts at 90°
    // Rotate the circle a quarter of a circle backwards to set it at 0°
    [_progressLayer setValue:@(-M_PI/2) forKeyPath:@"transform.rotation.z"];
    
    _progressLayer.fillColor = NULL;
    _progressLayer.strokeColor = NULL;
    _progressLayer.lineWidth = BAMSGCLOSE_GLYPH_BASE_WIDTH;
    _progressLayer.lineCap = kCALineCapButt;
    _progressLayer.strokeStart = 0;
    _progressLayer.strokeEnd = 0;
    
    [self.layer addSublayer:_progressLayer];

    _borderLayer = [CAShapeLayer layer];

    _borderLayer.fillColor = NULL;
    _borderLayer.strokeColor = NULL;
    // 1 point-width border
    _borderLayer.lineWidth = 1.5;
    _borderLayer.strokeStart = 0;
    _borderLayer.strokeEnd = 1;

    [self.layer addSublayer:_borderLayer];
}

- (void)prepareCountdown
{
    _progressLayer.strokeEnd = 1;
}

- (void)animateCountdownForDuration:(CFTimeInterval)duration completionHandler:(nullable void (^)(void))completionHandler
{
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration];
    if (completionHandler != nil) {
        [CATransaction setCompletionBlock:completionHandler];
    }
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = [NSNumber numberWithDouble:1];
    animation.toValue = [NSNumber numberWithDouble:0];
    
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.removedOnCompletion = YES;
    _progressLayer.strokeEnd = 0;
    [_progressLayer addAnimation:animation forKey:@"countdown"];
    
    [CATransaction commit];
}

- (void)setGlyphColor:(UIColor *)glyphColor
{
    _glyphColor = glyphColor;
    if (glyphColor) {
        [_progressLayer setStrokeColor:glyphColor.CGColor];
        [_borderLayer setStrokeColor:glyphColor.CGColor];
    }
}

- (void)setShowBorder:(BOOL)showBorder
{
    _showBorder = showBorder;
    _borderLayer.hidden = !_showBorder;
}

- (void)setHighlighted:(BOOL)highlighted
{
    _pressedLayer.hidden = !highlighted;
    
    [super setHighlighted:highlighted];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, self.glyphColor.CGColor);
    CGFloat lineWidth = _computedGlyphWidth;
    CGContextSetLineWidth(context, lineWidth);
    CGPoint startPoint = CGPointMake(rect.origin.x + _computedGlyphPadding, rect.origin.y + _computedGlyphPadding);
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(rect) - _computedGlyphPadding, CGRectGetMaxY(rect) - _computedGlyphPadding);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, self.glyphColor.CGColor);
    CGContextSetLineWidth(context, lineWidth);
    startPoint = CGPointMake(CGRectGetMaxX(rect) - _computedGlyphPadding, rect.origin.y + _computedGlyphPadding);
    endPoint = CGPointMake(rect.origin.x + _computedGlyphPadding, CGRectGetMaxY(rect) - _computedGlyphPadding);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    
    self.layer.cornerRadius = self.frame.size.height / 2;
    _pressedLayer.frame = bounds;
    _progressLayer.frame = bounds;
    _borderLayer.frame = bounds;
    
    // Glyph padding scales up with button size, so does the line width
    float scalingRatio = (self.frame.size.height / BAMSGCLOSE_DEFAULT_SIZE);
    _computedGlyphPadding = self.glyphPadding != nil ? [self.glyphPadding floatValue] : scalingRatio * BAMSGCLOSE_GLYPH_BASE_PADDING;
    _computedGlyphWidth = self.glyphWidth != nil ? [self.glyphWidth floatValue] : scalingRatio * BAMSGCLOSE_GLYPH_BASE_WIDTH;
    
    // Update the progress layer path:
    // Add some padding between the stroke and the outer circle to make it look like it's in the close button
    // We achieve that by making a the path a circle smaller than the outer one, accounting for the stroke expanding half of it's specified width outside of the circle it follows,
    // plus some additional padding for our desired style.
    // It's okay if you don't understand that comment.
    float paddedGlyphWidth = _computedGlyphWidth + 2*scalingRatio;
    CGRect progressPathFrame = CGRectMake(paddedGlyphWidth/2, paddedGlyphWidth/2, bounds.size.width-paddedGlyphWidth, bounds.size.height-paddedGlyphWidth);

    _progressLayer.lineWidth = _computedGlyphWidth;
    _progressLayer.path = CFAutorelease(CGPathCreateWithEllipseInRect(progressPathFrame, 0));

    // we want outer border of borderLayer to match outer border of the button
    CGRect borderPathFrame = CGRectInset(bounds, _borderLayer.lineWidth / 2, _borderLayer.lineWidth / 2);
    _borderLayer.path = CFAutorelease(CGPathCreateWithEllipseInRect(borderPathFrame, 0));
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(BAMSGCLOSE_DEFAULT_SIZE, BAMSGCLOSE_DEFAULT_SIZE);
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
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
                self.glyphColor = color;
            }
        }
        else if ([@"glyph-padding" isEqualToString:rule])
        {
            self.glyphPadding = @([value floatValue]);
        }
        else if ([@"glyph-width" isEqualToString:rule])
        {
            self.glyphWidth = @([value floatValue]);
        }
    }
}

@end
