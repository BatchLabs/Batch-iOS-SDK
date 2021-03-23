#import <Batch/BAMSGBaseContainerView.h>
#import <Batch/BAMSGPannableContainerView.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BAMSGPannableAnchoredContainerVerticalAnchor) {
    BAMSGPannableAnchoredContainerVerticalAnchorOther = 0,
    BAMSGPannableAnchoredContainerVerticalAnchorTop,
    BAMSGPannableAnchoredContainerVerticalAnchorBottom,
};

/**
 Pannable container view for banners anchored to a edge of the screen
 */
@interface BAMSGPannableAnchoredContainerView : BAMSGBaseContainerView <BAMSGPannableContainerView>

@property (weak, nullable) id<BAMSGPannableContainerViewDelegate> delegate;

@property BAMSGPannableAnchoredContainerVerticalAnchor verticalAnchor;

/**
 The biggest visible view displayed.
 This is used for automatic dismissal based on hiding a percentage of the visible view's height.
 Overriding this is useful when the container view is mostly transparent
 
 If not set, dismissal will only be based on velocity
 */
@property (weak, nullable) UIView *biggestUserVisibleView;

@end

NS_ASSUME_NONNULL_END
