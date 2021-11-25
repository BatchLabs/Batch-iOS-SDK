//
//  messageEventPayloadTests.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAMessageEventPayload.h"
#import "BatchMessagingPrivate.h"

@interface messageEventPayloadTests : XCTestCase

@property (nonatomic) id helperMock;

@end

@implementation messageEventPayloadTests

- (void)testPushMessageEventPayload
{
    NSDictionary<NSString*, NSObject*> *dictionary = @{
       @"title": @"testPush",
       @"id": @"9242259",
       @"l-campaignid": @"9242259",
       @"did": @"test-tracking-id",
       @"body": @"TEST",
       @"ed": @{
         @"t": @"l",
         @"v": @"0",
         @"lth": @"SIMPLE-TOP-BANNER",
         @"i": @"1569579362154"
       },
       @"kind": @"banner",
       @"attach_cta_bottom": @true,
       @"hero_split_ratio": @0.4,
       @"close": @true,
       @"cta_direction": @"h",
       @"auto_close": @10000,
       @"style": @"@import sdk(\"banner1\");\n*{--valign:top;--countdown-color:#191E5E;--countdown-valign:bottom;--ios-shadow:15 0.5 #000000;--android-shadow:10;--title-color:#DB243B;--body-color:#666666;--bg-color:#FFFFFF;--close-color:#666666;--cta-android-shadow:auto;--cta1-color:#DB243B;--cta1-text-color:#FFFFFF;--cta2-color:#ffffff;--cta2-text-color:#E3959F;--margin:15;--corner-radius:5;--mode:dark;}",
       @"cta": @[
         @{
           @"a": @"batch.deeplink",
           @"args": @{
             @"l": @"https://batch.com/test?utm_campaign=test&utm_content=main_button"
           },
           @"l": @"TEST"
         },
         @{
           @"a": @"batch.deeplink",
           @"args": @{
             @"l": @"https://batch.com/test?utm_campaign=test&utm_content=second_button"
           },
           @"l": @"TEST"
         },
         @{
           @"args": @{
             
           },
           @"l": @"CANCEL"
         }
       ]
    };
    
    BatchInAppMessage *message = [BatchInAppMessage messageForPayload:dictionary];
    XCTAssertNotNil(message);
    
    BAMessageEventPayload *payload1 = [[BAMessageEventPayload alloc] initWithMessage:message action:nil];
    XCTAssertNotNil(payload1);
    
    XCTAssertNil(payload1.deeplink);
    XCTAssertNil(payload1.notificationUserInfo);
    XCTAssertNotNil(payload1.sourceMessage);
    XCTAssertEqual(payload1.trackingId, @"test-tracking-id");
    XCTAssertFalse(payload1.isPositiveAction);
    
    BAMSGAction *action1 = [[BAMSGAction alloc] init];
    action1.actionIdentifier = @"batch.deeplink";
    action1.actionArguments = @{
        @"l": @"https://batch.com/test?utm_campaign=test&utm_content=main_button"
    };
    
    BAMessageEventPayload *payload2 = [[BAMessageEventPayload alloc] initWithMessage:message action:action1];
    XCTAssertNotNil(payload2);
    
    XCTAssertTrue(payload2.isPositiveAction);
    XCTAssertEqual(payload2.deeplink, @"https://batch.com/test?utm_campaign=test&utm_content=main_button");
    
    BAMSGAction *action2 = [[BAMSGAction alloc] init];
    action2.actionIdentifier = nil;
    action2.actionArguments = @{};
    
    BAMessageEventPayload *payload3 = [[BAMessageEventPayload alloc] initWithMessage:message action:action2];
    XCTAssertNotNil(payload3);
    
    XCTAssertFalse(payload3.isPositiveAction);
    XCTAssertNil(payload3.deeplink);
}

@end
