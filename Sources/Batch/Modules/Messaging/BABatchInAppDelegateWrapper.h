//
//  BABatchInAppDelegateWrapper.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BatchMessaging.h>
#import <Foundation/Foundation.h>

/**
 Delegate wrapping the dev's supplied messaging delegate.
 Calls to these methods are safe, no matter whether there is a delegate or not, and if it implements the required
 methods or not.

 Methods usually returning void will return BOOL, indicating if the delegate implemented them and the invocations were
 forwared to it.
 */
@interface BABatchInAppDelegateWrapper : NSObject

@property (nonatomic, weak, readonly, nullable) id<BatchInAppDelegate> delegate;

/*!
 @method initWithDelgate:
 @abstract Create the BatchInAppDelegate wrapper.
 @return The wrapper or nil.
 */
- (nullable instancetype)initWithDelgate:(nullable id<BatchInAppDelegate>)delegate;

/*!
 @method hasWrappedDelegate
 @abstract Check if a delegate is currently wrapped or not
 @return YES if a delegate is wrapped, NO otherwise.
 */
- (BOOL)hasWrappedDelegate;

- (BOOL)batchInAppMessageReady:(nonnull BatchInAppMessage *)message;

@end
