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

- (BOOL)batchMessageDidTriggerAction:(BatchMessageAction *_Nonnull)action
                   messageIdentifier:(NSString *)identifier
                       ctaIdentifier:(NSString *_Nonnull)ctaIdentifier {
    if ([_delegate respondsToSelector:@selector(batchMessageDidTriggerAction:messageIdentifier:ctaIdentifier:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchMessageDidTriggerAction:action
                                      messageIdentifier:identifier
                                          ctaIdentifier:ctaIdentifier];
        }];
        return true;
    }
    return false;
}

- (BOOL)batchMessageDidDisappear:(NSString *)identifier reason:(BatchMessagingCloseReason)reason {
    if ([_delegate respondsToSelector:@selector(batchMessageDidDisappear:reason:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchMessageDidDisappear:identifier reason:reason];
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
