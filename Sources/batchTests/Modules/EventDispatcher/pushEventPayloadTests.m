//
//  pushEventPayloadTests.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAPushEventPayload.h"

@interface pushEventPayloadTests : XCTestCase

@property (nonatomic) id helperMock;

@end

@implementation pushEventPayloadTests

- (void)testPushEventPayload
{
    NSDictionary<NSString*, NSObject*> *dictionary = @{
        @"hip": @"hop",
        @"com.batch": @{
            @"t": @"t",
            @"od": @{
                @"n": @"925a4e70-e13c-11e9-bbd4-cf7d44429d5e"
            },
            @"i": @"Testtransac4-1569598588",
            @"l": @"https://batch.com/test?utm_campaign=test_campaign&utm_content=test-content-1"
        }
    };
    
    BAPushEventPayload *payload = [[BAPushEventPayload alloc] initWithUserInfo:dictionary];
    
    XCTAssertNotNil(payload);
    
    XCTAssertEqual(@"https://batch.com/test?utm_campaign=test_campaign&utm_content=test-content-1", payload.deeplink);
    XCTAssertNil(payload.trackingId);
    XCTAssertNil([payload customValueForKey:@"com.batch"]);
    XCTAssertEqual(@"hop", [payload customValueForKey:@"hip"]);
    XCTAssertNil([payload customValueForKey:@"void"]);
    XCTAssertNil(payload.sourceMessage);
    XCTAssertNotNil(payload.notificationUserInfo);
    XCTAssertTrue(payload.isPositiveAction);
}
@end
