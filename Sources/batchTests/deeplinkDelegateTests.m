//
//  deeplinkDelegateTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BACoreCenter.h"
#import "BatchCore.h"
#import "BatchTests-Swift.h"
#import "DeeplinkDelegateStub.h"

#import "OCMock.h"

@interface deeplinkDelegateTests : XCTestCase

@end

@implementation deeplinkDelegateTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    [BatchSDK setDeeplinkDelegate:nil];
}

- (void)testNoDelegate {
    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);

    [[BACoreCenter instance] openDeeplink:@"https://apple.fr" inApp:NO];
    [self waitForMainThreadLoop];

    [self verifyOpenURL:uiApplicationMock];
}

- (void)testInvalidURL {
    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);

    [[BACoreCenter instance] openDeeplink:@" https://poula" inApp:NO];

    [self rejectOpenURL:uiApplicationMock];

    DeeplinkDelegateStub *delegate = [DeeplinkDelegateStub new];
    BatchSDK.deeplinkDelegate = delegate;

    [[BACoreCenter instance] openDeeplink:@" https://poula" inApp:NO];
    [self waitForMainThreadLoop];

    XCTAssertTrue(delegate.hasOpenBeenCalled);
}

- (void)testDelegateRemoval {
    DeeplinkDelegateStub *delegate = [DeeplinkDelegateStub new];
    BatchSDK.deeplinkDelegate = delegate;
    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);

    [[BACoreCenter instance] openDeeplink:@"https://apple.fr" inApp:NO];
    [self waitForMainThreadLoop];
    XCTAssertTrue(delegate.hasOpenBeenCalled);

    BatchSDK.deeplinkDelegate = nil;
    [[BACoreCenter instance] openDeeplink:@"https://apple.fr" inApp:NO];
    [self waitForMainThreadLoop];
    [self verifyOpenURL:uiApplicationMock];
}

- (void)testDelegate {
    DeeplinkDelegateStub *delegate = [DeeplinkDelegateStub new];
    BatchSDK.deeplinkDelegate = delegate;
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
        [BatchSDK setDeeplinkDelegate:delegate];
        XCTAssertEqual(BatchSDK.deeplinkDelegate, delegate);
        delegate = nil;
    }
    XCTAssertNil(BatchSDK.deeplinkDelegate);
}

- (void)verifyOpenURL:(id)mock {
    OCMVerify([mock openURL:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]);
}

- (void)rejectOpenURL:(id)mock {
    OCMReject([mock openURL:[OCMArg any] options:[OCMArg any] completionHandler:[OCMArg any]]);
}

@end
