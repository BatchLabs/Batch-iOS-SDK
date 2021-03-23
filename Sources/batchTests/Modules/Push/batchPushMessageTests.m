//
//  batchPushMessageTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAPushPayload.h"
#import "BAPropertiesCenter.h"

@interface batchPushMessageTests : XCTestCase

@end

@implementation batchPushMessageTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBasics
{
    BAPushPayload *message = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    message = [[BAPushPayload alloc] initWithUserInfo:nil];
#pragma clang diagnostic pop
    XCTAssertNil(message, @"A message has been created with nil info.");
    
    message = [[BAPushPayload alloc] initWithUserInfo:(NSDictionary *)@[@"a",@"b"]];
    XCTAssertNil(message, @"A message has been created with invalid info format.");
    
    message = [[BAPushPayload alloc] initWithUserInfo:@{@"a":@"b"}];
    XCTAssertNil(message, @"A message has been created with invalid info.");
    
    message = [[BAPushPayload alloc] initWithUserInfo:@{kWebserviceKeyPushBatchData:@{@"i":@"CAMPAIGN", kWebserviceKeyPushDeeplink:@"non-url deeplink"}}];
    XCTAssertNotNil(message, @"Unable to create a message with a valid identifier.");
    XCTAssertNotNil([message rawDeeplink], @"A deeplink should have been parsed");
    XCTAssertNotNil([message data], @"No data found for a valid message.");
    XCTAssertTrue([[[message data] allKeys] count] == 2, @"invalid number of data.");
    
    message = [[BAPushPayload alloc] initWithUserInfo:@{kWebserviceKeyPushBatchData:@{@"i":@"CAMPAIGN", kWebserviceKeyPushDeeplink:@"https://batch.com"}}];
    XCTAssertNotNil(message, @"Unable to create a message with a valid identifier.");
    XCTAssertNotNil([message rawDeeplink], @"No deeplink created for a valid message.");
    XCTAssertNotNil([message data], @"No data found for a valid message.");
    XCTAssertTrue([[[message data] allKeys] count] == 2, @"invalid number of data.");
    
    message = [[BAPushPayload alloc] initWithUserInfo:@{kWebserviceKeyPushBatchData:@{@"i":@"CAMPAIGN", kWebserviceKeyPushDeeplink:@"https://batch.com"}}];
    XCTAssertNotNil(message, @"Unable to create a message with a valid identifier.");
    XCTAssertNotNil([message rawDeeplink], @"No deeplink created for a valid message.");
    XCTAssertNotNil([message data], @"No data found for a valid message.");
    XCTAssertTrue([[[message data] allKeys] count] == 2, @"invalid number of data.");
}

@end
