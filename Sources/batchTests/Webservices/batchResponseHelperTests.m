//
//  BatchStartResponseTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAResponseHelper.h"

@interface BatchResponseHelperTests : XCTestCase

@end

@implementation BatchResponseHelperTests

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

- (void)testCheck
{
    NSError *e;
    
    // Test NULL response case.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    e = [BAResponseHelper checkResponse:nil];
#pragma clang diagnostic pop
    XCTAssertNotNil(e, @"The webservice reponse check must have returned an error.");
    
    // Test empty response case.
    e = [BAResponseHelper checkResponse:@{}];
    XCTAssertNotNil(e, @"The webservice reponse check must have returned an error.");
    
    // Test missing header response case.
    e = [BAResponseHelper checkResponse:@{@"body":@{}}];
    XCTAssertNotNil(e, @"The webservice reponse check must have returned an error.");
    
    // Test NULL header response case.
    e = [BAResponseHelper checkResponse:@{@"header":[NSNull alloc]}];
    XCTAssertNotNil(e, @"The webservice reponse check must have returned an error.");
    
    // Test empty header response case.
    e = [BAResponseHelper checkResponse:@{@"header":@{}}];
    XCTAssertNotNil(e, @"The webservice reponse check must have returned an error.");
    
    // Test NULL header status response case.
    e = [BAResponseHelper checkResponse:@{@"header":@{@"status":[NSNull alloc]}}];
    XCTAssertNotNil(e, @"The webservice reponse check must have returned an error.");
    
    // Test empty header status response case.
    e = [BAResponseHelper checkResponse:@{@"header":@{@"status":@""}}];
    XCTAssertNotNil(e, @"The webservice reponse check must have returned an error.");

    // Test valid header response witout body case.
    e = [BAResponseHelper checkResponse:@{@"header":@{@"status":@"OK"}}];
    XCTAssertNotNil(e, @"The webservice reponse check must have returned an error.");
    
    // Test valid response case.
    e = [BAResponseHelper checkResponse:@{@"header":@{@"status":@"OK"}, @"body":@{}}];
    XCTAssertNil(e, @"The webservice reponse check must not retur an error: %@",[e description]);
}

@end
