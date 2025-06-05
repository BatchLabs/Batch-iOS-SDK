//
//  BABatchMessagingDelegateWrapper.h
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
@interface BABatchMessagingDelegateWrapper : NSObject

@property (nonatomic, weak, readonly, nullable) id<BatchMessagingDelegate> delegate;

/*!
 @method initWithDelgate:
 @abstract Create the BatchDelegate wrapper.
 @return The wrapper or nil.
 */
- (nullable instancetype)initWithDelgate:(nullable id<BatchMessagingDelegate>)delegate;

/*!
 @method hasWrappedDelegate
 @abstract Check if a delegate is currently wrapped or not
 @return YES if a delegate is wrapped, NO otherwise.
 */
- (BOOL)hasWrappedDelegate;

- (BOOL)batchMessageDidAppear:(nullable NSString *)messageIdentifier;

- (BOOL)batchMessageDidTriggerAction:(nonnull BatchMessageAction *)action
                   messageIdentifier:(nullable NSString *)identifier
                       ctaIdentifier:(NSString *_Nonnull)ctaIdentifier;

- (BOOL)batchMessageDidDisappear:(nullable NSString *)messageIdentifier reason:(BatchMessagingCloseReason)reason;

- (nullable UIViewController *)presentingViewControllerForBatchUI;

@end
