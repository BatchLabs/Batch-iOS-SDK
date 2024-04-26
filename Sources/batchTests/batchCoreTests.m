//
//  BatchCoreTests.m
//  BatchCoreTests
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Batch.h"

#import <UIKit/UIKit.h>
#import <objc/message.h>

#import "OCMock.h"

@interface MockLoggerDelegate : NSObject <BatchLoggerDelegate>
@property NSString *message;
@end

@interface batchCoreTests : XCTestCase

@end

@implementation batchCoreTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPublicMethods {
    id unNotificationMock = OCMClassMock([UNUserNotificationCenter class]);
    OCMExpect([unNotificationMock currentNotificationCenter]).andReturn(nil);

    /*** Start ***/

    // Start Batch and stop it with different keys.
    // We can't test the feedback on key error, but we can test that it does not crash.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    [BatchSDK startWithAPIKey:nil];
#pragma clang diagnostic pop

    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification object:nil];

    [BatchSDK startWithAPIKey:@""];

    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification object:nil];

    [BatchSDK startWithAPIKey:@"MYDEVKEY"];

    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification object:nil];

    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}

- (void)testLoggerDelegate {
    MockLoggerDelegate *delegate = [MockLoggerDelegate new];

    XCTAssertNil(delegate.message);

    [BatchSDK setLoggerDelegate:delegate];

    // Force logging
    ((void (*)(id, SEL))objc_msgSend)(NSClassFromString(@"BALogger"), NSSelectorFromString(@"enableInternalLogs"));

    // Trigger a message
    [BatchSDK optIn];

    XCTAssertNotNil(delegate.message);

    delegate.message = nil;

    // Unforce logging
    ((void (*)(id, SEL))objc_msgSend)(NSClassFromString(@"BALogger"), NSSelectorFromString(@"disableInternalLogs"));

    // Trigger a message
    [BatchSDK optIn];

    XCTAssertNil(delegate.message);
}

@end

@implementation MockLoggerDelegate
- (void)logWithMessage:(NSString *)message {
    self.message = message;
}
@end
