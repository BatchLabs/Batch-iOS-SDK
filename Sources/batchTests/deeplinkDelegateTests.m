//
//  deeplinkDelegateTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BACoreCenter.h"
#import "BatchCore.h"
#import "DeeplinkDelegateStub.h"

#import "OCMock.h"

@interface deeplinkDelegateTests : XCTestCase

@end

@implementation deeplinkDelegateTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    [Batch setDeeplinkDelegate:nil];
}

- (void)testNoDelegate {
    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);

    [[BACoreCenter instance] openDeeplink:@"https://apple.fr" inApp:NO];

    [self verifyOpenURL:uiApplicationMock];
}

- (void)testInvalidURL {
    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);

    [[BACoreCenter instance] openDeeplink:@"poula%" inApp:NO];

    [self rejectOpenURL:uiApplicationMock];

    DeeplinkDelegateStub *delegate = [DeeplinkDelegateStub new];
    Batch.deeplinkDelegate = delegate;

    [[BACoreCenter instance] openDeeplink:@"poula%" inApp:NO];
    [self waitForMainThreadLoop];

    XCTAssertTrue(delegate.hasOpenBeenCalled);
}

- (void)testDelegateRemoval {
    DeeplinkDelegateStub *delegate = [DeeplinkDelegateStub new];
    Batch.deeplinkDelegate = delegate;
    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);

    [[BACoreCenter instance] openDeeplink:@"https://apple.fr" inApp:NO];
    [self waitForMainThreadLoop];
    XCTAssertTrue(delegate.hasOpenBeenCalled);

    Batch.deeplinkDelegate = nil;
    [[BACoreCenter instance] openDeeplink:@"https://apple.fr" inApp:NO];
    [self waitForMainThreadLoop];
    [self verifyOpenURL:uiApplicationMock];
}

- (void)testDelegate {
    DeeplinkDelegateStub *delegate = [DeeplinkDelegateStub new];
    Batch.deeplinkDelegate = delegate;
    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);

    [[BACoreCenter instance] openDeeplink:@"https://apple.fr" inApp:NO];
    [self waitForMainThreadLoop];

    [self rejectOpenURL:uiApplicationMock];
    XCTAssertTrue(delegate.hasOpenBeenCalled);
}

- (void)testDelegateWeakness {
    // We need an explicit autorelease pool, so it can be drained
    // Otherwise, we can't test this accurately
    @autoreleasepool {
        DeeplinkDelegateStub *delegate = [DeeplinkDelegateStub new];
        [Batch setDeeplinkDelegate:delegate];
        XCTAssertEqual(Batch.deeplinkDelegate, delegate);
        delegate = nil;
    }
    XCTAssertNil(Batch.deeplinkDelegate);
}

- (void)verifyOpenURL:(id)mock {
    OCMVerify([mock openURL:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]);
}

- (void)rejectOpenURL:(id)mock {
    OCMReject([mock openURL:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]);
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
