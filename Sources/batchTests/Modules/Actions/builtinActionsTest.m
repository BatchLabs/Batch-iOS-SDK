#import <Batch/Batch.h>
#import <XCTest/XCTest.h>
#import "BAActionsCenter.h"
#import "BatchTests-Swift.h"
#import "DeeplinkDelegateStub.h"
#import "OCMock.h"

@interface builtinActionsTest : XCTestCase
@end

@implementation builtinActionsTest

- (void)tearDown {
    [BatchSDK setDeeplinkDelegate:nil];
}

- (void)testTagEditAction {
    id batchProfileMock = OCMClassMock([BatchProfile class]);
    id batchProfileDataEditorMock = OCMClassMock([BatchProfileEditor class]);
    [batchProfileDataEditorMock setExpectationOrderMatters:YES];

    OCMExpect([batchProfileMock editor]).andReturn(batchProfileDataEditorMock);
    OCMExpect([batchProfileDataEditorMock addItemToStringArrayAttribute:@"foo"
                                                                 forKey:@"bar"
                                                                  error:[OCMArg anyObjectRef]]);
    OCMExpect([batchProfileDataEditorMock save]);

    OCMExpect([batchProfileMock editor]).andReturn(batchProfileDataEditorMock);
    OCMExpect([(BatchProfileEditor *)batchProfileDataEditorMock
        removeItemFromStringArrayAttribute:@"foo"
                                    forKey:@"bar"
                                     error:[OCMArg anyObjectRef]]);
    OCMExpect([batchProfileDataEditorMock save]);

    OCMReject([batchProfileMock editor]);

    [[BAActionsCenter instance] performAction:@"batch.user.tag"
                                     withArgs:@{@"c" : @"bar", @"t" : @"foo", @"a" : @"add"}
                                    andSource:nil];
    [[BAActionsCenter instance] performAction:@"batch.user.tag"
                                     withArgs:@{@"c" : @"bar", @"t" : @"foo", @"a" : @"remove"}
                                    andSource:nil];

    // Bad values
    [[BAActionsCenter instance] performAction:@"batch.user.tag" withArgs:@{} andSource:nil];
    [[BAActionsCenter instance] performAction:@"batch.user.tag"
                                     withArgs:@{@"c" : @"bar", @"t" : @"foo", @"a" : @"nothing"}
                                    andSource:nil];
    [[BAActionsCenter instance] performAction:@"batch.user.tag"
                                     withArgs:@{@"c" : @"bar", @"t" : @"foo", @"a" : [NSNull null]}
                                    andSource:nil];
    [[BAActionsCenter instance] performAction:@"batch.user.tag"
                                     withArgs:@{@"c" : @"bar", @"t" : @"foo", @"a" : @(20)}
                                    andSource:nil];
    [[BAActionsCenter instance] performAction:@"batch.user.tag" withArgs:@{@"c" : @"bar", @"t" : @"foo"} andSource:nil];

    [[BAActionsCenter instance] performAction:@"batch.user.tag"
                                     withArgs:@{@"c" : @"bar", @"t" : @"", @"a" : @"add"}
                                    andSource:nil];
    [[BAActionsCenter instance] performAction:@"batch.user.tag"
                                     withArgs:@{@"c" : @"bar", @"t" : [NSNull null], @"a" : @"add"}
                                    andSource:nil];
    [[BAActionsCenter instance] performAction:@"batch.user.tag"
                                     withArgs:@{@"c" : @"bar", @"t" : @(20), @"a" : @"add"}
                                    andSource:nil];
    [[BAActionsCenter instance] performAction:@"batch.user.tag" withArgs:@{@"c" : @"bar", @"a" : @"add"} andSource:nil];

    [[BAActionsCenter instance] performAction:@"batch.user.tag"
                                     withArgs:@{@"c" : [NSNull null], @"t" : @"foo", @"a" : @"add"}
                                    andSource:nil];
    [[BAActionsCenter instance] performAction:@"batch.user.tag"
                                     withArgs:@{@"c" : @(20), @"t" : @"foo", @"a" : @"add"}
                                    andSource:nil];
    [[BAActionsCenter instance] performAction:@"batch.user.tag" withArgs:@{@"t" : @"foo", @"a" : @"add"} andSource:nil];

    OCMVerifyAll(batchProfileMock);
    OCMVerifyAll(batchProfileDataEditorMock);
}

- (void)testDeeplinkFromActions {
    DeeplinkDelegateStub *delegate = [DeeplinkDelegateStub new];
    BatchSDK.deeplinkDelegate = delegate;
    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);

    [[BAActionsCenter instance] performAction:@"batch.deeplink" withArgs:@{@"l" : @"http://apple.com"} andSource:nil];

    [self waitForMainThreadLoop];

    [self rejectOpenURL:uiApplicationMock];
    XCTAssertTrue(delegate.hasOpenBeenCalled);
}

- (void)testClipboardAction {
    UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:@"test-pasteboard" create:YES];
    [[BAActionsCenter instance] setValue:pasteboard forKey:@"_pasteboard"];
    [[BAActionsCenter instance] performAction:@"batch.clipboard" withArgs:@{@"t" : @"je suis un texte"} andSource:nil];
    XCTAssertTrue([@"je suis un texte" isEqualToString:pasteboard.string]);
}

- (void)rejectOpenURL:(id)mock {
    OCMReject([mock openURL:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]);
}

- (void)testTrackEventAction {
    self.continueAfterFailure = false;

    MockEventTracker *eventTracker = [MockEventTracker new];
    [BAInjection overlayProtocol:@protocol(BATEventTrackerProtocol)
                        callback:^id _Nullable(id _Nullable originalInstance) {
                          return eventTracker;
                        }];
    // Register a temporary ProfileCenter so that the event tracker is not cached
    [BAInjection overlayProtocol:@protocol(BAProfileCenterProtocol)
                        callback:^id _Nullable(id _Nullable originalInstance) {
                          return [[BAProfileCenter alloc] init];
                        }];

    /*OCMExpect([batchUserMock trackEvent:@"test_event"
     withLabel:@"test_label"
     associatedData:[OCMArg checkWithBlock:^BOOL(id parameter) {
     if (![parameter isKindOfClass:[BatchEventData class]]) {
     return NO;
     }

     BatchEventData *data = parameter;
     return [data->_attributes count] == 0 && [data->_tags count] == 0;
     }]]);*/
    [[BAActionsCenter instance] performAction:@"batch.user.event"
                                     withArgs:@{@"e" : @"test_event", @"l" : @"test_label"}
                                    andSource:nil];

    BAEvent *event = [eventTracker findEventWithName:@"E.TEST_EVENT" parameters:nil];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.parametersDictionary[@"label"], @"test_label");

    [eventTracker reset];
    [[BAActionsCenter instance]
        performAction:@"batch.user.event"
             withArgs:@{@"e" : @"test_event_2", @"l" : @"test_label_2", @"t" : @[ @"tag1", @"tag2", @"tag3" ]}
            andSource:nil];

    event = [eventTracker findEventWithName:@"E.TEST_EVENT_2" parameters:nil];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.parametersDictionary[@"label"], @"test_label_2");
    NSArray *expectedTags = @[ @"tag1", @"tag2", @"tag3" ];
    XCTAssertEqualObjects((NSArray *)[event.parametersDictionary[@"tags"]
                              sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)],
                          expectedTags);

    [eventTracker reset];
    [[BAActionsCenter instance] performAction:@"batch.user.event"
                                     withArgs:@{
                                         @"e" : @"test_event_3",
                                         @"l" : @"test_label_3",
                                         @"a" : @{
                                             @"bool" : @YES,
                                             @"int" : @64,
                                             @"double" : @654.21,
                                             @"string" : @"toto",
                                             @"date" : @"2020-08-09T12:12:23.943Z"
                                         }
                                     }
                                    andSource:nil];

    event = [eventTracker findEventWithName:@"E.TEST_EVENT_3" parameters:nil];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.parametersDictionary[@"label"], @"test_label_3");

    NSDictionary *expectedAttibutes = @{
        @"bool.b" : @(true),
        @"date.t" : @(1596975143943),
        @"double.f" : @(654.21),
        @"int.i" : @(64),
        @"string.s" : @"toto",
    };
    XCTAssertEqualObjects(event.parametersDictionary[@"attributes"], expectedAttibutes);
}

- (void)waitForMainThreadLoop {
    // Since openDeeplink schedules async work on the main thread, we have
    // to perform a little dance to correctly test the behaviour
    // To work around this, we schedule something to run on the main thread
    // AFTER other work has been submitted, and wait for our dummy
    // task to finish
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for a main thread loop run"];
    dispatch_async(dispatch_get_main_queue(), ^{
      [expectation fulfill];
    });
    [self waitForExpectations:@[ expectation ] timeout:3.0];
}

@end
