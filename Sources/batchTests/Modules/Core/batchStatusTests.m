//
//  BatchStatusTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>
#import <XCTest/XCTest.h>

#import "OCMock.h"

#import "BAStatus.h"

@interface BatchStatusTests : XCTestCase

@end

@implementation BatchStatusTests

- (void)setUp {
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown {
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testState {
    id unNotificationMock = OCMClassMock([UNUserNotificationCenter class]);
    OCMExpect([unNotificationMock currentNotificationCenter]).andReturn(nil);

    // Test instantiation.
    BAStatus *s = [[BAStatus alloc] init];
    XCTAssertNotNil(s, @"Failed to instantiate a BAStatus.");

    NSError *error;
    error = [s initialization];
    XCTAssertNil(error, @"Error on first initialization.");
    error = [s initialization];
    XCTAssertNotNil(error, @"No error found on a second initialization.");

    // Test default status.
    XCTAssertFalse([s isRunning], @"Default state after instantiation is not 'NO'.");

    // Test regular start.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    [s start];
#pragma clang diagnostic pop
    XCTAssertTrue([s isRunning], @"Fail to set state in START mode.");

    // Test regular stop.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    [s stop];
#pragma clang diagnostic pop
    XCTAssertFalse([s isRunning], @"Fail to set state in STOP mode.");

    error = [s startWebservice];
    XCTAssertNil(error, @"Error on start webservice.");
    error = [s startWebservice];
    XCTAssertNotNil(error, @"No error on start webservice again.");

    XCTAssert([s hasStartWebservice], @"Start webservice in not considered as started.");
}

@end
