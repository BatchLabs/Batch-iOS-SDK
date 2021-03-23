//
//  BatchCoreCenterTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BACoreCenter.h"

@interface BatchCoreCenterTests : XCTestCase

@end

@implementation BatchCoreCenterTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testBasics
{
    XCTAssertNotNil([BACoreCenter instance], @"Failed to create a Batch center instance.");

    XCTAssertNotNil([BACoreCenter instance].status, @"Empty status in Batch center instance.");

    XCTAssertNotNil([BACoreCenter instance].configuration, @"Empty configuration in Batch center instance.");
}

@end
