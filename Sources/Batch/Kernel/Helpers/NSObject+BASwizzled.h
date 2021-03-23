//
//  NSObject+BASwizzled.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BASwizzledObject : NSObject
@end

@interface NSObject (BASwizzled)

/*!
 @property additionalDelegate
 @abstract Delegate to call for implemented UIApplicationDelegate methods.
 */
@property (nonatomic, strong) id<UIApplicationDelegate> additionalDelegate;

/*!
 @method swizzleForDelegate:
 @abstract Swizzle the current [UIApplication sharedApplication].delegate class for many UIApplicationDelegate methods.
 @param delegate    :   Object catching UIApplicationDelegate methods.
 @return The singleton object.
 */
+ (instancetype)swizzleForDelegate:(id<UIApplicationDelegate>)delegate;

@end
