//
//  swizzlingTests.m
//  BatchTests
//
//  Created by arnaud on 15/09/2020.
//  Copyright © 2020 Batch.com. All rights reserved.
//

@import XCTest;
@import UIKit;
@import Batch.Batch_Private;
#import "BatchTests-Swift.h"
#import "InvocationRecorders.h"
#import "OCMock.h"

#pragma mark Test delegates delcarations

// We could use OCMock to generate a protocol stub but we want a real class as much as possible
@interface StubApplicationDelegate : InvocationRecordingObject <UIApplicationDelegate>

@property BOOL didFailToRegisterRecorded;

@end

// App Delegate that implements all methods
@interface StubCompleteApplicationDelegate : InvocationRecordingObject <UIApplicationDelegate>

@end

@interface BatchApplicationDelegate : NSObject <BAPartialApplicationDelegate>

@property BOOL didFailToRegisterRecorded;
@property BOOL didRegisterForRemoteNotificationsRecorded;

@end

#pragma mark Tests

@interface swizzlingTests : XCTestCase

@end

@implementation swizzlingTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSharedInstance {
    XCTAssertNotNil([BADelegatedApplicationDelegate sharedInstance]);
}

- (void)testChecks {
    // Test sanity checks
    StubApplicationDelegate *applicationDelegate = [StubApplicationDelegate new];

    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);
    OCMStub([uiApplicationMock delegate]).andReturn(applicationDelegate);

    BADelegatedApplicationDelegate *delegatedAppDelegate = [BADelegatedApplicationDelegate new];
    // Test that we can't swizzle with no batch delegate
    XCTAssertFalse([delegatedAppDelegate swizzleAppDelegate]);
    // Test that we can't swizzle if the batch delegate is the same class of the app delegate
    // Which causes an infinite loop
    delegatedAppDelegate.batchDelegate = (id)[StubApplicationDelegate new];
    XCTAssertFalse([delegatedAppDelegate swizzleAppDelegate]);

    BatchApplicationDelegate *batchDelegate = [BatchApplicationDelegate new];
    delegatedAppDelegate.batchDelegate = batchDelegate;
    // Test that we can't swizzle twiice
    XCTAssertTrue([delegatedAppDelegate swizzleAppDelegate]);
    XCTAssertFalse([delegatedAppDelegate swizzleAppDelegate]);
}

- (void)testNoProxy {
    // Tests that NSProxy isn't attempted to be swizzled
    NSProxy *applicationDelegate = [NSProxy alloc];
    // Note that this needs to be another class or else we could end up in an infinite loop
    BatchApplicationDelegate *batchDelegate = [BatchApplicationDelegate new];

    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);
    OCMStub([uiApplicationMock delegate]).andReturn(applicationDelegate);

    BADelegatedApplicationDelegate *delegatedAppDelegate = [BADelegatedApplicationDelegate new];
    delegatedAppDelegate.batchDelegate = batchDelegate;
    XCTAssertFalse([delegatedAppDelegate swizzleAppDelegate]);
}

- (void)testSwizzling {
    StubApplicationDelegate *applicationDelegate = [StubApplicationDelegate new];
    // Note that this needs to be another class or else we could end up in an infinite loop
    BatchApplicationDelegate *batchDelegate = [BatchApplicationDelegate new];

    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);
    OCMStub([uiApplicationMock delegate]).andReturn(applicationDelegate);

    XCTAssertFalse(applicationDelegate.didFailToRegisterRecorded);
    XCTAssertFalse(batchDelegate.didFailToRegisterRecorded);
    XCTAssertFalse(batchDelegate.didRegisterForRemoteNotificationsRecorded);

    BADelegatedApplicationDelegate *delegatedAppDelegate = [BADelegatedApplicationDelegate new];
    delegatedAppDelegate.batchDelegate = batchDelegate;
    XCTAssertTrue([delegatedAppDelegate swizzleAppDelegate]);

    // Test that calling a method calls both the original application delegate, and Batch's implementation
    [UIApplication.sharedApplication.delegate application:uiApplicationMock
         didFailToRegisterForRemoteNotificationsWithError:self.dummyError];
    XCTAssertTrue(applicationDelegate.didFailToRegisterRecorded);
    XCTAssertTrue(batchDelegate.didFailToRegisterRecorded);

    // Test that calling a method that doesn't exist on the original delegate works
    // Also test that the original reference to the app delegate is still the right one and that
    // we didn't break UIApplication.shared.delegate
    [applicationDelegate application:uiApplicationMock didRegisterForRemoteNotificationsWithDeviceToken:[NSData new]];
    XCTAssertTrue(batchDelegate.didRegisterForRemoteNotificationsRecorded);
}

- (void)testSwiftSwizzling {
    SwiftStubApplicationDelegate *applicationDelegate = [SwiftStubApplicationDelegate new];
    // Note that this needs to be another class or else we could end up in an infinite loop
    BatchApplicationDelegate *batchDelegate = [BatchApplicationDelegate new];

    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);
    OCMStub([uiApplicationMock delegate]).andReturn(applicationDelegate);

    XCTAssertFalse(applicationDelegate.didFailToRegisterRecorded);
    XCTAssertFalse(batchDelegate.didFailToRegisterRecorded);
    XCTAssertFalse(batchDelegate.didRegisterForRemoteNotificationsRecorded);

    BADelegatedApplicationDelegate *delegatedAppDelegate = [BADelegatedApplicationDelegate new];
    delegatedAppDelegate.batchDelegate = batchDelegate;
    XCTAssertTrue([delegatedAppDelegate swizzleAppDelegate]);

    // Test that calling a method calls both the original application delegate, and Batch's implementation
    [UIApplication.sharedApplication.delegate application:uiApplicationMock
         didFailToRegisterForRemoteNotificationsWithError:self.dummyError];
    XCTAssertTrue(applicationDelegate.didFailToRegisterRecorded);
    XCTAssertTrue(batchDelegate.didFailToRegisterRecorded);

    // Test that calling a method that doesn't exist on the original delegate works
    [applicationDelegate application:uiApplicationMock didRegisterForRemoteNotificationsWithDeviceToken:[NSData new]];
    XCTAssertTrue(batchDelegate.didRegisterForRemoteNotificationsRecorded);
}

- (void)testOptionalMethods {
    // Test that optional methods aren't added when swizzling

    StubApplicationDelegate *applicationDelegate = [StubApplicationDelegate new];
    // Note that this needs to be another class or else we could end up in an infinite loop
    BatchApplicationDelegate *batchDelegate = [BatchApplicationDelegate new];

    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);
    OCMStub([uiApplicationMock delegate]).andReturn(applicationDelegate);

    BADelegatedApplicationDelegate *delegatedAppDelegate = [BADelegatedApplicationDelegate new];
    delegatedAppDelegate.batchDelegate = batchDelegate;
    XCTAssertTrue([delegatedAppDelegate swizzleAppDelegate]);

    XCTAssertFalse([applicationDelegate respondsToSelector:@selector(application:
                                                               didReceiveRemoteNotification:fetchCompletionHandler:)]);
    XCTAssertFalse([applicationDelegate
        respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)]);
    XCTAssertFalse([applicationDelegate
        respondsToSelector:@selector(application:
                               handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)]);

    StubCompleteApplicationDelegate *completeApplicationDelegate = [StubCompleteApplicationDelegate new];
    OCMStub([uiApplicationMock delegate]).andReturn(completeApplicationDelegate);
    delegatedAppDelegate = [BADelegatedApplicationDelegate new];
    delegatedAppDelegate.batchDelegate = batchDelegate;
    XCTAssertTrue([delegatedAppDelegate swizzleAppDelegate]);

    XCTAssertTrue([completeApplicationDelegate
        respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]);
    XCTAssertTrue([completeApplicationDelegate
        respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)]);
    XCTAssertTrue([completeApplicationDelegate
        respondsToSelector:@selector(application:
                               handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)]);
}

- (void)testNonoptionalMethods {
    // Test that calling all known delegate methods:
    //  - Doesn't crash
    //  - Calls the original delegate
    //  - Calls Batch's delegate
    // This is tested both on a partial and a full delegate
    // Note: this test has to be updated every time new methods are swizzled
    // (which should basically never happen anymore)

    StubApplicationDelegate *applicationDelegate = [StubApplicationDelegate new];
    BatchApplicationDelegate *batchDelegate = [BatchApplicationDelegate new];
    // Use an InvocationRecordingProxy to record the called selectors
    InvocationRecordingProxy *batchDelegateProxy = [InvocationRecordingProxy proxyWithObject:batchDelegate];

    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);
    OCMStub([uiApplicationMock delegate]).andReturn(applicationDelegate);

    BADelegatedApplicationDelegate *delegatedAppDelegate = [BADelegatedApplicationDelegate new];
    delegatedAppDelegate.batchDelegate = (id)batchDelegateProxy;
    XCTAssertTrue([delegatedAppDelegate swizzleAppDelegate]);

    [self callAllDelegateMethodsOn:applicationDelegate applicationMock:uiApplicationMock];
    XCTAssertEqual(1, [applicationDelegate.invokedSelectors count]);
    // Optional methods aren't supposed to be implemented, so we expect less calls than all
    // that's supported by the delegate
    XCTAssertEqual(4, [batchDelegateProxy.proxy_invokedSelectors count]);
}

- (void)testAllMethods {
    // Test that calling all known delegate methods:
    //  - Doesn't crash
    //  - Calls the original delegate
    //  - Calls Batch's delegate
    // This is tested both on a partial and a full delegate
    // Note: this test has to be updated every time new methods are swizzled
    // (which should basically never happen anymore)

    StubCompleteApplicationDelegate *applicationDelegate = [StubCompleteApplicationDelegate new];
    BatchApplicationDelegate *batchDelegate = [BatchApplicationDelegate new];
    // Use an InvocationRecordingProxy to record the called selectors
    InvocationRecordingProxy *batchDelegateProxy = [InvocationRecordingProxy proxyWithObject:batchDelegate];

    id uiApplicationMock = OCMClassMock([UIApplication class]);
    OCMStub([uiApplicationMock sharedApplication]).andReturn(uiApplicationMock);
    OCMStub([uiApplicationMock delegate]).andReturn(applicationDelegate);

    BADelegatedApplicationDelegate *delegatedAppDelegate = [BADelegatedApplicationDelegate new];
    delegatedAppDelegate.batchDelegate = (id)batchDelegateProxy;
    XCTAssertTrue([delegatedAppDelegate swizzleAppDelegate]);

    [self callAllDelegateMethodsOn:applicationDelegate applicationMock:uiApplicationMock];
    XCTAssertEqual(7, [applicationDelegate.invokedSelectors count]);
    XCTAssertEqual(7, [batchDelegateProxy.proxy_invokedSelectors count]);
}

- (void)callAllDelegateMethodsOn:(id<UIApplicationDelegate>)delegate applicationMock:(UIApplication *)application {
    if ([delegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
        [delegate application:application didRegisterForRemoteNotificationsWithDeviceToken:[NSData new]];
    }

    if ([delegate respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]) {
        [delegate application:application didFailToRegisterForRemoteNotificationsWithError:[self dummyError]];
    }

    if ([delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
        [delegate application:application
            didReceiveRemoteNotification:[NSDictionary new]
                  fetchCompletionHandler:^(UIBackgroundFetchResult result){
                  }];
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)]) {
        [delegate application:application didReceiveRemoteNotification:[NSDictionary new]];
    }

    if ([delegate respondsToSelector:@selector(application:didRegisterUserNotificationSettings:)]) {
        id userNotificationSettings = OCMClassMock([UIUserNotificationSettings class]);
        [delegate application:application didRegisterUserNotificationSettings:userNotificationSettings];
    }

    if ([delegate respondsToSelector:@selector(application:
                                         handleActionWithIdentifier:forRemoteNotification:completionHandler:)]) {
        [delegate application:application
            handleActionWithIdentifier:@"foo"
                 forRemoteNotification:[NSDictionary new]
                     completionHandler:^{
                     }];
    }

    if ([delegate respondsToSelector:@selector
                  (application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)]) {
        [delegate application:application
            handleActionWithIdentifier:@"foo"
                 forRemoteNotification:[NSDictionary new]
                      withResponseInfo:[NSDictionary new]
                     completionHandler:^{
                     }];
    }
#pragma clang diagnostic pop
}

- (NSError *)dummyError {
    return [NSError errorWithDomain:@"tests" code:0 userInfo:nil];
}

@end

#pragma mark Test delegates

@implementation StubApplicationDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _didFailToRegisterRecorded = false;
    }
    return self;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self recordSelector:_cmd];
    _didFailToRegisterRecorded = true;
}

@end

// This class should record its invocations itself as we can't swizzle a NSProxy
@implementation StubCompleteApplicationDelegate

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self recordSelector:_cmd];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self recordSelector:_cmd];
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self recordSelector:_cmd];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self recordSelector:_cmd];
}

- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [self recordSelector:_cmd];
}

- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
         forRemoteNotification:(NSDictionary *)userInfo
             completionHandler:(void (^)(void))completionHandler {
    [self recordSelector:_cmd];
}

- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
         forRemoteNotification:(NSDictionary *)userInfo
              withResponseInfo:(NSDictionary *)responseInfo
             completionHandler:(void (^)(void))completionHandler {
    [self recordSelector:_cmd];
}

#pragma clang diagnostic pop

@end

// We don't need to record calls here as we'll use a proxy object to do so
@implementation BatchApplicationDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _didFailToRegisterRecorded = false;
        _didRegisterForRemoteNotificationsRecorded = false;
    }
    return self;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    _didFailToRegisterRecorded = true;
}

- (void)application:(nonnull UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo {
}

- (void)application:(nonnull UIApplication *)application
    didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo
          fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
}

- (void)application:(nonnull UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken {
    _didRegisterForRemoteNotificationsRecorded = true;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)application:(nonnull UIApplication *)application
    didRegisterUserNotificationSettings:(nonnull UIUserNotificationSettings *)notificationSettings {
}

#pragma clang diagnostic pop

- (void)application:(nonnull UIApplication *)application
    handleActionWithIdentifier:(nullable NSString *)identifier
         forRemoteNotification:(nonnull NSDictionary *)userInfo
             completionHandler:(nonnull void (^)(void))completionHandler {
}

- (void)application:(nonnull UIApplication *)application
    handleActionWithIdentifier:(nullable NSString *)identifier
         forRemoteNotification:(nonnull NSDictionary *)userInfo
              withResponseInfo:(nonnull NSDictionary *)responseInfo
             completionHandler:(nonnull void (^)(void))completionHandler {
}

@end
