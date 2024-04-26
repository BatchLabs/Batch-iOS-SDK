//
//  BAWindowHelper.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAWindowHelper : NSObject

+ (nullable UIWindowScene *)activeScene;

+ (nullable UIWindowScene *)activeWindowScene;

+ (nullable UIWindow *)keyWindow;

+ (nullable UIViewController *)frontmostViewController;

@end

NS_ASSUME_NONNULL_END
