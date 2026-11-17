//
//  batchPushCenterTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCMock.h"

@import Batch;
@import Batch.Batch_Private;
@import UserNotifications;

@interface BAPushCenter (Tests)

- (void)internalHandleNotification:(NSDictionary *)userInfo actionIdentifier:(NSString *)identifier;

@end

@interface batchPushCenterTests : XCTestCase

@end

@implementation batchPushCenterTests

- (void)testBasics {
    XCTAssertNotNil([BAPushCenter instance], @"Failed to create a Batch push center instance.");
}

- (void)testIsBatchPush {
    NSDictionary *comBatch = @{@"i" : @(2)};
    NSDictionary *validPayload = @{@"foo" : @"bar", @"com.batch" : comBatch};
    XCTAssertTrue([BAPushCenter isBatchPush:validPayload]);
    validPayload = @{@"foo" : @"bar", @"com.batch" : comBatch};
    XCTAssertTrue([BAPushCenter isBatchPush:validPayload]);

    XCTAssertFalse([BAPushCenter isBatchPush:@{@"com.batch" : @{}}]);
    XCTAssertFalse([BAPushCenter isBatchPush:@{@"com.batch" : [NSNull null]}]);
    XCTAssertFalse([BAPushCenter isBatchPush:@{@"com.batch" : @(2)}]);
    XCTAssertFalse([BAPushCenter isBatchPush:@{@"foo" : @"bar"}]);
    XCTAssertFalse([BAPushCenter isBatchPush:@{}]);
    // Force a bad cast to silence the warnings, we still want to test those cases
    XCTAssertFalse([BAPushCenter isBatchPush:(NSDictionary *)@(2)]);
    XCTAssertFalse([BAPushCenter isBatchPush:(NSDictionary *)[NSNull null]]);
    XCTAssertFalse([BAPushCenter isBatchPush:nil]);
}

- (void)testIsBatchPush_public {
    NSDictionary *comBatch = @{@"i" : @(2)};
    NSDictionary *validPayload = @{@"foo" : @"bar", @"com.batch" : comBatch};
    XCTAssertTrue([BatchPush isBatchPush:validPayload]);
    validPayload = @{@"foo" : @"bar", @"com.batch" : comBatch};
    XCTAssertTrue([BatchPush isBatchPush:validPayload]);

    XCTAssertFalse([BatchPush isBatchPush:@{@"com.batch" : @{}}]);
    XCTAssertFalse([BatchPush isBatchPush:@{@"com.batch" : [NSNull null]}]);
    XCTAssertFalse([BatchPush isBatchPush:@{@"com.batch" : @(2)}]);
    XCTAssertFalse([BatchPush isBatchPush:@{@"foo" : @"bar"}]);
    XCTAssertFalse([BatchPush isBatchPush:@{}]);
    // Force a bad cast to silence the warnings, we still want to test those cases
    XCTAssertFalse([BatchPush isBatchPush:(NSDictionary *)@(2)]);
    XCTAssertFalse([BatchPush isBatchPush:(NSDictionary *)[NSNull null]]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertFalse([BatchPush isBatchPush:nil]);
#pragma clang diagnostic pop
}

- (void)testDuplicateNotificationResponseIsIgnored {
    id pushCenterMock = OCMPartialMock([BAPushCenter instance]);
    __block NSUInteger parseCount = 0;
    OCMStub([pushCenterMock parseNotification:[OCMArg any]
                          fetchCompletionHandler:nil
                originatesFromUNDelegateResponse:YES])
        .andDo(^(NSInvocation *invocation) {
          parseCount++;
        });

    NSDate *date = [NSDate date];
    id response = [self responseWithRequestIdentifier:[NSUUID UUID].UUIDString
                                                 date:date
                                     actionIdentifier:UNNotificationDefaultActionIdentifier];
    id duplicateResponse = [self responseWithRequestIdentifier:[response notification].request.identifier
                                                          date:date
                                              actionIdentifier:UNNotificationDefaultActionIdentifier];

    [BAPushCenter handleUserNotificationCenter:OCMClassMock([UNUserNotificationCenter class])
                didReceiveNotificationResponse:response];
    [BAPushCenter handleUserNotificationCenter:OCMClassMock([UNUserNotificationCenter class])
                didReceiveNotificationResponse:duplicateResponse];

    XCTAssertEqual(parseCount, 1);
    [pushCenterMock stopMocking];
}

- (void)testDuplicateNotificationActionIsIgnored {
    id pushCenterMock = OCMPartialMock([BAPushCenter instance]);
    __block NSUInteger actionCount = 0;
    OCMStub([pushCenterMock internalHandleNotification:[OCMArg any] actionIdentifier:@"THUMBS_UP"])
        .andDo(^(NSInvocation *invocation) {
          actionCount++;
        });

    id response = [self responseWithRequestIdentifier:[NSUUID UUID].UUIDString
                                                 date:[NSDate date]
                                     actionIdentifier:@"THUMBS_UP"];

    [BAPushCenter handleUserNotificationCenter:OCMClassMock([UNUserNotificationCenter class])
                didReceiveNotificationResponse:response];
    [BAPushCenter handleUserNotificationCenter:OCMClassMock([UNUserNotificationCenter class])
                didReceiveNotificationResponse:response];

    XCTAssertEqual(actionCount, 1);
    [pushCenterMock stopMocking];
}

- (void)testDistinctNotificationResponsesAreHandled {
    id pushCenterMock = OCMPartialMock([BAPushCenter instance]);
    __block NSUInteger parseCount = 0;
    OCMStub([pushCenterMock parseNotification:[OCMArg any]
                          fetchCompletionHandler:nil
                originatesFromUNDelegateResponse:YES])
        .andDo(^(NSInvocation *invocation) {
          parseCount++;
        });

    NSString *identifier = [NSUUID UUID].UUIDString;
    NSDate *date = [NSDate date];
    // Another notification
    id first = [self responseWithRequestIdentifier:identifier
                                              date:date
                                  actionIdentifier:UNNotificationDefaultActionIdentifier];
    id other = [self responseWithRequestIdentifier:[NSUUID UUID].UUIDString
                                              date:date
                                  actionIdentifier:UNNotificationDefaultActionIdentifier];
    // Same identifier, but a newer delivery: a notification replaced through apns-collapse-id
    id replaced = [self responseWithRequestIdentifier:identifier
                                                 date:[date dateByAddingTimeInterval:60]
                                     actionIdentifier:UNNotificationDefaultActionIdentifier];

    for (id response in @[ first, other, replaced ]) {
        [BAPushCenter handleUserNotificationCenter:OCMClassMock([UNUserNotificationCenter class])
                    didReceiveNotificationResponse:response];
    }

    XCTAssertEqual(parseCount, 3);
    [pushCenterMock stopMocking];
}

- (id)responseWithRequestIdentifier:(NSString *)identifier date:(NSDate *)date actionIdentifier:(NSString *)action {
    id request = OCMClassMock([UNNotificationRequest class]);
    OCMStub([request identifier]).andReturn(identifier);
    id content = OCMClassMock([UNNotificationContent class]);
    OCMStub([content userInfo]).andReturn(@{@"com.batch" : @{@"i" : identifier}});
    OCMStub([request content]).andReturn(content);

    id notification = OCMClassMock([UNNotification class]);
    OCMStub([notification request]).andReturn(request);
    OCMStub([notification date]).andReturn(date);

    id response = OCMClassMock([UNNotificationResponse class]);
    OCMStub([response notification]).andReturn(notification);
    OCMStub([response actionIdentifier]).andReturn(action);
    return response;
}

@end
