//
//  inboxSyncWebserviceClientTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCMock.h"

#import <sqlite3.h>

#import "BAInbox.h"
#import "BAInboxSQLiteDatasource.h"
#import "BAInboxSQLiteHelper.h"
#import "BAInboxSyncWebserviceClient.h"
#import "BAInboxWebserviceClientType.h"
#import "BAInjection.h"
#import "BAJson.h"
#import "BATJsonDictionary.h"
#import "BAWebserviceURLBuilder.h"

#define PUSH_PAYLOAD                                                                                                   \
    @"{\"aps\":{\"alert\":\"Bienvenue sur la sample iOS ! Si nos calculs sont bons, tu l\'as install\u00E9e il y a 5 " \
    @"minutes, & tu re\u00E7ois donc cette trigger campaign d\u00E9dicac\u00E9e en guise de f\u00E9licitations. "      \
    @"\",\"mutable-content\":1,\"sound\":\"default\"},\"com.batch\":{\"t\":\"tc\",\"i\":"                              \
    @"\"9761e19205fd0aa66721dc7a94db4ae2-push_action-u1586420710260\",\"od\":{\"n\":\"a09c5300-7a3b-11ea-ac39-"        \
    @"29b797ebf207\",\"an\":\"push_action\",\"ct\":\"9761e19205fd0aa66721dc7a94db4ae2\"}}}"

@interface inboxSyncWebserviceClientTests : XCTestCase {
    BAOverlayedInjectable *_datasourceOverlay;
    BAInboxSQLiteDatasource *_datasource;
    sqlite3 *_database;
    id _helperMock;
}

@end

@implementation inboxSyncWebserviceClientTests

- (void)setUp {
    [super setUp];

    NSString *host = [[BAInjection injectProtocol:@protocol(BADomainManagerProtocol)] urlFor:BADomainServiceWeb
                                                                        overrideWithOriginal:FALSE];
    _helperMock = OCMClassMock([BAWebserviceURLBuilder class]);
    OCMStub([_helperMock webserviceURLForHost:host shortname:[OCMArg any]])
        .andReturn([NSURL URLWithString:@"https://batch.com/"]);

    // Put setup code here. This method is called before the invocation of each test method in the class.
    _datasource = [[BAInboxSQLiteDatasource alloc] initWithFilename:@"ba_in_tests.db"
                                                        forDBHelper:[BAInboxSQLiteHelper new]];
    XCTAssertNotNil(_datasource, "Could not instanciate datasource");

    Ivar databaseIVar = class_getInstanceVariable([_datasource class], "_database");
    _database = (__bridge sqlite3 *)object_getIvar(_datasource, databaseIVar);

    [_datasource clear];

    _datasourceOverlay = [BAInjection overlayProtocol:@protocol(BAInboxDatasourceProtocol)
                                     returnedInstance:_datasource];
}

- (void)tearDown {
    [BAInjection unregisterOverlay:_datasourceOverlay];

    [_datasource clear];
    [_datasource close];
    [super tearDown];

    [_helperMock stopMocking];
    _helperMock = nil;
}

- (void)testMissingNotificationInCache {
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier
                                                identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);

    long long timeOffset = 0;
    NSMutableArray<BAInboxNotificationContent *> *notifications = [NSMutableArray new];
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
        content.isUnread = NO;

        [notifications addObject:content];
    }

    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;

    XCTAssertTrue([_datasource insertResponse:response withFetcherId:fetcherId]);

    // We now have 4 notifications in cache: test-id-0, test-id-1, test-id-2, test-id-3
    // Notifications timestamps: 3600, 7200, 10800, 14400
    // We'll sync 2 notifications from cursor test-id-3
    NSString *cursor = @"test-id-3";
    int limit = 2;

    NSArray<BAInboxCandidateNotification *> *candidates = [_datasource candidateNotificationsFromCursor:cursor
                                                                                                  limit:limit
                                                                                              fetcherId:fetcherId];
    XCTAssertEqual(limit, [candidates count]);
    XCTAssertEqualObjects(@"test-id-2", [candidates objectAtIndex:0].identifier);
    XCTAssertEqualObjects(@"test-id-1", [candidates objectAtIndex:1].identifier);

    void (^successHandler)(BAInboxWebserviceResponse *_Nonnull) = ^(BAInboxWebserviceResponse *_Nonnull response) {
      XCTAssertTrue([response hasMore]);
      XCTAssertFalse([response didTimeout]);
      XCTAssertEqualObjects(@"test-id-2", [response cursor]);
      XCTAssertEqual(2, [[response notifications] count]);

      XCTAssertEqualObjects(@"test-id-2.5", [[response notifications] objectAtIndex:0].identifiers.identifier);
      XCTAssertEqualObjects(@"test-id-2", [[response notifications] objectAtIndex:1].identifiers.identifier);

      NSString *selectQuery = @"SELECT * FROM notifications WHERE notification_id = \"test-id-2.5\";";
      sqlite3_stmt *selectStatement;
      if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1,
                             &selectStatement, NULL) == SQLITE_OK) {
          int count = 0;
          while (sqlite3_step(selectStatement) == SQLITE_ROW) {
              count += 1;
              if (count > 1) {
                  XCTFail();
              }

              XCTAssertEqualObjects(@"test-id-2.5", [NSString stringWithUTF8String:(const char *)sqlite3_column_text(
                                                                                       selectStatement, 1)]);
              XCTAssertEqualObjects(
                  @"test-send-id-2.5",
                  [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatement, 2)]);
              XCTAssertEqual(1, sqlite3_column_int(selectStatement, 3));
              XCTAssertEqual(0, sqlite3_column_int(selectStatement, 4));
              XCTAssertEqual(10900, sqlite3_column_int64(selectStatement, 5));
          }

          if (count == 0) {
              XCTFail();
          }

          sqlite3_finalize(selectStatement);
      } else {
          XCTFail();
      }

      selectQuery = @"SELECT * FROM fetcher_notifications WHERE notification_id = \"test-id-2.5\";";
      if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1,
                             &selectStatement, NULL) == SQLITE_OK) {
          int count = 0;
          while (sqlite3_step(selectStatement) == SQLITE_ROW) {
              count += 1;
              if (count > 1) {
                  XCTFail();
              }

              // fetcher_id
              XCTAssertEqual(fetcherId, sqlite3_column_int(selectStatement, 1));
              // notification_id
              XCTAssertEqualObjects(@"test-id-2.5", [NSString stringWithUTF8String:(const char *)sqlite3_column_text(
                                                                                       selectStatement, 2)]);
              // install_id
              XCTAssertEqualObjects(
                  @"b5baf3e0-a01f-11ea-111a-17c13e111be2",
                  [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatement, 3)]);
              // custom_id
              XCTAssertEqual(NULL, sqlite3_column_text(selectStatement, 4));
          }

          if (count == 0) {
              XCTFail();
          }

          sqlite3_finalize(selectStatement);
      } else {
          XCTFail();
      }
    };

    BAWebserviceClient *client =
        [[BAInboxSyncWebserviceClient alloc] initWithIdentifier:@"test-custom-id"
                                                           type:BAInboxWebserviceClientTypeUserIdentifier
                                              authenticationKey:@"C RIGOLO"
                                                          limit:limit
                                                      fetcherId:fetcherId
                                                     candidates:candidates
                                                      fromToken:cursor
                                                        success:successHandler
                                                          error:^(NSError *_Nonnull error) {
                                                            XCTAssert(false);
                                                          }];

    NSString *payload = @"{\"notifications\":[{\"installId\":\"b5baf3e0-a01f-11ea-111a-17c13e111be2\","
                        @"\"notificationId\":\"test-id-2.5\",\"notificationTime\":10900000,\"sendId\":\"test-send-id-2."
                        @"5\",\"payload\":{\"com.batch\":{\"t\":\"t\",\"l\":\"https://"
                        @"google.com\",\"i\":\"6y4g8guj-u1585829353322_68f3\",\"od\":{\"n\":\"c44d6340-74da-11ea-b3b3-"
                        @"8dc99181b65a\"}},\"msg\":\"test body\",\"title\":\"test "
                        @"title\"}},{\"notificationId\":\"test-id-2\"}],\"cache\":{\"lastMarkAllAsRead\":1585233902218}"
                        @",\"hasMore\":true,\"timeout\":false,\"cursor\":\"test-id-2\"}";
    NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
    [client connectionDidFinishLoadingWithData:data];
}

- (void)testUpdatingNotificationInCache {
    long long fetcherId = [_datasource createFetcherIdWith:BAInboxWebserviceClientTypeUserIdentifier
                                                identifier:@"test-custom-id"];
    XCTAssertTrue(fetcherId > 0);

    long long timeOffset = 0;
    NSMutableArray<BAInboxNotificationContent *> *notifications = [NSMutableArray new];
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
        content.isUnread = YES;

        [notifications addObject:content];
    }

    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];
    response.notifications = notifications;

    XCTAssertTrue([_datasource insertResponse:response withFetcherId:fetcherId]);

    // We now have 4 notifications in cache: test-id-0, test-id-1, test-id-2, test-id-3
    // Notifications timestamps: 3600, 7200, 10800, 14400
    // We'll sync 2 notifications from cursor test-id-3
    NSString *cursor = @"test-id-3";
    int limit = 2;

    NSArray<BAInboxCandidateNotification *> *candidates = [_datasource candidateNotificationsFromCursor:cursor
                                                                                                  limit:limit
                                                                                              fetcherId:fetcherId];
    XCTAssertEqual(limit, [candidates count]);
    XCTAssertEqualObjects(@"test-id-2", [candidates objectAtIndex:0].identifier);
    XCTAssertEqualObjects(@"test-id-1", [candidates objectAtIndex:1].identifier);

    void (^successHandler)(BAInboxWebserviceResponse *_Nonnull) = ^(BAInboxWebserviceResponse *_Nonnull response) {
      XCTAssertTrue([response hasMore]);
      XCTAssertFalse([response didTimeout]);
      XCTAssertEqualObjects(@"test-id-1", [response cursor]);
      XCTAssertEqual(2, [[response notifications] count]);

      XCTAssertEqualObjects(@"test-id-2", [[response notifications] objectAtIndex:0].identifiers.identifier);
      XCTAssertEqual(NO, [[response notifications] objectAtIndex:0].isUnread);

      XCTAssertEqualObjects(@"test-id-1", [[response notifications] objectAtIndex:1].identifiers.identifier);
      XCTAssertEqualObjects(@"test-install-id-1-updated",
                            [[response notifications] objectAtIndex:1].identifiers.installID);
      XCTAssertEqualObjects(@"test-custom-id-1-updated",
                            [[response notifications] objectAtIndex:1].identifiers.customID);
      XCTAssertEqualObjects(@"test-send-id-1-updated", [[response notifications] objectAtIndex:1].identifiers.sendID);
      XCTAssertEqual(7300, [[[response notifications] objectAtIndex:1].date timeIntervalSince1970]);

      NSString *selectQuery = @"SELECT * FROM notifications WHERE notification_id = \"test-id-2\";";
      sqlite3_stmt *selectStatement;
      if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1,
                             &selectStatement, NULL) == SQLITE_OK) {
          int count = 0;
          while (sqlite3_step(selectStatement) == SQLITE_ROW) {
              count += 1;
              if (count > 1) {
                  XCTFail();
              }

              XCTAssertEqualObjects(
                  @"test-id-2", [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatement, 1)]);
              XCTAssertEqualObjects(@"test-send-id-2", [NSString stringWithUTF8String:(const char *)sqlite3_column_text(
                                                                                          selectStatement, 2)]);
              XCTAssertEqual(0, sqlite3_column_int(selectStatement, 3));
              XCTAssertEqual(0, sqlite3_column_int(selectStatement, 3));
              XCTAssertEqual(10800, sqlite3_column_int64(selectStatement, 5));
          }

          if (count == 0) {
              XCTFail();
          }

          sqlite3_finalize(selectStatement);
      } else {
          XCTFail();
      }

      selectQuery = @"SELECT * FROM notifications WHERE notification_id = \"test-id-1\";";
      if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1,
                             &selectStatement, NULL) == SQLITE_OK) {
          int count = 0;
          while (sqlite3_step(selectStatement) == SQLITE_ROW) {
              count += 1;
              if (count > 1) {
                  XCTFail();
              }

              XCTAssertEqualObjects(
                  @"test-id-1", [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatement, 1)]);
              XCTAssertEqualObjects(
                  @"test-send-id-1-updated",
                  [NSString stringWithUTF8String:(const char *)sqlite3_column_text(selectStatement, 2)]);
              XCTAssertEqual(1, sqlite3_column_int(selectStatement, 3));
              XCTAssertEqual(0, sqlite3_column_int(selectStatement, 4));
              XCTAssertEqual(7300, sqlite3_column_int64(selectStatement, 5));
          }

          if (count == 0) {
              XCTFail();
          }

          sqlite3_finalize(selectStatement);
      } else {
          XCTFail();
      }
    };

    BAWebserviceClient *client =
        [[BAInboxSyncWebserviceClient alloc] initWithIdentifier:@"test-custom-id"
                                                           type:BAInboxWebserviceClientTypeUserIdentifier
                                              authenticationKey:@"C RIGOLO"
                                                          limit:limit
                                                      fetcherId:fetcherId
                                                     candidates:candidates
                                                      fromToken:cursor
                                                        success:successHandler
                                                          error:^(NSError *_Nonnull error) {
                                                            XCTAssert(false);
                                                          }];

    NSString *payload =
        @"{\"notifications\":[{\"read\":true,\"notificationId\":\"test-id-2\"},{\"installId\":\"test-install-id-1-"
        @"updated\",\"customId\":\"test-custom-id-1-updated\",\"notificationId\":\"test-id-1\",\"notificationTime\":"
        @"7300000,\"sendId\":\"test-send-id-1-updated\"}],\"hasMore\":true,\"timeout\":false,\"cursor\":\"test-id-1\"}";
    NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
    [client connectionDidFinishLoadingWithData:data];
}

@end
