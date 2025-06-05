//
//  BABatchInAppDelegateWrapper.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BABatchInAppDelegateWrapper.h>
#import <Batch/BAErrorHelper.h>
#import <Batch/BAThreading.h>
#import <Batch/BatchMessaging.h>

@implementation BABatchInAppDelegateWrapper

- (instancetype)initWithDelgate:(id<BatchInAppDelegate>)delegate {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    if ([delegate conformsToProtocol:@protocol(BatchInAppDelegate)]) {
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
#pragma mark BatchInAppDelegate

- (BOOL)batchInAppMessageReady:(BatchInAppMessage *)message {
    if ([_delegate respondsToSelector:@selector(batchInAppMessageReady:)]) {
        [BAThreading performBlockOnMainThreadAsync:^{
          [self->_delegate batchInAppMessageReady:message];
        }];
        return true;
    }
    return false;
}

@end
