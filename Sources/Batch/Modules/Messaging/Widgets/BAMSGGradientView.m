//
//  BAMSGGradientView.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGGradientView.h>

@implementation BAMSGGradientView

- (instancetype)init {
    self = [super init];
    if (self) {
        _touchPassthrough = false;
    }
    return self;
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

+ (void)setupGradientLayer:(CAGradientLayer *)layer
                 withAngle:(float)angle
                    colors:(NSArray<UIColor *> *)colors
                 locations:(NSArray<NSNumber *> *)locations {
    angle = angle / 360;
    // Thanks to http://stackoverflow.com/a/29168654
    // Tweaked to match css3 linear-gradient
    float x1 = pow(sinf((2 * M_PI * ((angle + 0.75) / 2))), 2);
    float y1 = pow(sinf((2 * M_PI * ((angle + 0.5) / 2))), 2);
    float x2 = pow(sinf((2 * M_PI * ((angle + 0.25) / 2))), 2);
    float y2 = pow(sinf((2 * M_PI * ((angle + 0.0) / 2))), 2);

    NSMutableArray *cgColors = [[NSMutableArray alloc] initWithCapacity:colors.count];
    UIColor *color;
    for (int i = 0; i < colors.count; i++) {
        color = colors[i];

        // Automatically replace transparent colors with the previous color in its transparent form.
        // If we don't do that, gradient with a transparent color will turn to a blackish-transparent
        // in the process. That's because clearColor is black, with an alpha of 0.
        if (i > 0 && color == [UIColor clearColor]) {
            color = [colors[i - 1] colorWithAlphaComponent:0];
        }

        [cgColors addObject:(id)color.CGColor];
    }

    [layer setColors:cgColors];
    [layer setStartPoint:CGPointMake(x1, y1)];
    [layer setEndPoint:CGPointMake(x2, y2)];
    [layer setLocations:[locations copy]];
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
    [self setBackgroundColor:[UIColor clearColor]];
    [BAMSGGradientView setupGradientLayer:[self gradientLayer] withAngle:angle colors:colors locations:locations];
}

- (CAGradientLayer *)gradientLayer {
    return (CAGradientLayer *)self.layer;
}

@end

@implementation BAMSGGradientImageView

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

@end
