//
//  BAMSGImageView.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import <Batch/BAMSGImageView.h>

@interface BAMSGImageView () {
    BOOL hasBackgroundColor;
    float blurRadius;
    int blurIterations;

    float borderRadius;

    UIImage *_baseImage;
    UIImage *_blurredImage;
}

@end

@implementation BAMSGImageView

+ (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations baseImage:(UIImage *)image {
    // image must be nonzero size
    if (floorf(image.size.width) * floorf(image.size.height) <= 0.0f) {
        return image;
    }

    // boxsize must be an odd integer
    uint32_t boxSize = (uint32_t)(radius * image.scale);
    if (boxSize % 2 == 0) {
        boxSize++;
    }

    // create image buffers
    CGImageRef imageRef = image.CGImage;
    vImage_Buffer buffer1, buffer2;
    buffer1.width = buffer2.width = CGImageGetWidth(imageRef);
    buffer1.height = buffer2.height = CGImageGetHeight(imageRef);
    buffer1.rowBytes = buffer2.rowBytes = CGImageGetBytesPerRow(imageRef);
    size_t bytes = buffer1.rowBytes * buffer1.height;
    buffer1.data = malloc(bytes);
    buffer2.data = malloc(bytes);

    // create temp buffer
    void *tempBuffer = malloc((size_t)vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize, NULL,
                                                                 kvImageEdgeExtend + kvImageGetTempBufferSize));

    // copy image data
    CFDataRef dataSource = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    memcpy(buffer1.data, CFDataGetBytePtr(dataSource), bytes);
    CFRelease(dataSource);

    void *temp;
    for (NSUInteger i = 0; i < iterations; i++) {
        // perform blur
        vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);

        // swap buffers
        temp = buffer1.data;
        buffer1.data = buffer2.data;
        buffer2.data = temp;
    }

    // free buffers
    free(buffer2.data);
    free(tempBuffer);

    // create image context from buffer
    CGContextRef ctx = CGBitmapContextCreate(buffer1.data, buffer1.width, buffer1.height, 8, buffer1.rowBytes,
                                             CGImageGetColorSpace(imageRef), CGImageGetBitmapInfo(imageRef));

    // create image from context
    imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *blurredImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(buffer1.data);

    return blurredImage;
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
    self.clipsToBounds = YES;
    self.layer.masksToBounds = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.alwaysShowImage = YES;
    self.enableIntrinsicContentSize = YES;
    hasBackgroundColor = NO;
    blurRadius = 0;
    blurIterations = 1;
    borderRadius = 0;
    _roundedCorners = UIRectCornerAllCorners;

    [self setAccessibilityIgnoresInvertColors:YES];
}

- (void)setImage:(UIImage *)image {
    _baseImage = image;
    _blurredImage = nil;

    if (blurRadius > 0) {
        _blurredImage = [BAMSGImageView blurredImageWithRadius:blurRadius iterations:blurIterations baseImage:image];
        [super setImage:_blurredImage];
        return;
    }

    if (self.alwaysShowImage) {
        [super setImage:image];
    } else {
        // Only if the view doesn't always need an image (so basically background views)
        // If there's no blur, we fallback on the gradient, color, or just transparent
        // It means that the blur can't be changed once the image is set, but that's not an issue here
        [super setImage:nil];
    }
}

- (CGSize)intrinsicContentSize {
    return self.enableIntrinsicContentSize ? [super intrinsicContentSize] : CGSizeZero;
}

- (void)layoutSubviews {
    if (self.roundedCorners == UIRectCornerAllCorners || borderRadius <= 0) {
        self.layer.cornerRadius = borderRadius;
        self.layer.mask = nil;
    } else {
        self.layer.cornerRadius = 0;
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                       byRoundingCorners:self.roundedCorners
                                                             cornerRadii:CGSizeMake(borderRadius, borderRadius)];

        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.bounds;
        maskLayer.path = maskPath.CGPath;

        self.layer.mask = maskLayer;
    }
}

- (void)applyRules:(nonnull BACSSRules *)rules {
    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys]) {
        NSString *value = rules[rule];

        // Setting background-color disables the image
        if ([@"background-color" isEqualToString:rule]) {
            UIColor *color = [BAMSGStylableViewHelper colorFromValue:value];
            if (color) {
                hasBackgroundColor = YES;
                self.backgroundColor = color;
                self.image = nil;
            }
        } else if ([@"blur" isEqualToString:rule]) {
            blurRadius = [value floatValue];
        } else if ([@"blur-iterations" isEqualToString:rule]) {
            blurIterations = (int)MAX(0, [value integerValue]);
        } else if ([@"border-radius" isEqualToString:rule]) {
            borderRadius = [value floatValue];
        } else if ([@"scale" isEqualToString:rule]) {
            if ([@"fit" isEqualToString:value]) {
                self.contentMode = UIViewContentModeScaleAspectFit;
            } else if ([@"fill" isEqualToString:value]) {
                self.contentMode = UIViewContentModeScaleAspectFill;
            }
        } else if ([@"rounded-corners" isEqualToString:rule]) {
            if ([@"all" isEqualToString:value]) {
                self.roundedCorners = UIRectCornerAllCorners;
            } else if ([@"left" isEqualToString:value]) {
                self.roundedCorners = UIRectCornerTopLeft | UIRectCornerBottomLeft;
            } else if ([@"right" isEqualToString:value]) {
                self.roundedCorners = UIRectCornerTopRight | UIRectCornerBottomRight;
            } else if ([@"top" isEqualToString:value]) {
                self.roundedCorners = UIRectCornerTopLeft | UIRectCornerTopRight;
            } else if ([@"bottom" isEqualToString:value]) {
                self.roundedCorners = UIRectCornerBottomLeft | UIRectCornerBottomRight;
            }
        }
    }

    [self setImage:_baseImage];
}

@end
