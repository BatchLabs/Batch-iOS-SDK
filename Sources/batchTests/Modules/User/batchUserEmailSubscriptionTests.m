//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BATrackerCenter.h"
#import "OCMock.h"

@interface batchUserEmailSubscriptionTests : XCTestCase

@end

@implementation batchUserEmailSubscriptionTests {
    id userMock;
    id trackerCenterMock;
}

- (void)setUp {
    userMock = OCMClassMock([BatchUser class]);
    trackerCenterMock = OCMClassMock([BATrackerCenter class]);
    OCMStub([trackerCenterMock instance]).andReturn(trackerCenterMock);
    OCMStub([userMock identifier]).andReturn(@"test_id");
}

- (void)tearDown {
    [userMock stopMocking];
    [trackerCenterMock stopMocking];
}

- (void)testSendEmailOnly {
    BAUserEmailSubscription *emailSubscription = [[BAUserEmailSubscription alloc] init];
    [emailSubscription setEmail:@"test@batch.com"];
    OCMExpect([trackerCenterMock trackPrivateEvent:@"_EMAIL_CHANGED" parameters:self.eventEmailOnly]);
    [emailSubscription sendEmailSubscriptionEvent];
    OCMVerifyAll(trackerCenterMock);
}

- (void)testSendEmailNullOnly {
    BAUserEmailSubscription *emailSubscription = [[BAUserEmailSubscription alloc] init];
    [emailSubscription setEmail:nil];
    OCMExpect([trackerCenterMock trackPrivateEvent:@"_EMAIL_CHANGED" parameters:self.eventEmailNullOnly]);
    [emailSubscription sendEmailSubscriptionEvent];
    OCMVerifyAll(trackerCenterMock);
}

- (void)testSendEmailSubscriptionOnly {
    BAUserEmailSubscription *emailSubscription = [[BAUserEmailSubscription alloc] init];
    [emailSubscription setEmailSubscriptionState:BatchEmailSubscriptionStateSubscribed forKind:BAEmailKindMarketing];
    OCMExpect([trackerCenterMock trackPrivateEvent:@"_EMAIL_CHANGED" parameters:self.eventEmailSubscriptionOnly]);
    [emailSubscription sendEmailSubscriptionEvent];
    OCMVerifyAll(trackerCenterMock);
}

- (void)testSendEmailSubscriptionFull {
    BAUserEmailSubscription *emailSubscription = [[BAUserEmailSubscription alloc] init];
    [emailSubscription setEmail:@"test@batch.com"];
    [emailSubscription setEmailSubscriptionState:BatchEmailSubscriptionStateUnsubscribed forKind:BAEmailKindMarketing];
    OCMExpect([trackerCenterMock trackPrivateEvent:@"_EMAIL_CHANGED" parameters:self.eventEmailSubscriptionFull]);
    [emailSubscription sendEmailSubscriptionEvent];
    OCMVerifyAll(trackerCenterMock);
}

- (NSDictionary *)eventEmailOnly {
    return @{@"custom_id" : @"test_id", @"email" : @"test@batch.com"};
}

- (NSDictionary *)eventEmailNullOnly {
    return @{@"custom_id" : @"test_id", @"email" : [NSNull null]};
}

- (NSDictionary *)eventEmailSubscriptionOnly {
    return @{
        @"custom_id" : @"test_id",
        @"subscriptions" : @{
            @"marketing" : @"subscribed",
        }
    };
}

- (NSDictionary *)eventEmailSubscriptionFull {
    return @{
        @"custom_id" : @"test_id",
        @"email" : @"test@batch.com",
        @"subscriptions" : @{
            @"marketing" : @"unsubscribed",
        }
    };
}

@end
