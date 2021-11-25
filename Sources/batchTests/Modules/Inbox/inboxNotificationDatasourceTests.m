//
//  inboxNotificationDatasourceTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <XCTest/XCTest.h>

#import "BAInbox.h"
#import "BAJson.h"
#import "BATJsonDictionary.h"
#import "BAInboxSQLiteDatasource.h"
#import "BAInboxSQLiteHelper.h"
#import "BAInboxWebserviceClientType.h"

#define JSON_PAYLOAD @"{\"notificationId\":\"a09c9800-7a3b-11ea-aaaa-29b797ebf207\",\"notificationTime\":1586420710448,\"sendId\":\"9761f65205fd0aa66721dc7a94db4ae2-push_action-u1586420710260\",\"payload\":{\"aps\":{\"alert\":\"Bienvenue sur la sample iOS ! Si nos calculs sont bons, tu l\'as install\u00E9e il y a 5 minutes, \\u0026 tu re\u00E7ois donc cette trigger campaign d\u00E9dicac\u00E9e en guise de f\u00E9licitations. \",\"mutable-content\":1,\"sound\":\"default\"},\"com.batch\":{\"t\":\"tc\",\"i\":\"9761e19205fd0aa66721dc7a94db4ae2-push_action-u1586420710260\",\"od\":{\"n\":\"a09c5300-7a3b-11ea-ac39-29b797ebf207\",\"an\":\"push_action\",\"ct\":\"9761e19205fd0aa66721dc7a94db4ae2\"}}}}"

#define PUSH_PAYLOAD @"{\"aps\":{\"alert\":\"Bienvenue sur la sample iOS ! Si nos calculs sont bons, tu l\'as install\u00E9e il y a 5 minutes, & tu re\u00E7ois donc cette trigger campaign d\u00E9dicac\u00E9e en guise de f\u00E9licitations. \",\"mutable-content\":1,\"sound\":\"default\"},\"com.batch\":{\"t\":\"tc\",\"i\":\"9761e19205fd0aa66721dc7a94db4ae2-push_action-u1586420710260\",\"od\":{\"n\":\"a09c5300-7a3b-11ea-ac39-29b797ebf207\",\"an\":\"push_action\",\"ct\":\"9761e19205fd0aa66721dc7a94db4ae2\"}}}"

@interface inboxNotificationDatasourceTests : XCTestCase
{
    BAOverlayedInjectable *_datasourceOverlay;
    BAInboxSQLiteDatasource *_datasource;
    sqlite3 *_database;
}
@end

@implementation inboxNotificationDatasourceTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _datasource = [[BAInboxSQLiteDatasource alloc] initWithFilename:@"ba_in_tests.db" forDBHelper:[BAInboxSQLiteHelper new]];
    XCTAssertNotNil(_datasource, "Could not instanciate datasource");
    
    Ivar databaseIVar = class_getInstanceVariable([_datasource class], "_database");
    _database = (__bridge sqlite3 *) object_getIvar(_datasource, databaseIVar);
    
    [_datasource clear];
    
    _datasourceOverlay = [BAInjection overlayProtocol:@protocol(BAInboxDatasourceProtocol) returnedInstance:_datasource];
}

- (void)tearDown
{
    [BAInjection unregisterOverlay:_datasourceOverlay];
    
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [_datasource clear];
    [_datasource close];
    [super tearDown];
}

- (void)testInsertFetcherIds
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertEqual(-1, [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeInstallation identifier:nil]);
    XCTAssertEqual(-1, [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeInstallation identifier:@""]);
#pragma clang diagnostic pop

    
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);
    
    NSString *selectQuery = @"SELECT * FROM fetchers;";
    sqlite3_stmt *selectStatement;
    
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            if (count > 1) {
                XCTFail();
            }
            
            // Type
            XCTAssertEqual(1, sqlite3_column_int(selectStatement, 1));
            // Identifier
            XCTAssertEqualObjects(@"test-custom-id", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 2)]);
        }
        
        if (count == 0) {
            XCTFail();
        }
        
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
    
    long long fetcherId2 = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeInstallation identifier:@"test-install-id"];
    XCTAssertEqual(fetcherId2, fetcherId + 1);
    
    selectQuery = [NSString stringWithFormat:@"SELECT * FROM fetchers WHERE _db_id = %lld;", fetcherId2];;
    
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            if (count > 1) {
                XCTFail();
            }
            
            // Type
            XCTAssertEqual(0, sqlite3_column_int(selectStatement, 1));
            // Identifier
            XCTAssertEqualObjects(@"test-install-id", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 2)]);
        }
        
        if (count == 0) {
            XCTFail();
        }
        
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
    
    long long fetcherId3 = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertEqual(fetcherId3, fetcherId);
}

-(void)testGetNotifications
{
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);

    BAInboxNotificationContent *content = [BAInboxNotificationContent new];
    content.identifiers = [BAInboxNotificationContentIdentifiers new];
    
    content.identifiers.identifier = @"test-id";
    content.identifiers.sendID = @"test-send-id";
    content.identifiers.installID = @"test-install-id";
    content.identifiers.customID = @"test-custom-id";
    
    content.date = [NSDate date];
    content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
    content.isUnread = YES;
    
    NSMutableArray<BAInboxNotificationContent*> *notifications = [NSMutableArray new];
    [notifications addObject:content];
    
    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;
    
    XCTAssertTrue([_datasource insertResponse:response withFetcherId:fetcherId]);
    
    NSMutableArray<NSString *> *ids = [NSMutableArray new];
    [ids addObject:@"test-id"];
    
    NSArray<BAInboxNotificationContent *>* result = [_datasource notifications:ids withFetcherId:fetcherId];
    XCTAssertNotNil(result);
    XCTAssertEqual(1, [result count]);
    XCTAssertEqualObjects(@"test-id", [result objectAtIndex:0].identifiers.identifier);
}

-(void)testSimpleInsert
{
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);
    
    BAInboxNotificationContent *content = [BAInboxNotificationContent new];
    content.identifiers = [BAInboxNotificationContentIdentifiers new];
    
    content.identifiers.identifier = @"test-id";
    content.identifiers.sendID = @"test-send-id";
    content.identifiers.installID = @"test-install-id";
    content.identifiers.customID = @"test-custom-id";
    
    NSDate *now = [NSDate date];
    content.date = now;
    content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
    content.isUnread = YES;
    
    NSMutableArray<BAInboxNotificationContent*> *notifications = [NSMutableArray new];
    [notifications addObject:content];
    
    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;
    
    XCTAssertTrue([_datasource insertResponse:response withFetcherId:fetcherId]);
    
    NSString *selectQuery = @"SELECT * FROM notifications;";
    sqlite3_stmt *selectStatement;
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            if (count > 1) {
                XCTFail();
            }
            
            XCTAssertEqualObjects(@"test-id", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 1)]);
            XCTAssertEqualObjects(@"test-send-id", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 2)]);
            XCTAssertEqual(1, sqlite3_column_int(selectStatement, 3));
            XCTAssertEqual(0, sqlite3_column_int(selectStatement, 4));
            XCTAssertEqual((long long) [now timeIntervalSince1970], sqlite3_column_int64(selectStatement, 5));
            XCTAssertEqualObjects(PUSH_PAYLOAD, [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 6)]);
        }
        
        if (count == 0) {
            XCTFail();
        }
        
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
    
    selectQuery = @"SELECT * FROM fetcher_notifications;";
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            if (count > 1) {
                XCTFail();
            }
        
            // fetcher_id
            XCTAssertEqual(fetcherId, sqlite3_column_int(selectStatement, 1));
            // notification_id
            XCTAssertEqualObjects(@"test-id", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 2)]);
            // install_id
            XCTAssertEqualObjects(@"test-install-id", [NSString stringWithUTF8String:(const char *) sqlite3_column_text(selectStatement, 3)]);
            // custom_id
            XCTAssertEqualObjects(@"test-custom-id", [NSString stringWithUTF8String:(const char *) sqlite3_column_text(selectStatement, 4)]);
        }
        
        if (count == 0) {
            XCTFail();
        }
        
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
}

-(void)testNotificationTime
{
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);

    BAInboxNotificationContent *content = [BAInboxNotificationContent new];
    content.identifiers = [BAInboxNotificationContentIdentifiers new];
    
    content.identifiers.identifier = @"test-id";
    content.identifiers.sendID = @"test-send-id";
    content.identifiers.installID = @"test-install-id";
    content.identifiers.customID = @"test-custom-id";
    
    NSDate *now = [NSDate date];
    content.date = now;
    content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
    content.isUnread = YES;
    
    NSMutableArray<BAInboxNotificationContent*> *notifications = [NSMutableArray new];
    [notifications addObject:content];
    
    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;
    
    XCTAssertTrue([_datasource insertResponse:response withFetcherId:fetcherId]);
    
    long long notificationTime = [_datasource notificationTime:@"test-id"];
    XCTAssertEqual((long long) [now timeIntervalSince1970], notificationTime);
}

-(void)testCleanDatabase
{
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);
    
    long long now = [[NSDate date] timeIntervalSince1970];
    long long times[4] = {now - 7776000, now, now - 7779990, now + 321456};
    NSMutableArray<BAInboxNotificationContent*> *notifications = [NSMutableArray new];
    for (int i = 0; i < 4; ++i) {
        
        BAInboxNotificationContent *content = [BAInboxNotificationContent new];
        content.identifiers = [BAInboxNotificationContentIdentifiers new];
        
        content.identifiers.identifier = [@"test-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.sendID = [@"test-send-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.installID = [@"test-install-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.customID = [@"test-custom-id-" stringByAppendingString:[@(i) stringValue]];
        
        content.date = [NSDate dateWithTimeIntervalSince1970:times[i]];
        content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
        content.isUnread = i % 2 == 0;
        
        [notifications addObject:content];
    }
    
    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;
    
    XCTAssertTrue([_datasource insertResponse:response withFetcherId:fetcherId]);
    
    XCTAssertTrue([_datasource cleanDatabase]);
    
    NSString *selectQuery = @"SELECT * FROM notifications;";
    sqlite3_stmt *selectStatement;
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            
            if (count == 1) {
                XCTAssertEqualObjects(@"test-id-1", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 1)]);
                XCTAssertEqual(times[1], sqlite3_column_int64(selectStatement, 5));
            } else if (count == 2) {
                XCTAssertEqualObjects(@"test-id-3", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 1)]);
                XCTAssertEqual(times[3], sqlite3_column_int64(selectStatement, 5));
            } else {
                XCTFail();
            }
        }
        
        if (count == 0) {
            XCTFail();
        }
        
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
}

-(void)testCandidateNotification
{
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);
    
    long long timeOffset = 0;
    NSMutableArray<BAInboxNotificationContent*> *notifications = [NSMutableArray new];
    for (int i = 0; i < 4; ++i) {
        
        BAInboxNotificationContent *content = [BAInboxNotificationContent new];
        content.identifiers = [BAInboxNotificationContentIdentifiers new];
        
        content.identifiers.identifier = [@"test-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.sendID = [@"test-send-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.installID = [@"test-install-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.customID = [@"test-custom-id-" stringByAppendingString:[@(i) stringValue]];
        
        timeOffset += 3600;
        content.date = [NSDate dateWithTimeIntervalSince1970:timeOffset];
        content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
        content.isUnread = i % 2 == 0;
        
        [notifications addObject:content];
    }
    
    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;
    
    XCTAssertTrue([_datasource insertResponse:response withFetcherId:fetcherId]);
    
    NSArray<BAInboxCandidateNotification*> *candidates = [_datasource candidateNotificationsFromCursor:@"test-id-3" limit:3 fetcherId:fetcherId];
    XCTAssertEqual(3, [candidates count]);
    XCTAssertEqualObjects(@"test-id-2", [candidates objectAtIndex:0].identifier);
    XCTAssertEqual(YES, [candidates objectAtIndex:0].isUnread);
    XCTAssertEqualObjects(@"test-id-1", [candidates objectAtIndex:1].identifier);
    XCTAssertEqual(NO, [candidates objectAtIndex:1].isUnread);
    XCTAssertEqualObjects(@"test-id-0", [candidates objectAtIndex:2].identifier);
    XCTAssertEqual(YES, [candidates objectAtIndex:2].isUnread);
    
    candidates = [_datasource candidateNotificationsFromCursor:nil limit:4 fetcherId:fetcherId];
    XCTAssertEqual(4, [candidates count]);
    XCTAssertEqualObjects(@"test-id-3", [candidates objectAtIndex:0].identifier);
    XCTAssertEqual(NO, [candidates objectAtIndex:0].isUnread);
    XCTAssertEqualObjects(@"test-id-2", [candidates objectAtIndex:1].identifier);
    XCTAssertEqual(YES, [candidates objectAtIndex:1].isUnread);
    XCTAssertEqualObjects(@"test-id-1", [candidates objectAtIndex:2].identifier);
    XCTAssertEqual(NO, [candidates objectAtIndex:2].isUnread);
    XCTAssertEqualObjects(@"test-id-0", [candidates objectAtIndex:3].identifier);
    XCTAssertEqual(YES, [candidates objectAtIndex:3].isUnread);
}

-(void)testCandidateNotificationMutipleFecther
{
    long long customFetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(customFetcherId > 0);
    
    long long installFetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-install-id"];
    XCTAssertTrue(installFetcherId > 0);
    
    long long now = [[NSDate date] timeIntervalSince1970];
    long long timeOffset = 0;
    NSMutableArray<BAInboxNotificationContent*> *notifications = [NSMutableArray new];
    for (int i = 0; i < 4; ++i) {
        
        BAInboxNotificationContent *content = [BAInboxNotificationContent new];
        content.identifiers = [BAInboxNotificationContentIdentifiers new];
        
        content.identifiers.identifier = [@"test-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.sendID = [@"test-send-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.installID = [@"test-install-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.customID = [@"test-custom-id-" stringByAppendingString:[@(i) stringValue]];
        
        timeOffset -= 2500000;
        content.date = [NSDate dateWithTimeIntervalSince1970:now + timeOffset];
        content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
        content.isUnread = i % 2 == 0;
        
        [notifications addObject:content];
    }
    
    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;
    
    XCTAssertTrue([_datasource insertResponse:response withFetcherId:customFetcherId]);
    XCTAssertTrue([_datasource insertResponse:response withFetcherId:installFetcherId]);
    
    NSArray<BAInboxCandidateNotification*> *candidates = [_datasource candidateNotificationsFromCursor:@"test-id-0" limit:10 fetcherId:customFetcherId];
    XCTAssertEqual(3, [candidates count]);
    XCTAssertEqualObjects(@"test-id-1", [candidates objectAtIndex:0].identifier);
    XCTAssertEqualObjects(@"test-id-2", [candidates objectAtIndex:1].identifier);
    XCTAssertEqualObjects(@"test-id-3", [candidates objectAtIndex:2].identifier);
    
    candidates = [_datasource candidateNotificationsFromCursor:@"test-id-1" limit:2 fetcherId:installFetcherId];
    XCTAssertEqual(2, [candidates count]);
    XCTAssertEqualObjects(@"test-id-2", [candidates objectAtIndex:0].identifier);
    XCTAssertEqualObjects(@"test-id-3", [candidates objectAtIndex:1].identifier);
    
    candidates = [_datasource candidateNotificationsFromCursor:@"test-id-3" limit:2 fetcherId:installFetcherId];
    XCTAssertEqual(0, [candidates count]);
    
    candidates = [_datasource candidateNotificationsFromCursor:nil limit:10 fetcherId:customFetcherId];
    XCTAssertEqual(4, [candidates count]);
    XCTAssertEqualObjects(@"test-id-0", [candidates objectAtIndex:0].identifier);
    XCTAssertEqualObjects(@"test-id-1", [candidates objectAtIndex:1].identifier);
    XCTAssertEqualObjects(@"test-id-2", [candidates objectAtIndex:2].identifier);
    XCTAssertEqualObjects(@"test-id-3", [candidates objectAtIndex:3].identifier);
}

-(void)testMarkAsDeleted {
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);
    BAInboxNotificationContent *content = [BAInboxNotificationContent new];
    content.identifiers = [BAInboxNotificationContentIdentifiers new];
    content.identifiers.identifier = @"test-id-1";
    content.identifiers.sendID = @"test-send-id-1";
    content.identifiers.installID = @"test-install-id-1";
    content.identifiers.customID = @"test-custom-id-1";
    content.date = [NSDate date];
    content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
    content.isUnread = YES;
    
    XCTAssertTrue([_datasource insertNotification:content withFetcherId:fetcherId]);
    
    XCTAssertTrue([_datasource markAsDeleted:@"test-id-1"]);
    
    NSString *selectQuery = @"SELECT * FROM notifications WHERE notification_id = 'test-id-1';";
    sqlite3_stmt *selectStatement;
    
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            if (count > 1) {
                XCTFail();
            }
            XCTAssertEqual(1, sqlite3_column_int(selectStatement, 4));
        }
        
        if (count != 1) {
            XCTFail();
        }
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
}

-(void)testMarkAsRead {
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);
    BAInboxNotificationContent *content = [BAInboxNotificationContent new];
    content.identifiers = [BAInboxNotificationContentIdentifiers new];
    content.identifiers.identifier = @"test-id-1";
    content.identifiers.sendID = @"test-send-id-1";
    content.identifiers.installID = @"test-install-id-1";
    content.identifiers.customID = @"test-custom-id-1";
    content.date = [NSDate date];
    content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
    content.isUnread = YES;
    
    XCTAssertTrue([_datasource insertNotification:content withFetcherId:fetcherId]);
    
    XCTAssertTrue([_datasource markAsRead:@"test-id-1"]);
    
    NSString *selectQuery = @"SELECT * FROM notifications WHERE notification_id = 'test-id-1';";
    sqlite3_stmt *selectStatement;
    
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            if (count > 1) {
                XCTFail();
            }
            XCTAssertEqual(0, sqlite3_column_int(selectStatement, 3));
        }
        
        if (count != 1) {
            XCTFail();
        }
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
}


-(void)testMarkAllAsRead
{
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);
    
    long long now = [[NSDate date] timeIntervalSince1970];
    long long timeOffset = 0;
    NSMutableArray<BAInboxNotificationContent*> *notifications = [NSMutableArray new];
    for (int i = 0; i < 4; ++i) {
        
        BAInboxNotificationContent *content = [BAInboxNotificationContent new];
        content.identifiers = [BAInboxNotificationContentIdentifiers new];
        
        content.identifiers.identifier = [@"test-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.sendID = [@"test-send-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.installID = [@"test-install-id-" stringByAppendingString:[@(i) stringValue]];
        content.identifiers.customID = [@"test-custom-id-" stringByAppendingString:[@(i) stringValue]];
        
        timeOffset -= 10000;
        content.date = [NSDate dateWithTimeIntervalSince1970:now + timeOffset];
        content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
        content.isUnread = YES;
        
        [notifications addObject:content];
    }
    
    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;
    
    XCTAssertTrue([_datasource insertResponse:response withFetcherId:fetcherId]);
    
    XCTAssertTrue([_datasource markAllAsRead:now - 25000 withFetcherId:fetcherId]);
    
    NSString *selectQuery = @"SELECT * FROM notifications WHERE unread = 0;";
    sqlite3_stmt *selectStatement;
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            if (count > 2) {
                XCTFail();
            }
            
            XCTAssertEqual(0, sqlite3_column_int(selectStatement, 3));
        }
        
        if (count == 0) {
            XCTFail();
        }
        
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
}

-(void)testDelete
{
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);

    BAInboxNotificationContent *content = [BAInboxNotificationContent new];
    content.identifiers = [BAInboxNotificationContentIdentifiers new];
    
    content.identifiers.identifier = @"test-id";
    content.identifiers.sendID = @"test-send-id";
    content.identifiers.installID = @"test-install-id";
    content.identifiers.customID = @"test-custom-id";
    
    NSDate *now = [NSDate date];
    content.date = now;
    content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
    content.isUnread = YES;
    
    NSMutableArray<BAInboxNotificationContent*> *notifications = [NSMutableArray new];
    [notifications addObject:content];
    
    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;
    
    XCTAssertTrue([_datasource insertResponse:response withFetcherId:fetcherId]);
    
    NSMutableArray *ids = [NSMutableArray new];
    [ids addObject:@"test-id"];
    
    XCTAssertTrue([_datasource deleteNotifications:ids]);
    
    NSString *selectQuery = @"SELECT * FROM notifications;";
    sqlite3_stmt *selectStatement;
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        XCTAssertEqual(SQLITE_DONE, sqlite3_step(selectStatement));
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
    
    selectQuery = @"SELECT * FROM fetcher_notifications;";
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        XCTAssertEqual(SQLITE_DONE, sqlite3_step(selectStatement));
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
}

-(void)testUpdate
{
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);

    BAInboxNotificationContent *content = [BAInboxNotificationContent new];
    content.identifiers = [BAInboxNotificationContentIdentifiers new];
    
    content.identifiers.identifier = @"test-id";
    content.identifiers.sendID = @"test-send-id";
    content.identifiers.installID = @"test-install-id";
    content.identifiers.customID = @"test-custom-id";
    
    NSDate *now = [NSDate date];
    content.date = now;
    content.payload = [BAJson deserializeAsDictionary:PUSH_PAYLOAD error:nil];
    content.isUnread = YES;
    
    NSMutableArray<BAInboxNotificationContent*> *notifications = [NSMutableArray new];
    [notifications addObject:content];
    
    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;
    
    XCTAssertTrue([_datasource insertResponse:response withFetcherId:fetcherId]);
    
    NSDictionary *updatePayload = [BAJson deserializeAsDictionary:@"{\"notificationId\":\"test-id\"}" error:nil];
    XCTAssertEqualObjects(@"test-id", [_datasource updateNotification:updatePayload withFetcherId:fetcherId]);
    
    updatePayload = [BAJson deserializeAsDictionary:@"{\"notificationId\":\"test-id\",\"read\":true}" error:nil];
    XCTAssertEqualObjects(@"test-id", [_datasource updateNotification:updatePayload withFetcherId:fetcherId]);
    
    NSString *selectQuery = @"SELECT * FROM notifications;";
    sqlite3_stmt *selectStatement;
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            if (count > 1) {
                XCTFail();
            }
            
            XCTAssertEqualObjects(@"test-id", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 1)]);
            XCTAssertEqualObjects(@"test-send-id", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 2)]);
            XCTAssertEqual(0, sqlite3_column_int(selectStatement, 3));
            XCTAssertEqual(0, sqlite3_column_int(selectStatement, 4));
            XCTAssertEqual((long long) [now timeIntervalSince1970], sqlite3_column_int64(selectStatement, 5));
            XCTAssertEqualObjects(PUSH_PAYLOAD, [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 6)]);
        }
        
        if (count == 0) {
            XCTFail();
        }
        
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
    
    updatePayload = [BAJson deserializeAsDictionary:@"{\"notificationId\":\"test-id\",\"notificationTime\":123456000,\"sendId\":\"updated-send-id\",\"installId\":\"updated-install-id\",\"customId\":\"updated-custom-id\"}"
                                              error:nil];
    XCTAssertEqualObjects(@"test-id", [_datasource updateNotification:updatePayload withFetcherId:fetcherId]);
    
    selectQuery = @"SELECT * FROM notifications;";
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            if (count > 1) {
                XCTFail();
            }
            
            XCTAssertEqualObjects(@"test-id", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 1)]);
            XCTAssertEqualObjects(@"updated-send-id", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 2)]);
            XCTAssertEqual(0, sqlite3_column_int(selectStatement, 3));
            XCTAssertEqual(0, sqlite3_column_int(selectStatement, 4));
            XCTAssertEqual(123456, sqlite3_column_int64(selectStatement, 5));
            XCTAssertEqualObjects(PUSH_PAYLOAD, [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 6)]);
        }
        
        if (count == 0) {
            XCTFail();
        }
        
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
    
    selectQuery = @"SELECT * FROM fetcher_notifications;";
    if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
    {
        int count = 0;
        while (sqlite3_step(selectStatement) == SQLITE_ROW) {
            count += 1;
            if (count > 1) {
                XCTFail();
            }
        
            // fetcher_id
            XCTAssertEqual(fetcherId, sqlite3_column_int(selectStatement, 1));
            // notification_id
            XCTAssertEqualObjects(@"test-id", [NSString stringWithUTF8String: (const char *) sqlite3_column_text(selectStatement, 2)]);
            // install_id
            XCTAssertEqualObjects(@"updated-install-id", [NSString stringWithUTF8String:(const char *) sqlite3_column_text(selectStatement, 3)]);
            // custom_id
            XCTAssertEqualObjects(@"updated-custom-id", [NSString stringWithUTF8String:(const char *) sqlite3_column_text(selectStatement, 4)]);
        }
        
        if (count == 0) {
            XCTFail();
        }
        
        sqlite3_finalize(selectStatement);
    } else {
        XCTFail();
    }
}

@end

