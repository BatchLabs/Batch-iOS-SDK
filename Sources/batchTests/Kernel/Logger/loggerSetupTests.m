//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
@import Batch.Batch_Private;
#import "OCMock.h"

@interface loggerSetupTests : XCTestCase

@end

@implementation loggerSetupTests

+ (void)tearDown {
    BALogger.internalLogsEnabled = false;
}

- (void)testEnableInternalLogsWithArgument {
    BALogger.internalLogsEnabled = false;

    NSMutableArray *mockArguments = [NSMutableArray new];

    id nsProcessMock = OCMClassMock([NSProcessInfo class]);
    OCMStub([nsProcessMock processInfo]).andReturn(nsProcessMock);
    OCMStub([nsProcessMock arguments]).andReturn(mockArguments);

    [BALogger setup];
    XCTAssertFalse(BALogger.internalLogsEnabled);

    [mockArguments addObject:@"-BatchSDKEnableInternalLogs"];
    [BALogger setup];
    XCTAssertTrue(BALogger.internalLogsEnabled);
}

@end
