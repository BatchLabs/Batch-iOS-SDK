//
//  BatchWebserviceResponseTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAWSResponse.h"
#import "BAErrorHelper.h"

@interface BatchWebserviceResponseTests : XCTestCase

@end

@implementation BatchWebserviceResponseTests

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
    BAWSResponse *response;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    response = [[BAWSResponse alloc] initWithResponse:nil];
#pragma clang diagnostic pop
    XCTAssertNil(response, @"Creating a response with an invalid input.");
    
    response = [[BAWSResponse alloc] initWithResponse:@{}];
    XCTAssertNil(response, @"Creating a response with an invalid input.");
    
    response = [[BAWSResponse alloc] initWithResponse:@{@"papa":@"maman"}];
    XCTAssertNil(response, @"Creating a response with an invalid input.");
    
    response = [[BAWSResponse alloc] initWithResponse:@{@"id":@"RESPONSE"}];
    XCTAssertNotNil(response, @"Cannot creat a response with a valid input.");
    XCTAssert([@"RESPONSE" isEqualToString:response.reference], @"Invalid response reference");
    
    response = [[BAWSResponse alloc] initWithResponse:@{@"id":@"RESPONSE", @"code":@"CODE", @"infos":@{@"type": @"INVALID_CODE"}}];
    XCTAssertNotNil(response, @"Cannot creat a response with a valid input.");
    XCTAssert([@"RESPONSE" isEqualToString:response.reference], @"Invalid response reference");
}

- (void)testErrors
{
    BAWSResponse *response;
    
    NSDictionary *SUCCESS_COMPLETE_JSON = @{@"id":@"abc",@"code":@"code",@"status":@"SUCCESS",@"infos":[NSNull null],@"offer":@{@"r":@"promotion1",@"id":@"promo1",@"data":@[@{@"n":@"key1",@"v":@"value1"}],@"tok":@"token2",@"bundles":@[@{@"r":@"bundle1",@"feat":@[@{@"r":@"feature1",@"val":@"value1"}],@"res":@[@{@"r":@"res1",@"val":@10}]}],@"feat":@[@{@"r":@"feature2",@"val":@"value2"}],@"res":@[@{@"r":@"res2",@"val":@10}]}};

    response = [[BAWSResponse alloc] initWithResponse:SUCCESS_COMPLETE_JSON];
    XCTAssertNotNil(response, @"Connot creat a response with a valid input.");
    
    NSDictionary *ERROR_JSON = @{@"id":@"abc",@"code":@"code",@"status":@"ERROR"};
    response = [[BAWSResponse alloc] initWithResponse:ERROR_JSON];
    XCTAssertNotNil(response, @"Connot creat a response with a valid input.");
}

@end
