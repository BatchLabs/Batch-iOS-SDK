//
//  BAMSGActivityIndicatorView.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Batch/BAMSGStylableView.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BAMSGActivityIndicatorViewSize) {
    BAMSGActivityIndicatorViewSizeMedium,
    BAMSGActivityIndicatorViewSizeLarge,
};

typedef NS_ENUM(NSUInteger, BAMSGActivityIndicatorViewColor) {
    BAMSGActivityIndicatorViewColorLight,
    BAMSGActivityIndicatorViewColorDark,
};

@interface BAMSGActivityIndicatorView : UIActivityIndicatorView <BAMSGStylableView>

- (instancetype)initWithPreferredSize:(BAMSGActivityIndicatorViewSize)size NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style __attribute__((deprecated("Use initWithPreferredSize:"))) NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

// Preferred size.
// Equivalent to UIActivityIndicatorView.Style.Large and .Medium, but in a retrocompatible way
// On iOS 12 and lower, this value will have no effect and will force BAMSGActivityIndicatorViewSizeMedium
@property (assign) BAMSGActivityIndicatorViewSize preferredSize;

// Preferred color.
// Retrocompatible way to set a predefined color using the latest supported APIs with compatibility
// for iOS 12 and lower
@property (assign) BAMSGActivityIndicatorViewColor preferredColor;

@end

NS_ASSUME_NONNULL_END
