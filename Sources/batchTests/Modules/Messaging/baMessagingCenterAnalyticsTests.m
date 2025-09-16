//
//  baMessagingCenterAnalyticsTests.m
//  Batch
//
//  Tests for BAMessagingCenter analytics tracking methods
//

#import <XCTest/XCTest.h>

#import "BAConcurrentQueue.h"
#import "BAEvent.h"
#import "BAMSGAction.h"
#import "BAMSGCTA.h"
#import "BAMSGMessage.h"
#import "BAMessagingCenter.h"
#import "BATrackerCenter.h"

@interface BAMessagingCenter (TestPrivate)
- (void)trackCTAClickEvent:(BAMSGMessage *_Nonnull)message ctaIndex:(NSInteger)ctaIndex action:(NSString *)action;

- (void)trackCTAClickEvent:(BAMSGMessage *_Nonnull)message
             ctaIdentifier:(NSString *)ctaIdentifier
                   ctaType:(NSString *)ctaType
                    action:(NSString *)action;
@end

@interface BATrackerCenter (TestPrivate)
- (BAConcurrentQueue *)queue;
- (void)stop;
- (void)start;
@end

@interface baMessagingCenterAnalyticsTests : XCTestCase
@property (nonatomic, strong) BAMessagingCenter *messagingCenter;
@property (nonatomic, strong) BAMSGMEPMessage *testMessage;
@end

@implementation baMessagingCenterAnalyticsTests

- (void)setUp {
    [super setUp];

    self.messagingCenter = [BAMessagingCenter instance];
    self.testMessage = [[BAMSGMEPMessage alloc] init];

    // Clear the tracker queue before each test
    [[BATrackerCenter instance] stop];
    BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
    [queue clear];
}

- (void)tearDown {
    // Clear the queue and restart the tracker
    BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
    [queue clear];
    [[BATrackerCenter instance] start];

    [super tearDown];
}

#pragma mark - MEP CTA Click Event Tests (with ctaIndex as NSInteger)

- (void)testTrackCTAClickEvent_MEP_WithAction {
    // Given
    NSInteger ctaIndex = 2;
    NSString *action = @"https://example.com";

    // When
    [self.messagingCenter trackCTAClickEvent:self.testMessage ctaIndex:ctaIndex action:action];

    // Then
    BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
    XCTAssertEqual([queue count], 1, @"Should have tracked one event");

    // Verify the event parameters
    BAEvent *event = (BAEvent *)[queue poll];
    XCTAssertNotNil(event, @"Event should not be nil");
    XCTAssertTrue([event isKindOfClass:[BAEvent class]], @"Should be BAEvent class");

    NSDictionary *parameters = event.parametersDictionary;
    XCTAssertNotNil(parameters, @"Parameters should not be nil");

    // Verify the ctaIndex parameter (should be an NSNumber wrapping the integer)
    XCTAssertEqualObjects(parameters[@"ctaIndex"], @(ctaIndex), @"ctaIndex should be %ld", (long)ctaIndex);

    // Verify the action parameter
    XCTAssertEqualObjects(parameters[@"action"], action, @"Action should be '%@'", action);

    // Verify event name
    XCTAssertEqualObjects(event.name, @"_MESSAGING", @"Event name should be '_MESSAGING'");
}

- (void)testTrackCTAClickEvent_MEP_WithNilAction {
    // Given
    NSInteger ctaIndex = 0;
    NSString *action = nil;

    // When
    [self.messagingCenter trackCTAClickEvent:self.testMessage ctaIndex:ctaIndex action:action];

    // Then
    BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
    XCTAssertEqual([queue count], 1, @"Should have tracked one event");

    // Verify the event parameters
    BAEvent *event = (BAEvent *)[queue poll];
    NSDictionary *parameters = event.parametersDictionary;

    // Verify the ctaIndex parameter
    XCTAssertEqualObjects(parameters[@"ctaIndex"], @(ctaIndex), @"ctaIndex should be %ld", (long)ctaIndex);

    // Verify the action parameter is NSNull when nil
    XCTAssertEqual(parameters[@"action"], [NSNull null], @"Action should be NSNull when nil");
}

- (void)testTrackCTAClickEvent_MEP_MultipleIndexValues {
    // Test various index values to ensure they're passed correctly
    NSArray<NSNumber *> *testIndexes = @[ @0, @1, @2, @10, @99 ];

    for (NSNumber *indexNumber in testIndexes) {
        NSInteger index = [indexNumber integerValue];

        // Clear the queue for each test
        BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
        [queue clear];

        // When
        [self.messagingCenter trackCTAClickEvent:self.testMessage ctaIndex:index action:@"test-action"];

        // Then
        XCTAssertEqual([queue count], 1, @"Should have tracked one event for index %ld", (long)index);

        BAEvent *event = (BAEvent *)[queue poll];
        NSDictionary *parameters = event.parametersDictionary;

        XCTAssertEqualObjects(parameters[@"ctaIndex"], @(index), @"ctaIndex should be %ld for test index %ld",
                              (long)index, (long)index);
    }
}

#pragma mark - CEP CTA Click Event Tests (with ctaId and ctaType)

- (void)testTrackCTAClickEvent_CEP_WithAllParameters {
    // Given
    NSString *ctaId = @"button-1";
    NSString *ctaType = @"button";
    NSString *action = @"https://example.com/cep";

    // When
    [self.messagingCenter trackCTAClickEvent:self.testMessage ctaIdentifier:ctaId ctaType:ctaType action:action];

    // Then
    BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
    XCTAssertEqual([queue count], 1, @"Should have tracked one event");

    // Verify the event parameters
    BAEvent *event = (BAEvent *)[queue poll];
    XCTAssertNotNil(event, @"Event should not be nil");
    XCTAssertTrue([event isKindOfClass:[BAEvent class]], @"Should be BAEvent class");

    NSDictionary *parameters = event.parametersDictionary;
    XCTAssertNotNil(parameters, @"Parameters should not be nil");

    // Verify the ctaId parameter (should be the identifier, not an index)
    XCTAssertEqualObjects(parameters[@"ctaId"], ctaId, @"ctaId should be '%@'", ctaId);

    // Verify the ctaType parameter
    XCTAssertEqualObjects(parameters[@"ctaType"], ctaType, @"ctaType should be '%@'", ctaType);

    // Verify the action parameter
    XCTAssertEqualObjects(parameters[@"action"], action, @"Action should be '%@'", action);

    // Verify event name
    XCTAssertEqualObjects(event.name, @"_MESSAGING", @"Event name should be '_MESSAGING'");
}

- (void)testTrackCTAClickEvent_CEP_WithNilAction {
    // Given
    NSString *ctaId = @"close-button";
    NSString *ctaType = @"close";
    NSString *action = nil;

    // When
    [self.messagingCenter trackCTAClickEvent:self.testMessage ctaIdentifier:ctaId ctaType:ctaType action:action];

    // Then
    BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
    XCTAssertEqual([queue count], 1, @"Should have tracked one event");

    // Verify the event parameters
    BAEvent *event = (BAEvent *)[queue poll];
    NSDictionary *parameters = event.parametersDictionary;

    // Verify the ctaId parameter
    XCTAssertEqualObjects(parameters[@"ctaId"], ctaId, @"ctaId should be '%@'", ctaId);

    // Verify the ctaType parameter
    XCTAssertEqualObjects(parameters[@"ctaType"], ctaType, @"ctaType should be '%@'", ctaType);

    // Verify the action parameter is NSNull when nil
    XCTAssertEqual(parameters[@"action"], [NSNull null], @"Action should be NSNull when nil");
}

- (void)testTrackCTAClickEvent_CEP_VariousCtaTypes {
    // Test various CTA types to ensure they're passed correctly
    NSArray *testTypes = @[ @"button", @"image" ];

    for (NSString *ctaType in testTypes) {
        // Clear the queue for each test
        BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
        [queue clear];

        // When
        [self.messagingCenter trackCTAClickEvent:self.testMessage
                                   ctaIdentifier:@"test-id"
                                         ctaType:ctaType
                                          action:@"test-action"];

        // Then
        XCTAssertEqual([queue count], 1, @"Should have tracked one event for ctaType %@", ctaType);

        BAEvent *event = (BAEvent *)[queue poll];
        NSDictionary *parameters = event.parametersDictionary;

        XCTAssertEqualObjects(parameters[@"ctaType"], ctaType, @"ctaType should be '%@' for test type %@", ctaType,
                              ctaType);
    }
}

#pragma mark - Parameter Key Verification Tests

- (void)testParameterKeys_MEP_vs_CEP {
    // This test verifies that MEP uses "ctaIndex" (as NSNumber) and CEP uses "ctaId" + "ctaType"

    // MEP tracking
    [self.messagingCenter trackCTAClickEvent:self.testMessage ctaIndex:1 action:@"mep-action"];

    BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
    BAEvent *mepEvent = (BAEvent *)[queue poll];
    NSDictionary *mepParameters = mepEvent.parametersDictionary;

    // MEP should have ctaIndex (as NSNumber), not ctaId or ctaType
    XCTAssertNotNil(mepParameters[@"ctaIndex"], @"MEP event should have ctaIndex");
    XCTAssertTrue([mepParameters[@"ctaIndex"] isKindOfClass:[NSNumber class]], @"MEP ctaIndex should be NSNumber");
    XCTAssertNil(mepParameters[@"ctaId"], @"MEP event should not have ctaId");
    XCTAssertNil(mepParameters[@"ctaType"], @"MEP event should not have ctaType");

    // CEP tracking
    [self.messagingCenter trackCTAClickEvent:self.testMessage
                               ctaIdentifier:@"button-id"
                                     ctaType:@"button"
                                      action:@"cep-action"];

    BAEvent *cepEvent = (BAEvent *)[queue poll];
    NSDictionary *cepParameters = cepEvent.parametersDictionary;

    // CEP should have ctaId and ctaType, not ctaIndex
    XCTAssertNotNil(cepParameters[@"ctaId"], @"CEP event should have ctaId");
    XCTAssertNotNil(cepParameters[@"ctaType"], @"CEP event should have ctaType");
    XCTAssertNil(cepParameters[@"ctaIndex"], @"CEP event should not have ctaIndex");
}

- (void)testTrackWebViewClickEvent_MEP_UsesActionNameKey {
    // Given
    BAMSGAction *action = [BAMSGAction new];
    action.actionIdentifier = @"my-action";
    NSString *analyticsID = @"anlytics-123";

    // When
    [self.messagingCenter messageWebViewClickTracked:self.testMessage action:action analyticsIdentifier:analyticsID];

    // Then
    BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
    XCTAssertEqual([queue count], 1, @"Should have tracked one event");

    BAEvent *event = (BAEvent *)[queue poll];
    XCTAssertNotNil(event, @"Event should not be nil");
    NSDictionary *parameters = event.parametersDictionary;

    XCTAssertEqualObjects(parameters[@"type"], @"webview_click", @"Type should be 'webview_click'");
    XCTAssertEqualObjects(parameters[@"analyticsID"], analyticsID, @"analyticsID should match");

    // MEP should use actionName
    XCTAssertEqualObjects(parameters[@"actionName"], @"my-action", @"MEP should use 'actionName' key");

    // And not use the CEP key
    XCTAssertNil(parameters[@"action"], @"MEP should not set 'action' key");
}

- (void)testTrackWebViewClickEvent_CEP_UsesActionKey {
    // Given
    BAMSGAction *action = [BAMSGAction new];
    action.actionIdentifier = @"cep-action";
    NSString *analyticsID = @"cep-analytics-456";
    BAMSGCEPMessage *cepMessage = [BAMSGCEPMessage new];

    // When
    [self.messagingCenter messageWebViewClickTracked:cepMessage action:action analyticsIdentifier:analyticsID];

    // Then
    BAConcurrentQueue *queue = [[BATrackerCenter instance] queue];
    XCTAssertEqual([queue count], 1, @"Should have tracked one event");

    BAEvent *event = (BAEvent *)[queue poll];
    XCTAssertNotNil(event, @"Event should not be nil");
    NSDictionary *parameters = event.parametersDictionary;

    XCTAssertEqualObjects(parameters[@"type"], @"webview_click", @"Type should be 'webview_click'");
    XCTAssertEqualObjects(parameters[@"analyticsID"], analyticsID, @"analyticsID should match");

    // CEP should use action
    XCTAssertEqualObjects(parameters[@"action"], @"cep-action", @"CEP should use 'action' key");

    // And not use the MEP key
    XCTAssertNil(parameters[@"actionName"], @"CEP should not set 'actionName' key");
}

@end
