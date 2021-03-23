//
//  BAMSGStackViewItem.h
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BACSS.h>

@import UIKit;

@interface BAMSGStackViewItem : NSObject

@property (nonnull) BACSSRules* rules;
@property (nullable) UIView* view;
@property BOOL attachToParentBottom;

- (nonnull NSArray<NSLayoutConstraint*>*)computeConstraints;

// "Private" properties, that will be set by the stack view
@property (nullable, weak) UIView* previousView;
@property (nullable, weak) UIView* nextView;
@property (nullable, weak) UIView* parentView;

@end

@interface BAMSGStackViewSeparatorItem : BAMSGStackViewItem

@end
