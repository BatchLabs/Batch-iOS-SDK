//
//  BAMSGGradientView.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAMSGPassthroughProtocol.h>

@protocol BAMSGGradientBackgroundProtocol <NSObject>

- (void)setBackgroundGradient:(float)angle colors:(NSArray *)colors locations:(NSArray *)locations;

@end

@interface BAMSGGradientView : UIView <BAMSGGradientBackgroundProtocol, BAMSGPasstroughProtocol>

+ (void)setupGradientLayer:(CAGradientLayer *)layer
                 withAngle:(float)angle
                    colors:(NSArray<UIColor *> *)colors
                 locations:(NSArray<NSNumber *> *)locations;

@property BOOL touchPassthrough;

@end

@interface BAMSGGradientImageView : UIImageView <BAMSGGradientBackgroundProtocol>

@end
