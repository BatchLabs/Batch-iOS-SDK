//
//  BANotificationCenter.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

// Batch notifications:
#define kNotificationBatchStarts @"notification.start"
#define kNotificationBatchStops @"notification.stop"

/*!
 @class BANotificationCenter
 @abstract The private notification center.
 */
@interface BANotificationCenter : NSNotificationCenter

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method defaultCenter
 @abstract Singleton accessor.
 @return The unique instance of this object.
 */
+ (instancetype)defaultCenter __attribute__((warn_unused_result));

@end
