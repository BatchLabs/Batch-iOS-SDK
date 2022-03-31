//
//  inboxNotificationContentTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BatchInboxPrivate.h"

@interface inboxNotificationContentTests : XCTestCase

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation inboxNotificationContentTests

- (void)testNotificationContentValidPayload {
    NSDate *now = [NSDate date];

    NSMutableDictionary *alert = [NSMutableDictionary new];
    [alert setValue:@"Je suis un body" forKey:@"body"];
    [alert setValue:@"Je suis un title" forKey:@"title"];

    NSMutableDictionary *aps = [NSMutableDictionary new];
    [aps setValue:alert forKey:@"alert"];
    [aps setValue:[NSNumber numberWithInteger:1] forKey:@"mutable-content"];
    [aps setValue:@"default" forKey:@"sound"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setValue:aps forKey:@"aps"];
    [payload setValue:[self makeBatchPrivatePayload] forKey:@"com.batch"];

    BatchInboxNotificationContent *content =
        [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                               rawPayload:payload
                                                                 isUnread:TRUE
                                                                     date:now
                                                 failOnSilentNotification:true];

    XCTAssertEqual(@"test-id", [content identifier]);
    XCTAssertEqual(@"Je suis un title", [content title]);
    XCTAssertEqual(@"Je suis un body", [content body]);
    XCTAssertEqual(@"Je suis un title", [[content message] title]);
    XCTAssertEqual(@"Je suis un body", [[content message] body]);
    XCTAssertNil([[content message] subtitle]);
    XCTAssertTrue([content isUnread]);
    XCTAssertFalse([content isDeleted]);
    XCTAssertFalse([content isSilent]);
    XCTAssertEqual(BatchNotificationSourceTransactional, [content source]);
    XCTAssertEqual(@"https://batch.com", [[content attachmentURL] absoluteString]);

    [content _markAsRead];
    XCTAssertFalse([content isUnread]);

    // Add a subtitle
    [alert setValue:@"Je suis un subtitle" forKey:@"subtitle"];

    content = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                                     rawPayload:payload
                                                                       isUnread:TRUE
                                                                           date:now
                                                       failOnSilentNotification:true];
    XCTAssertEqual(@"Je suis un title", [content title]);
    XCTAssertEqual(@"Je suis un body", [content body]);
    XCTAssertEqual(@"Je suis un title", [[content message] title]);
    XCTAssertEqual(@"Je suis un body", [[content message] body]);
    XCTAssertEqual(@"Je suis un subtitle", [[content message] subtitle]);
    XCTAssertFalse([content isSilent]);
    // Simple aps format

    [aps setValue:@"Je suis une alerte" forKey:@"alert"];
    content = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                                     rawPayload:payload
                                                                       isUnread:TRUE
                                                                           date:now
                                                       failOnSilentNotification:true];
    XCTAssertEqual(@"test-id", [content identifier]);
    XCTAssertNil([content title]);
    XCTAssertNil([[content message] title]);
    XCTAssertNil([[content message] subtitle]);
    XCTAssertEqual(@"Je suis une alerte", [content body]);
    XCTAssertEqual(@"Je suis une alerte", [[content message] body]);
    XCTAssertTrue([content isUnread]);
    XCTAssertFalse([content isDeleted]);
    XCTAssertFalse([content isSilent]);
    XCTAssertEqual(BatchNotificationSourceTransactional, [content source]);
}

- (void)testNotificationContentInvalidPayload {
    NSDate *now = [NSDate date];
    BatchInboxNotificationContent *content =
        [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                               rawPayload:[NSMutableDictionary new]
                                                                 isUnread:TRUE
                                                                     date:now
                                                 failOnSilentNotification:true];
    XCTAssertNil(content);

    NSMutableDictionary *payload2 = [NSMutableDictionary new];
    [payload2 setValue:@"lol" forKey:@"aps"];
    BatchInboxNotificationContent *content2 = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@""
                                                                                                     rawPayload:payload2
                                                                                                       isUnread:TRUE
                                                                                                           date:now
                                                                                       failOnSilentNotification:true];
    XCTAssertNil(content2);

    NSMutableDictionary *payload3 = [NSMutableDictionary new];
    [payload3 setValue:[NSMutableDictionary new] forKey:@"aps"];
    BatchInboxNotificationContent *content3 =
        [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                               rawPayload:payload3
                                                                 isUnread:TRUE
                                                                     date:now
                                                 failOnSilentNotification:true];
    XCTAssertNil(content3);

    NSMutableDictionary *payload4 = [NSMutableDictionary new];
    [payload4 setValue:[NSMutableDictionary dictionaryWithObject:@"" forKey:@"alert"] forKey:@"aps"];
    BatchInboxNotificationContent *content4 =
        [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                               rawPayload:payload4
                                                                 isUnread:TRUE
                                                                     date:now
                                                 failOnSilentNotification:true];
    XCTAssertNil(content4);

    NSMutableDictionary *payload5 = [NSMutableDictionary new];
    [payload5 setValue:[NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInteger:154] forKey:@"alert"]
                forKey:@"aps"];
    BatchInboxNotificationContent *content5 =
        [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                               rawPayload:payload5
                                                                 isUnread:TRUE
                                                                     date:now
                                                 failOnSilentNotification:true];
    XCTAssertNil(content5);

    NSMutableDictionary *payload6 = [NSMutableDictionary new];
    [payload6 setValue:[NSMutableDictionary dictionaryWithObject:[NSMutableDictionary dictionaryWithObject:@""
                                                                                                    forKey:@"body"]
                                                          forKey:@"alert"]
                forKey:@"aps"];
    BatchInboxNotificationContent *content6 =
        [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                               rawPayload:payload6
                                                                 isUnread:TRUE
                                                                     date:now
                                                 failOnSilentNotification:true];
    XCTAssertNil(content6);
}

- (void)testSilentNotifications {
    NSDate *now = [NSDate date];
    NSDictionary *silentNotificationPayload =
        @{@"aps" : @{@"content-available" : @(1)}, @"com.batch" : [self makeBatchPrivatePayload]};

    // Test that the class refuses to parse a silent notification
    XCTAssertNil([[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                                        rawPayload:silentNotificationPayload
                                                                          isUnread:TRUE
                                                                              date:now
                                                          failOnSilentNotification:true]);

    // Test that when enabled, silent notifications can be parsed
    BatchInboxNotificationContent *content =
        [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                               rawPayload:silentNotificationPayload
                                                                 isUnread:TRUE
                                                                     date:now
                                                 failOnSilentNotification:false];
    XCTAssertNil(content.title);
    XCTAssertNil(content.message);
    XCTAssertEqual(@"", content.body); // Test compatibility behaviour
    XCTAssertEqual(silentNotificationPayload, content.payload);
    XCTAssertTrue(content.isSilent);
}

- (NSMutableDictionary *)makeBatchPrivatePayload {
    NSMutableDictionary *at = [NSMutableDictionary new];
    [at setValue:@"https://batch.com" forKey:@"u"];

    NSMutableDictionary *od = [NSMutableDictionary new];
    [od setValue:@"5a3c93c0-7a3b-0000-0000-69f412b0000000" forKey:@"n"];

    NSMutableDictionary *batch = [NSMutableDictionary new];
    [batch setValue:@"6y4g8guj-u1586420592376_000000" forKey:@"i"];
    [batch setValue:@"https://batch.com" forKey:@"l"];
    [batch setValue:od forKey:@"od"];
    [batch setValue:@"t" forKey:@"t"];
    [batch setValue:at forKey:@"at"];
    return batch;
}

@end

#pragma clang diagnostic pop
