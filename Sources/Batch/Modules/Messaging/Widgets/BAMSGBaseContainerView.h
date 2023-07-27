#import <UIKit/UIKit.h>

#import <Batch/BAMSGGradientView.h>
#import <Batch/BAMSGPassthroughProtocol.h>

@protocol BAMSGContainerViewProtocol
@required

- (CALayer *)contentLayer;

@end

@interface BAMSGBaseContainerView
    : UIView <BAMSGGradientBackgroundProtocol, BAMSGContainerViewProtocol, BAMSGPasstroughProtocol>

@property float cornerRadius;

@property float shadowRadius;

@property UIColor *shadowColor;

@property float shadowOpacity;

@property BOOL touchPassthrough;

@property (nonatomic) BOOL rasterizeShadow;

- (void)removeAllSubviews;

@end
