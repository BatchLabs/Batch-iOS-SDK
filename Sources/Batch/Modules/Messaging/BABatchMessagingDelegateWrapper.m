//
//  BABatchMessagingDelegateWrapper.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BABatchMessagingDelegateWrapper.h>
#import <Batch/BAErrorHelper.h>
#import <Batch/BAThreading.h>

@implementation BABatchMessagingDelegateWrapper

- (instancetype)initWithDelgate:(id<BatchMessagingDelegate>)delegate {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    if ([delegate conformsToProtocol:@protocol(BatchMessagingDelegate)]) {
        _delegate = delegate;
    } else {
        _delegate = nil;
        // Only log if the delegate is not nil : nil is a valid value
        if (delegate) {
            [BALogger publicForDomain:@"Messaging"
                              message:@"%@", [[BAErrorHelper errorInvalidMessagingDelegate] localizedDescription]];
        }
    }

    return self;
}

- (BOOL)hasWrappedDelegate {
    return _delegate != nil;
}

#pragma mark -
#pragma mark BatchMessagingDelegate

- (BOOL)batchMessageDidAppear:(NSString *)identifier {
    if ([_delegate respondsToSelector:@selector(batchMessageDidAppear:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchMessageDidAppear:identifier];
        }];
        return true;
    }
    return false;
}

- (BOOL)batchMessageWasCancelledByUserAction:(NSString *)identifier {
    if ([_delegate respondsToSelector:@selector(batchMessageWasCancelledByUserAction:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchMessageWasCancelledByUserAction:identifier];
        }];
        return true;
    }
    return false;
}

- (BOOL)batchMessageWasCancelledByAutoclose:(NSString *)identifier {
    if ([_delegate respondsToSelector:@selector(batchMessageWasCancelledByAutoclose:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchMessageWasCancelledByAutoclose:identifier];
        }];
        return true;
    }
    return false;
}

- (BOOL)batchMessageDidTriggerAction:(BatchMessageAction *_Nonnull)action
                   messageIdentifier:(NSString *)identifier
                         actionIndex:(NSInteger)index {
    if ([_delegate respondsToSelector:@selector(batchMessageDidTriggerAction:messageIdentifier:actionIndex:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchMessageDidTriggerAction:action messageIdentifier:identifier actionIndex:index];
        }];
        return true;
    }
    return false;
}

- (BOOL)batchMessageDidDisappear:(NSString *)identifier {
    if ([_delegate respondsToSelector:@selector(batchMessageDidDisappear:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchMessageDidDisappear:identifier];
        }];
        return true;
    }
    return false;
}

- (BOOL)batchInAppMessageReady:(BatchInAppMessage *)message {
    if ([_delegate respondsToSelector:@selector(batchInAppMessageReady:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchInAppMessageReady:message];
        }];
        return true;
    }
    return false;
}

- (BOOL)batchMessageWasCancelledByError:(NSString *_Nullable)messageIdentifier {
    if ([_delegate respondsToSelector:@selector(batchMessageWasCancelledByError:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchMessageWasCancelledByError:messageIdentifier];
        }];
        return true;
    }
    return false;
}

- (BOOL)batchWebViewMessageDidTriggerAction:(BatchMessageAction *_Nullable)action
                          messageIdentifier:(NSString *_Nullable)messageIdentifier
                        analyticsIdentifier:(NSString *_Nullable)analyticsIdentifier {
    if ([_delegate respondsToSelector:@selector(batchWebViewMessageDidTriggerAction:
                                                                  messageIdentifier:analyticsIdentifier:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchWebViewMessageDidTriggerAction:action
                                             messageIdentifier:messageIdentifier
                                           analyticsIdentifier:analyticsIdentifier];
        }];
        return true;
    }
    return false;
}

- (UIViewController *)presentingViewControllerForBatchUI {
    if ([_delegate respondsToSelector:@selector(presentingViewControllerForBatchUI)]) {
        return [_delegate presentingViewControllerForBatchUI];
    }
    return nil;
}

@end
