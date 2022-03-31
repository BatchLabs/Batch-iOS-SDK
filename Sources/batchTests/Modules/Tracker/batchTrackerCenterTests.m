//
//  batchTrackerCenterTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAConcurrentQueue.h"
#import "BATrackerCenter.h"

@interface BATrackerCenter ()

// Expose the private methods
- (BAConcurrentQueue *)queue;
- (void)start;
- (void)stop;

@end

@interface batchTrackerCenterTests : XCTestCase

@end

@implementation batchTrackerCenterTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [[[BATrackerCenter instance] queue] clear];
    [[BATrackerCenter instance] start];
    [super tearDown];
}

- (void)testBasics {
    XCTAssertNotNil([BATrackerCenter instance], @"Failed to create a Batch tracker center instance.");

    [[BATrackerCenter instance] stop];
    // Clear the queue to avoid events like "start" polluting the test
    BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
    [queue clear];

    [BATrackerCenter trackPrivateEvent:@"test" parameters:@{}];
    [BATrackerCenter trackPrivateEvent:@"testParameters" parameters:@{@"hello" : @"batch"}];

    XCTAssertTrue([queue count] == 2, @"Event queue doesn't contain 2 events but %lu.", (unsigned long)[queue count]);
}

@end
