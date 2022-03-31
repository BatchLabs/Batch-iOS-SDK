//
//  BatchCoreCenterTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BACoreCenter.h"
#import "OCMock.h"

@interface BatchCoreCenterTests : XCTestCase

@end

@implementation BatchCoreCenterTests

- (void)setUp {
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown {
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    [[BACoreCenter instance].configuration setAssociatedDomains:[NSArray array]];
}

- (void)testBasics {
    XCTAssertNotNil([BACoreCenter instance], @"Failed to create a Batch center instance.");

    XCTAssertNotNil([BACoreCenter instance].status, @"Empty status in Batch center instance.");

    XCTAssertNotNil([BACoreCenter instance].configuration, @"Empty configuration in Batch center instance.");
}

- (void)testUniversalLinks {
    id uiApplicationDelegateMock = OCMProtocolMock(@protocol(UIApplicationDelegate));
    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);
    OCMStub([uiApplicationMock delegate]).andReturn(uiApplicationDelegateMock);

    NSArray *domains = [NSArray arrayWithObjects:@"apple.fr", nil];
    [[BACoreCenter instance].configuration setAssociatedDomains:domains];

    [[BACoreCenter instance] openDeeplink:@"https://apple.fr/test?id=3" inApp:YES];
    [[BACoreCenter instance] openDeeplink:@"https://apple.fr/test?id=3" inApp:NO];
    OCMVerify(times(2), [uiApplicationDelegateMock application:[OCMArg any]
                                          continueUserActivity:[OCMArg any]
                                            restorationHandler:[OCMArg any]]);

    [[BACoreCenter instance] openDeeplink:@"https://www.apple.fr/test?id=3" inApp:YES];
    OCMReject([uiApplicationDelegateMock application:[OCMArg any]
                                continueUserActivity:[OCMArg any]
                                  restorationHandler:[OCMArg any]]);
}

@end
