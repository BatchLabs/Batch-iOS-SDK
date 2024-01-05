//
//  BAMSGViewToolbox.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMSGViewToolbox.h>
#import <Batch/BAWindowHelper.h>

@implementation BAMSGViewToolbox

+ (void)setView:(UIView *)view fullframeToSuperview:(UIView *)superview useSafeArea:(BOOL)useSafeArea {
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];

    if (view.superview != superview) {
        [superview addSubview:view];
    }

    // Safe area might not always be used, and only works on iOS 11+: keep track if we added the constraints
    // as we can't only rely on useSafeArea
    BOOL addedSafeAreaConstraints = false;

    if (useSafeArea) {
        addedSafeAreaConstraints = true;
        UILayoutGuide *safeGuide = superview.safeAreaLayoutGuide;
        NSMutableArray<NSLayoutConstraint *> *safeLayoutConstraints = [NSMutableArray new];
        [safeLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                      attribute:NSLayoutAttributeTop
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:safeGuide
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0
                                                                       constant:0]];

        [safeLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                      attribute:NSLayoutAttributeBottom
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:safeGuide
                                                                      attribute:NSLayoutAttributeBottom
                                                                     multiplier:1.0
                                                                       constant:0]];

        [safeLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                      attribute:NSLayoutAttributeLeft
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:safeGuide
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0
                                                                       constant:0]];

        [safeLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                      attribute:NSLayoutAttributeRight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:safeGuide
                                                                      attribute:NSLayoutAttributeRight
                                                                     multiplier:1.0
                                                                       constant:0]];
        [NSLayoutConstraint activateConstraints:safeLayoutConstraints];
    }

    if (!addedSafeAreaConstraints) {
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
    }
}

+ (CGSize)sceneSize {
    if (@available(iOS 13, *)) {
        // On iOS 13, UIScreen will return the wrong size unless you ask the right scene
        id<UICoordinateSpace> coordinateSpace = [BAWindowHelper activeWindowScene].coordinateSpace;

        if (coordinateSpace != nil) {
            return coordinateSpace.bounds.size;
        } else {
            return [UIWindow new].bounds.size;
        }
    } else {
        // On iOS 9, iPads support split screen, so init a UIWindow, which will have the split's size, and read it
        // iOS 8 would have a 0 sized UIWindow
        return [UIWindow new].bounds.size;
    }
}

+ (nonnull NSString *)localizedStringUsingUIKit:(nonnull NSString *)string {
    NSBundle *appBundle = [NSBundle bundleForClass:[UIApplication class]];
    if (appBundle == nil) {
        return string;
    }
    NSString *localizedString = [appBundle localizedStringForKey:string value:string table:nil];
    if (localizedString == nil) {
        return string;
    }
    return localizedString;
}

@end
