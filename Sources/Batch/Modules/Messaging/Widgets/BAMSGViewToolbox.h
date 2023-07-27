//
//  BAMSGViewToolbox.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BAMSGViewToolbox : UIViewController

/// Set a view to be the same size than it's parent
/// @param view view to constraint
/// @param superview parent view
/// @param useSafeArea Use the safe area as inset, or constraint the view to it. true: constraint the child view to the
/// safeAreaLayoutGuide, applying insets outside of the view
///                          false: the view will be exactly the same size as the parent is and should handle the safe
///                          area using insets
+ (void)setView:(nonnull UIView *)view fullframeToSuperview:(nonnull UIView *)superview useSafeArea:(BOOL)useSafeArea;

/// Returns the current scene size
/// Prior to iOS 13, this returns the screen size, or the size of the split the app
/// is running it on a multitasking iPad
/// On catalyst, this is the window size
+ (CGSize)sceneSize;

/// Get a string localized by UIKit's builtin localizations
/// Useful for common stuff
+ (nonnull NSString *)localizedStringUsingUIKit:(nonnull NSString *)string;

@end
