//
//  BatchConfigurationTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAConfiguration.h"

@interface BatchConfigurationTests : XCTestCase

@end

@implementation BatchConfigurationTests

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

- (void)testDevelopperKey
{
    // Test instantiation.
    BAConfiguration *c = [[BAConfiguration alloc] init];
    XCTAssertNotNil(c, @"Failed to instantiate a BAConfiguration.");
    
    // Test the default DevelopperKey value.
    XCTAssertNil([c developperKey], @"Default developper key value is not NULL.");
    
    NSError *e = nil;
    
    // Test set a NULL value.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    e = [c setDevelopperKey:nil];
#pragma clang diagnostic pop
    XCTAssertNotNil(e, @"Check NULL developper key failled.");

    // Test set an empty value.
    e = [c setDevelopperKey:@""];
    XCTAssertNotNil(e, @"Check empty developper key failled.");

    // Test with a regular developper key.
    e = [c setDevelopperKey:@"MYDEVKEY"];
    XCTAssertNil(e, @"Failed to set a regular developper key: %@",e);
    XCTAssertNotNil([c developperKey], @"Storing a regular developper key stored a NULL.");
    XCTAssertEqual([c developperKey], @"MYDEVKEY", @"Stored develloper key do not match the input.");
    
    BOOL mode;
    // Test dev mode.
    mode = [c developmentMode];
    XCTAssertFalse(mode, @"Dev key is not supposed to give a dev mode at YES.");

    // Test another key.
    e = [c setDevelopperKey:@"devKEY"];
    XCTAssertNil(e, @"Failed to set a regular developper key: %@",e);
    mode = [c developmentMode];
    XCTAssertFalse(mode, @"Dev key is not supposed to give a dev mode at YES.");
    
    // Test another key.
    e = [c setDevelopperKey:@"DEV"];
    XCTAssertNil(e, @"Failed to set a regular developper key: %@",e);
    mode = [c developmentMode];
    XCTAssertTrue(mode, @"Dev key is supposed to give a dev mode at YES.");
    
    // Test a valid key.
    e = [c setDevelopperKey:@"DEVKEY"];
    XCTAssertNil(e, @"Failed to set a regular developper key: %@",e);
    mode = [c developmentMode];
    XCTAssertTrue(mode, @"Dev key is supposed to give a dev mode at YES.");
}

@end
