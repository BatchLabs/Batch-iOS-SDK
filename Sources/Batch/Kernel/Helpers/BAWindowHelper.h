//
//  BAWindowHelper.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAWindowHelper : NSObject

+ (nullable UIWindowScene*)activeScene NS_AVAILABLE_IOS(13.0);

+ (nullable UIWindowScene*)activeWindowScene NS_AVAILABLE_IOS(13.0);

+ (nullable UIWindow*)keyWindow;

@end

NS_ASSUME_NONNULL_END
