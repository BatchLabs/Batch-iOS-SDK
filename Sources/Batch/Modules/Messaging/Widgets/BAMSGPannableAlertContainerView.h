//
//  BAMSGPannableAlertContainerView.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMSGBaseContainerView.h>
#import <Batch/BAMSGPannableContainerView.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAMSGPannableAlertContainerView : BAMSGBaseContainerView <BAMSGPannableContainerView>

@property (weak, nullable) id<BAMSGPannableContainerViewDelegate> delegate;

/** Lock interaction vertically if true. Allowed in all directions if false. Default to YES. */
@property (nonatomic, assign) BOOL lockVertically;

/** If true, snap the view back in default position when dismissing. Default to YES. */
@property (nonatomic, assign) BOOL resetPositionOnDismiss;

/**
 Link a view to this one
 Linked views will be applied the same transform and alpha changes when this view is dragged

 This only supports one linked view for now, as we only have one to deal with as of writing
 */
- (void)setLinkedView:(nonnull UIView *)linkedView;

@end

NS_ASSUME_NONNULL_END
