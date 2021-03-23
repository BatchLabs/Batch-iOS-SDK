//
//  batchTestsBootstrap.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//


@import Batch.Batch_Private;

// Class that gets instantiated before all tests
// Do one time setup here
@interface batchTestsBootstrap : NSObject

@end

@implementation batchTestsBootstrap

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    BALogger.internalLogsEnabled = true;
}

@end
