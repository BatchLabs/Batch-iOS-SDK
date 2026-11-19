//
//  batchTrackerSenderTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCMock.h"

@import Batch;
@import Batch.Batch_Private;

/// In-memory datasource that can simulate a database that can be read but not written to, which is what happens
/// on a full disk or a read-only/corrupted SQLite file.
@interface BATrackerSenderTestDatasource : NSObject <BAEventDatasourceProtocol>

@property (nonatomic) NSMutableArray<BAEvent *> *events;
@property (nonatomic) BOOL canDelete;
// When NO (the default), state updates are lost like every other write. When YES, events moved to the Sending state
// stop being returned by eventsToSend:, like the SQLite datasource does.
@property (nonatomic) BOOL canUpdateState;
@property (nonatomic) NSMutableSet<NSString *> *sendingEventIdentifiers;
@property (nonatomic) NSUInteger deleteCallCount;

@end

@implementation BATrackerSenderTestDatasource

- (instancetype)init {
    self = [super init];
    if (self) {
        _events = [NSMutableArray new];
        _canDelete = YES;
        _canUpdateState = NO;
        _sendingEventIdentifiers = [NSMutableSet new];
    }
    return self;
}

- (void)close {
}

- (void)clear {
    [_events removeAllObjects];
}

- (BOOL)addEvent:(BAEvent *)event {
    [_events addObject:event];
    return YES;
}

- (NSArray *)eventsToSend:(NSUInteger)count {
    NSMutableArray<BAEvent *> *sendableEvents = [NSMutableArray new];
    for (BAEvent *event in _events) {
        if (![_sendingEventIdentifiers containsObject:event.identifier]) {
            [sendableEvents addObject:event];
        }
    }
    if (count == 0 || count >= [sendableEvents count]) {
        return sendableEvents;
    }
    return [sendableEvents subarrayWithRange:NSMakeRange(0, count)];
}

- (void)updateEventsStateFrom:(BAEventState)fromState to:(BAEventState)toState {
}

- (void)updateEventsStateTo:(BAEventState)state forEventsIdentifier:(NSArray *)events {
    if (!_canUpdateState) {
        // A datasource that cannot be written to does not update states either
        return;
    }
    if (state == BAEventStateSending) {
        [_sendingEventIdentifiers addObjectsFromArray:events];
    } else {
        for (NSString *identifier in events) {
            [_sendingEventIdentifiers removeObject:identifier];
        }
    }
}

- (BOOL)deleteEvents:(NSArray *)eventIdentifiers {
    _deleteCallCount++;
    if (!_canDelete) {
        return NO;
    }
    NSSet *identifiers = [NSSet setWithArray:eventIdentifiers];
    NSIndexSet *indexes = [_events indexesOfObjectsPassingTest:^BOOL(BAEvent *event, NSUInteger idx, BOOL *stop) {
      return [identifiers containsObject:event.identifier];
    }];
    [_events removeObjectsAtIndexes:indexes];
    return YES;
}

- (BOOL)hasEventsToSend {
    return [[self eventsToSend:1] count] > 0;
}

- (void)deleteEventsOlderThanTheLast:(NSUInteger)eventNumber {
}

@end

@interface batchTrackerSenderTests : XCTestCase {
    BATrackerSenderTestDatasource *_datasource;
    BATrackerSender *_sender;
    id _executorMock;
    NSMutableArray *_enqueuedClients;
}
@end

@implementation batchTrackerSenderTests

- (void)setUp {
    [super setUp];
    // The webservice URL can't be built without an API key
    NSError *configurationError = [[BACoreCenter instance].configuration setDevelopperKey:@"DEV_KEY"];
    XCTAssertNil(configurationError);

    _datasource = [BATrackerSenderTestDatasource new];
    _sender = [[BATrackerSender alloc] initWithDatasource:_datasource];

    // Capture the webservice clients instead of hitting the network
    _enqueuedClients = [NSMutableArray new];
    _executorMock = OCMClassMock([BAWebserviceClientExecutor class]);
    OCMStub([_executorMock sharedInstance]).andReturn(_executorMock);
    OCMStub([_executorMock addClient:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
      __unsafe_unretained id client;
      [invocation getArgument:&client atIndex:2];
      [self->_enqueuedClients addObject:client];
    });
}

- (void)tearDown {
    [_executorMock stopMocking];
    [super tearDown];
}

- (void)testSuccessfulDeletionAllowsNextBatch {
    [_datasource addEvent:[BAEvent eventWithName:@"_FIRST"]];
    [_datasource addEvent:[BAEvent eventWithName:@"_SECOND"]];

    XCTAssertTrue([_sender send]);
    XCTAssertEqual([_enqueuedClients count], 1);

    NSArray *sentEvents = [_datasource eventsToSend:0];
    [_sender trackingWebserviceDidFinish:YES forEvents:sentEvents];

    XCTAssertFalse([_datasource hasEventsToSend], @"Acknowledged events should have been deleted");
    XCTAssertFalse([_sender send], @"Nothing should be left to send");
    XCTAssertEqual([_enqueuedClients count], 1);
}

- (void)testAcknowledgedEventsAreNotSentAgainWhenDeletionFails {
    _datasource.canDelete = NO;
    [_datasource addEvent:[BAEvent eventWithName:@"_START"]];

    XCTAssertTrue([_sender send]);
    XCTAssertEqual([_enqueuedClients count], 1);

    NSArray *sentEvents = [_datasource eventsToSend:0];
    [_sender trackingWebserviceDidFinish:YES forEvents:sentEvents];

    // The event is still in the datasource, but the server already has it: the scheduler's immediate retry must not
    // send it again, otherwise the SDK loops at network speed.
    XCTAssertTrue([_datasource hasEventsToSend]);
    XCTAssertFalse([_sender send], @"An acknowledged event must not be sent again");
    XCTAssertFalse([_sender send], @"An acknowledged event must not be sent again, even on subsequent attempts");
    XCTAssertEqual([_enqueuedClients count], 1, @"No new webservice should have been started");
}

- (void)testNewEventsAreStillSentWhileAcknowledgedOnesAreStuck {
    _datasource.canDelete = NO;
    [_datasource addEvent:[BAEvent eventWithName:@"_STUCK"]];

    XCTAssertTrue([_sender send]);
    [_sender trackingWebserviceDidFinish:YES forEvents:[_datasource eventsToSend:0]];
    XCTAssertFalse([_sender send]);

    BAEvent *newEvent = [BAEvent eventWithName:@"_NEW"];
    [_datasource addEvent:newEvent];

    XCTAssertTrue([_sender send], @"A new event should still be sent");
    XCTAssertEqual([_enqueuedClients count], 2);
}

- (void)testAcknowledgedEventsAreDeletedOnceDatasourceIsWritableAgain {
    _datasource.canDelete = NO;
    [_datasource addEvent:[BAEvent eventWithName:@"_START"]];

    XCTAssertTrue([_sender send]);
    [_sender trackingWebserviceDidFinish:YES forEvents:[_datasource eventsToSend:0]];
    XCTAssertFalse([_sender send]);

    // Disk space is back: the next send attempt should clean up the acknowledged event
    _datasource.canDelete = YES;
    XCTAssertFalse([_sender send], @"The acknowledged event should be deleted, not sent");
    XCTAssertFalse([_datasource hasEventsToSend], @"The acknowledged event should have been deleted");
    XCTAssertEqual([_enqueuedClients count], 1);
}

- (void)testAcknowledgedEventsAreDeletedEvenWhenNothingIsSendable {
    // The state update went through but the deletion failed: the event is stuck in the Sending state, so it is not
    // sendable anymore and would never be cleaned up if the retry only ran when there is something to send.
    _datasource.canUpdateState = YES;
    _datasource.canDelete = NO;
    [_datasource addEvent:[BAEvent eventWithName:@"_START"]];
    // Grab the events before sending: once in the Sending state, the datasource won't return them anymore
    NSArray *sentEvents = [_datasource eventsToSend:0];

    XCTAssertTrue([_sender send]);
    [_sender trackingWebserviceDidFinish:YES forEvents:sentEvents];
    XCTAssertFalse([_datasource hasEventsToSend], @"The event should be stuck in the Sending state");
    XCTAssertEqual([_datasource.events count], 1);

    _datasource.canDelete = YES;
    XCTAssertFalse([_sender send]);
    XCTAssertEqual([_datasource.events count], 0, @"The acknowledged event should have been deleted");
    XCTAssertEqual([_enqueuedClients count], 1);
}

- (void)testFailureDoesNotAcknowledgeEvents {
    _datasource.canDelete = NO;
    [_datasource addEvent:[BAEvent eventWithName:@"_START"]];

    XCTAssertTrue([_sender send]);
    [_sender trackingWebserviceDidFinish:NO forEvents:[_datasource eventsToSend:0]];

    // The server did not get the event: it must be retried (the scheduler takes care of the delay)
    XCTAssertTrue([_sender send]);
    XCTAssertEqual([_enqueuedClients count], 2);
}

@end
