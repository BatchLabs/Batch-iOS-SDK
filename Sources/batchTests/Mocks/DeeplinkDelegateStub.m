//
//  DeeplinkDelegateStub.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import "DeeplinkDelegateStub.h"

@implementation DeeplinkDelegateStub

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hasOpenBeenCalled = false;
    }
    return self;
}

- (void)openBatchDeeplink:(NSString *)deeplink {
    self.hasOpenBeenCalled = true;
}

@end
