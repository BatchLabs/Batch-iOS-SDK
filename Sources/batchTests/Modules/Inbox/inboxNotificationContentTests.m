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

@implementation inboxNotificationContentTests

- (void)testNotificationContentValidPayload
{
    NSDate *now = [NSDate date];
    
    NSMutableDictionary *alert = [NSMutableDictionary new];
    [alert setValue:@"Je suis un body" forKey:@"body"];
    [alert setValue:@"Je suis un title" forKey:@"title"];
    
    NSMutableDictionary *aps = [NSMutableDictionary new];
    [aps setValue:alert forKey:@"alert"];
    [aps setValue:[NSNumber numberWithInteger:1] forKey:@"mutable-content"];
    [aps setValue:@"default" forKey:@"sound"];
    
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
    
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setValue:aps forKey:@"aps"];
    [payload setValue:batch forKey:@"com.batch"];
    
    BatchInboxNotificationContent *content = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                                                                  rawPayload:payload
                                                                                                    isUnread:TRUE
                                                                                                        date:now];
    
    XCTAssertEqual(@"test-id", [content identifier]);
    XCTAssertEqual(@"Je suis un title", [content title]);
    XCTAssertEqual(@"Je suis un body", [content body]);
    XCTAssertTrue([content isUnread]);
    XCTAssertFalse([content isDeleted]);
    XCTAssertEqual(BatchNotificationSourceTransactional, [content source]);
    XCTAssertEqual(@"https://batch.com", [[content attachmentURL] absoluteString]);
    
    [content _markAsRead];
    XCTAssertFalse([content isUnread]);
    
    [aps setValue:@"Je suis une alerte" forKey:@"alert"];
    BatchInboxNotificationContent *content2 = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                                                                     rawPayload:payload
                                                                                                       isUnread:TRUE
                                                                                                           date:now];
    XCTAssertEqual(@"test-id", [content2 identifier]);
    XCTAssertNil([content2 title]);
    XCTAssertEqual(@"Je suis une alerte", [content2 body]);
    XCTAssertTrue([content2 isUnread]);
    XCTAssertFalse([content isDeleted]);
    XCTAssertEqual(BatchNotificationSourceTransactional, [content2 source]);
    
}

- (void)testNotificationContentInvalidPayload
{
    NSDate *now = [NSDate date];
    BatchInboxNotificationContent *content = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                                                                  rawPayload:[NSMutableDictionary new]
                                                                                                    isUnread:TRUE
                                                                                                        date:now];
    XCTAssertNil(content);
    
    NSMutableDictionary *payload2 = [NSMutableDictionary new];
    [payload2 setValue:@"lol" forKey:@"aps"];
    BatchInboxNotificationContent *content2 = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@""
                                                                                                  rawPayload:payload2
                                                                                                    isUnread:TRUE
                                                                                                        date:now];
    XCTAssertNil(content2);
    
    NSMutableDictionary *payload3 = [NSMutableDictionary new];
    [payload3 setValue:[NSMutableDictionary new] forKey:@"aps"];
    BatchInboxNotificationContent *content3 = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                                                                  rawPayload:payload3
                                                                                                    isUnread:TRUE
                                                                                                        date:now];
    XCTAssertNil(content3);
    
    NSMutableDictionary *payload4 = [NSMutableDictionary new];
    [payload4 setValue:[NSMutableDictionary dictionaryWithObject:@"" forKey:@"alert"] forKey:@"aps"];
    BatchInboxNotificationContent *content4 = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                                                                  rawPayload:payload4
                                                                                                    isUnread:TRUE
                                                                                                        date:now];
    XCTAssertNil(content4);
    
    NSMutableDictionary *payload5 = [NSMutableDictionary new];
    [payload5 setValue:[NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInteger:154] forKey:@"alert"] forKey:@"aps"];
    BatchInboxNotificationContent *content5 = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                                                                  rawPayload:payload5
                                                                                                    isUnread:TRUE
                                                                                                        date:now];
    XCTAssertNil(content5);
    
    NSMutableDictionary *payload6 = [NSMutableDictionary new];
    [payload6 setValue:[NSMutableDictionary dictionaryWithObject:[NSMutableDictionary dictionaryWithObject:@"" forKey:@"body"] forKey:@"alert"] forKey:@"aps"];
    BatchInboxNotificationContent *content6 = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:@"test-id"
                                                                                                  rawPayload:payload6
                                                                                                    isUnread:TRUE
                                                                                                        date:now];
    XCTAssertNil(content6);
}

@end
