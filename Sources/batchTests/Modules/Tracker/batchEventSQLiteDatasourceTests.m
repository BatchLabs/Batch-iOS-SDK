//
//  batchEventSQLiteDatasourceTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAEventSQLiteDatasource.h"
#import "BAEventSQLiteHelper.h"
#import "BAJson.h"

@interface batchEventSQLiteDatasourceTests : XCTestCase {
    id<BAEventDatasourceProtocol> _datasource;
}
@end

@implementation batchEventSQLiteDatasourceTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _datasource = [[BAEventSQLiteDatasource alloc] initWithFilename:@"ba_tr_tests.db"
                                                        forDBHelper:[BAEventSQLiteHelper new]];
    XCTAssertNotNil(_datasource, "Could not instanciate datasource");
    [_datasource clear];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [_datasource clear];
    [_datasource close];
    [super tearDown];
}

- (void)testInsert {
    [_datasource clear];

    NSString *eventName = @"test";
    NSString *eventName2 = @"test2";
    NSString *eventKey = @"key";
    NSString *eventValue = @"value";

    // TODO add collapsable event tests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    [_datasource addEvent:[BAEvent eventWithName:eventName]];
    [_datasource addEvent:[BAEvent eventWithName:eventName]];
    [_datasource addEvent:[BAEvent eventWithName:eventName2 andParameters:@{eventKey : eventValue}]];
#pragma clang diagnostic pop

    NSArray *events = [_datasource eventsToSend:100];
    XCTAssertTrue([events count] == 3, @"Event table shound contain 3 events");

    BAEvent *event = [events lastObject];
    XCTAssertTrue([eventName2 isEqualToString:event.name], @"Event name badly persisted");
    XCTAssertTrue(event.state == BAEventStateNew, @"Bad event state");
    NSDictionary *parameters = [BAJson deserializeAsDictionary:event.parameters error:nil];
    XCTAssertNotNil(parameters, @"Event parameters not deserialized");
    XCTAssertTrue([eventValue isEqualToString:[parameters objectForKey:eventKey]],
                  @"Event parameters wrongly deserialized");

    event = [events firstObject];
    XCTAssertTrue([eventName isEqualToString:event.name], @"Event name badly persisted");

    // Test limiting
    events = [_datasource eventsToSend:2];
    XCTAssertTrue([events count] == 2, @"Event table shound contain 2 events when limited to 2");
}

- (void)testCollapsableInsert {
    [_datasource clear];

    NSString *eventName = @"test";
    NSString *eventName2 = @"test2";

    // TODO add collapsable event tests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    [_datasource addEvent:[BACollapsableEvent eventWithName:eventName]];
    [_datasource addEvent:[BACollapsableEvent eventWithName:eventName]];
    [_datasource addEvent:[BACollapsableEvent eventWithName:eventName]];
    [_datasource addEvent:[BACollapsableEvent eventWithName:eventName2]];
#pragma clang diagnostic pop

    NSArray *events = [_datasource eventsToSend:100];
    XCTAssertTrue([events count] == 2, @"Event table shound contain 2 collapsed events");

    BAEvent *event = [events lastObject];
    XCTAssertTrue([eventName2 isEqualToString:event.name], @"Event name badly persisted");
    XCTAssertTrue(event.state == BAEventStateNew, @"Bad event state");

    event = [events firstObject];
    XCTAssertTrue([eventName isEqualToString:event.name], @"Event name badly persisted");
}

- (void)testUpdate {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    [_datasource addEvent:[BAEvent eventWithName:@"test"]];
#pragma clang diagnostic pop
    [_datasource updateEventsStateFrom:BAEventStateNew to:BAEventStateSending];
    BAEvent *event = [[_datasource eventsToSend:1] firstObject];
    XCTAssertNil(event, @"There shouldn't be anything to send if all new events are sending");

    [_datasource updateEventsStateFrom:BAEventStateSending to:BAEventStateNew];
    event = [[_datasource eventsToSend:1] firstObject];
    XCTAssertTrue(event.state == BAEventStateNew, @"Mass state updating failed");

    [_datasource updateEventsStateTo:BAEventStateSent forEventsIdentifier:@[ event.identifier ]];
    event = [[_datasource eventsToSend:1] firstObject];
    XCTAssertNil(event, @"Sent events shouldn't be sendable");
}

- (void)testDelete {
    NSString *eventName = @"test3";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    [_datasource addEvent:[BAEvent eventWithName:eventName]];
#pragma clang diagnostic pop
    BAEvent *event = [[_datasource eventsToSend:1] firstObject];

    [_datasource deleteEvents:@[ event.identifier ]];

    event = [[_datasource eventsToSend:1] firstObject];
    // If event is nil, all is good
    if (event) {
        XCTAssertFalse([eventName isEqualToString:event.name], @"Event deletion failed");
    }
}

/// Events should be returned in the same order as they're inserted
- (void)testOrder {
    NSArray<NSString *> *eventNames = @[ @"_FIRST", @"E.SECOND", @"THIRD", @"_FOURTH" ];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    for (NSString *name in eventNames) {
        [_datasource addEvent:[BAEvent eventWithName:name]];
    }
#pragma clang diagnostic pop
    NSArray<BAEvent *> *eventsToSend = [_datasource eventsToSend:4];
    for (int i = 0; i < eventsToSend.count; i++) {
        XCTAssertEqualObjects(eventsToSend[i].name, eventNames[i]);
    }
}

@end
