//
//  batchUNUserNotificationCenterDelegateTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@import XCTest;
#import "OCMock.h"

@import UserNotifications;
@import Batch;

@interface batchUNUserNotificationCenterDelegateTests : XCTestCase

@end

@implementation batchUNUserNotificationCenterDelegateTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testRetain {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-unsafe-retained-assign"

    // Test that a normal delegate instanciation is not retained
    __weak BatchUNUserNotificationCenterDelegate *delegate;
    @autoreleasepool {
        delegate = [BatchUNUserNotificationCenterDelegate new];
    }
    XCTAssertNil(delegate);

#pragma clang diagnostic pop

    // Test that sharedInstance is retained
    @autoreleasepool {
        delegate = [BatchUNUserNotificationCenterDelegate sharedInstance];
    }
    XCTAssertNotNil(delegate);
}

- (void)testRegister {
    id unNotificationCenterMock = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([unNotificationCenterMock currentNotificationCenter]).andReturn(unNotificationCenterMock);

    OCMExpect([unNotificationCenterMock setDelegate:[BatchUNUserNotificationCenterDelegate sharedInstance]]);

    [BatchUNUserNotificationCenterDelegate registerAsDelegate];

    OCMVerifyAll(unNotificationCenterMock);
}

- (void)testForwarding {
    // Test that methods are forwarded to batch
    id unNotificationCenterMock = OCMClassMock([UNUserNotificationCenter class]);
    id notificationMock = OCMClassMock([UNNotification class]);
    id notificationResponseMock = OCMClassMock([UNNotificationResponse class]);

    id baPushCenterMock = OCMClassMock([BAPushCenter class]);
    [baPushCenterMock setExpectationOrderMatters:YES];

    // Test that the foreground option works in both modes
    OCMExpect([baPushCenterMock handleUserNotificationCenter:unNotificationCenterMock
                                     willPresentNotification:notificationMock
                               willShowSystemForegroundAlert:false]);

    OCMExpect([baPushCenterMock handleUserNotificationCenter:unNotificationCenterMock
                              didReceiveNotificationResponse:notificationResponseMock]);

    BatchUNUserNotificationCenterDelegate *delegate = [BatchUNUserNotificationCenterDelegate new];
    delegate.showForegroundNotifications = false;

    __block BOOL completionHandlerCalled = false;

    [delegate userNotificationCenter:unNotificationCenterMock
             willPresentNotification:notificationMock
               withCompletionHandler:^(UNNotificationPresentationOptions options) {
                 completionHandlerCalled = true;
               }];

    XCTAssertTrue(completionHandlerCalled);

    completionHandlerCalled = false;
    [delegate userNotificationCenter:unNotificationCenterMock
        didReceiveNotificationResponse:notificationResponseMock
                 withCompletionHandler:^{
                   completionHandlerCalled = true;
                 }];
    XCTAssertTrue(completionHandlerCalled);

    OCMVerifyAll(baPushCenterMock);
}

- (void)testForegroundNotifications {
    id unNotificationCenterMock = OCMClassMock([UNUserNotificationCenter class]);
    id notificationMock = OCMClassMock([UNNotification class]);

    id baPushCenterMock = OCMClassMock([BAPushCenter class]);
    [baPushCenterMock setExpectationOrderMatters:YES];

    // Test that the foreground option works in both modes
    OCMExpect([baPushCenterMock handleUserNotificationCenter:[OCMArg any]
                                     willPresentNotification:[OCMArg any]
                               willShowSystemForegroundAlert:true]);
    OCMExpect([baPushCenterMock handleUserNotificationCenter:[OCMArg any]
                                     willPresentNotification:[OCMArg any]
                               willShowSystemForegroundAlert:false]);

    BatchUNUserNotificationCenterDelegate *delegate = [BatchUNUserNotificationCenterDelegate new];
    // Test default value
    XCTAssertTrue(delegate.showForegroundNotifications);

    // Test that the delegate can show foreground notifications
    [delegate userNotificationCenter:unNotificationCenterMock
             willPresentNotification:notificationMock
               withCompletionHandler:^(UNNotificationPresentationOptions options) {
                 UNNotificationPresentationOptions expectedOptions =
                     UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound;
                 if (@available(iOS 14.0, *)) {
                     expectedOptions |= UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner;
                 } else {
                     expectedOptions |= UNNotificationPresentationOptionAlert;
                 }
                 XCTAssertEqual(expectedOptions, options);
               }];

    // Test that the delegate doesn't show foreground notifications
    delegate.showForegroundNotifications = false;
    [delegate userNotificationCenter:unNotificationCenterMock
             willPresentNotification:notificationMock
               withCompletionHandler:^(UNNotificationPresentationOptions options) {
                 XCTAssertEqual(0, options);
               }];

    OCMVerifyAll(baPushCenterMock);
}

@end
