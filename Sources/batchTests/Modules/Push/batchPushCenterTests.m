//
//  batchPushCenterTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

@import Batch;
@import Batch.Batch_Private;

@interface batchPushCenterTests : XCTestCase

@end

@implementation batchPushCenterTests

- (void)testBasics
{
    XCTAssertNotNil([BAPushCenter instance], @"Failed to create a Batch push center instance.");
}

- (void)testIsBatchPush
{
    NSDictionary *comBatch = @{@"i": @(2)};
    NSDictionary *validPayload = @{@"foo": @"bar", @"com.batch": comBatch};
    XCTAssertTrue([BAPushCenter isBatchPush:validPayload]);
    validPayload = @{@"foo": @"bar", @"com.batch": comBatch};
    XCTAssertTrue([BAPushCenter isBatchPush:validPayload]);
    
    XCTAssertFalse([BAPushCenter isBatchPush:@{@"com.batch": @{}}]);
    XCTAssertFalse([BAPushCenter isBatchPush:@{@"com.batch": [NSNull null]}]);
    XCTAssertFalse([BAPushCenter isBatchPush:@{@"com.batch": @(2)}]);
    XCTAssertFalse([BAPushCenter isBatchPush:@{@"foo": @"bar"}]);
    XCTAssertFalse([BAPushCenter isBatchPush:@{}]);
    // Force a bad cast to silence the warnings, we still want to test those cases
    XCTAssertFalse([BAPushCenter isBatchPush:(NSDictionary*)@(2)]);
    XCTAssertFalse([BAPushCenter isBatchPush:(NSDictionary*)[NSNull null]]);
    XCTAssertFalse([BAPushCenter isBatchPush:nil]);
}

- (void)testIsBatchPush_public
{
    NSDictionary *comBatch = @{@"i": @(2)};
    NSDictionary *validPayload = @{@"foo": @"bar", @"com.batch": comBatch};
    XCTAssertTrue([BatchPush isBatchPush:validPayload]);
    validPayload = @{@"foo": @"bar", @"com.batch": comBatch};
    XCTAssertTrue([BatchPush isBatchPush:validPayload]);
    
    XCTAssertFalse([BatchPush isBatchPush:@{@"com.batch": @{}}]);
    XCTAssertFalse([BatchPush isBatchPush:@{@"com.batch": [NSNull null]}]);
    XCTAssertFalse([BatchPush isBatchPush:@{@"com.batch": @(2)}]);
    XCTAssertFalse([BatchPush isBatchPush:@{@"foo": @"bar"}]);
    XCTAssertFalse([BatchPush isBatchPush:@{}]);
    // Force a bad cast to silence the warnings, we still want to test those cases
    XCTAssertFalse([BatchPush isBatchPush:(NSDictionary*)@(2)]);
    XCTAssertFalse([BatchPush isBatchPush:(NSDictionary*)[NSNull null]]);
    XCTAssertFalse([BatchPush isBatchPush:nil]);
}

@end
