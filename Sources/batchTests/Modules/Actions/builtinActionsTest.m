#import <Batch/Batch.h>
#import <XCTest/XCTest.h>
#import "BAActionsCenter.h"
#import "DeeplinkDelegateStub.h"
#import "OCMock.h"

@interface builtinActionsTest : XCTestCase
@end

@implementation builtinActionsTest

- (void)tearDown {
    [Batch setDeeplinkDelegate:nil];
}

- (void)testTagEditAction {
    id batchUserMock = OCMClassMock([BatchUser class]);
    id batchUserDataEditorMock = OCMClassMock([BatchUserDataEditor class]);
    [batchUserDataEditorMock setExpectationOrderMatters:YES];

    OCMExpect([batchUserMock editor]).andReturn(batchUserDataEditorMock);
    OCMExpect([batchUserDataEditorMock addTag:@"foo" inCollection:@"bar"]);
    OCMExpect([batchUserDataEditorMock save]);

    OCMExpect([batchUserMock editor]).andReturn(batchUserDataEditorMock);
    OCMExpect([(BatchUserDataEditor *)batchUserDataEditorMock removeTag:@"foo" fromCollection:@"bar"]);
    OCMExpect([batchUserDataEditorMock save]);

    OCMReject([batchUserMock editor]);

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

    OCMVerifyAll(batchUserMock);
    OCMVerifyAll(batchUserDataEditorMock);
}

- (void)testDeeplinkFromActions {
    DeeplinkDelegateStub *delegate = [DeeplinkDelegateStub new];
    Batch.deeplinkDelegate = delegate;
    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);

    [[BAActionsCenter instance] performAction:@"batch.deeplink" withArgs:@{@"l" : @"http://apple.com"} andSource:nil];

    [self waitForMainThreadLoop];

    [self rejectOpenURL:uiApplicationMock];
    XCTAssertTrue(delegate.hasOpenBeenCalled);
}

- (void)testClipboardAction {
    [[BAActionsCenter instance] performAction:@"batch.clipboard" withArgs:@{@"t" : @"je suis un texte"} andSource:nil];

    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    XCTAssertTrue([@"je suis un texte" isEqualToString:pasteboard.string]);
}

- (void)rejectOpenURL:(id)mock {
    OCMReject([mock openURL:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]);
}

- (void)testTrackEventAction {
    id batchUserMock = OCMClassMock([BatchUser class]);
    [batchUserMock setExpectationOrderMatters:YES];

    OCMExpect([batchUserMock trackEvent:@"test_event"
                              withLabel:@"test_label"
                         associatedData:[OCMArg checkWithBlock:^BOOL(id parameter) {
                           if (![parameter isKindOfClass:[BatchEventData class]]) {
                               return NO;
                           }

                           BatchEventData *data = parameter;
                           return [data->_attributes count] == 0 && [data->_tags count] == 0;
                         }]]);
    [[BAActionsCenter instance] performAction:@"batch.user.event"
                                     withArgs:@{@"e" : @"test_event", @"l" : @"test_label"}
                                    andSource:nil];

    OCMExpect([batchUserMock trackEvent:@"test_event_2"
                              withLabel:@"test_label_2"
                         associatedData:[OCMArg checkWithBlock:^BOOL(id parameter) {
                           if (![parameter isKindOfClass:[BatchEventData class]]) {
                               return NO;
                           }

                           BatchEventData *data = parameter;
                           if ([data->_attributes count] != 0) {
                               return NO;
                           }

                           return [data->_tags count] == 3 && [data->_tags containsObject:@"tag1"] &&
                                  [data->_tags containsObject:@"tag2"] && [data->_tags containsObject:@"tag3"];
                         }]]);
    [[BAActionsCenter instance]
        performAction:@"batch.user.event"
             withArgs:@{@"e" : @"test_event_2", @"l" : @"test_label_2", @"t" : @[ @"tag1", @"tag2", @"tag3" ]}
            andSource:nil];

    OCMExpect([batchUserMock trackEvent:@"test_event_3"
                              withLabel:@"test_label_3"
                         associatedData:[OCMArg checkWithBlock:^BOOL(id parameter) {
                           if (![parameter isKindOfClass:[BatchEventData class]]) {
                               return NO;
                           }

                           BatchEventData *data = parameter;
                           if ([data->_attributes count] != 5) {
                               return NO;
                           }

                           BATTypedEventAttribute *boolAttr = [data->_attributes objectForKey:@"bool"];
                           if (boolAttr.type != BAEventAttributeTypeBool || ![boolAttr.value isEqual:@YES]) {
                               return NO;
                           }

                           BATTypedEventAttribute *intAttr = [data->_attributes objectForKey:@"int"];
                           if (intAttr.type != BAEventAttributeTypeInteger || ![intAttr.value isEqual:@64]) {
                               return NO;
                           }

                           BATTypedEventAttribute *doubleAttr = [data->_attributes objectForKey:@"double"];
                           if (doubleAttr.type != BAEventAttributeTypeDouble || ![doubleAttr.value isEqual:@654.21]) {
                               return NO;
                           }

                           BATTypedEventAttribute *stringAttr = [data->_attributes objectForKey:@"string"];
                           if (stringAttr.type != BAEventAttributeTypeString || ![stringAttr.value isEqual:@"toto"]) {
                               return NO;
                           }

                           BATTypedEventAttribute *dateAttr = [data->_attributes objectForKey:@"date"];
                           if (dateAttr.type != BAEventAttributeTypeDate) {
                               return NO;
                           }

                           NSNumber *timestampValue = (NSNumber *)dateAttr.value;
                           return [timestampValue isEqual:@1596975143943];
                         }]]);
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

    OCMVerifyAll(batchUserMock);
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
