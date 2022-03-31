//
//  inboxWebserviceClientTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCMock.h"

#import "BAInboxFetchWebserviceClient.h"
#import "BAWebserviceURLBuilder.h"
#import "BatchInboxPrivate.h"

@interface inboxFetchWebserviceClientTests : XCTestCase

@property (nonatomic) id helperMock;

@end

@implementation inboxFetchWebserviceClientTests

- (void)setUp {
    [super setUp];

    _helperMock = OCMClassMock([BAWebserviceURLBuilder class]);
    OCMStub([_helperMock webserviceURLForShortname:[OCMArg any]])
        .andReturn([NSURL URLWithString:@"https://batch.com/"]);
}

- (void)tearDown {
    [super tearDown];

    [_helperMock stopMocking];
    _helperMock = nil;
}

- (void)testParseResponse {
    BAWebserviceClient *client = [[BAInboxFetchWebserviceClient alloc] initWithIdentifier:@"test-id"
        type:BAInboxWebserviceClientTypeInstallation
        authenticationKey:nil
        limit:20
        fetcherId:-1
        fromToken:nil
        success:^(BAInboxWebserviceResponse *_Nonnull response) {
          XCTAssertFalse([response hasMore]);
          XCTAssertFalse([response didTimeout]);
          XCTAssertNil([response cursor]);
          XCTAssertEqual([[response notifications] count], 4);
        }
        error:^(NSError *_Nonnull error) {
          XCTAssert(false);
        }];

    NSString *payload =
        @"{\"notifications\":[{\"notificationId\":\"a09c5300-7a3b-11ea-ac39-29b797ebf207\",\"notificationTime\":"
        @"1586420710448,\"sendId\":\"9761e19205fd0aa66721dc7a94db4ae2-push_action-u1586420710260\",\"payload\":{"
        @"\"aps\":{\"alert\":\"Bienvenue sur la sample iOS ! Si nos calculs sont bons, tu l'as installée il y a 5 "
        @"minutes, \\u0026 tu reçois donc cette trigger campaign dédicacée en guise de félicitations. "
        @"\",\"mutable-content\":1,\"sound\":\"default\"},\"com.batch\":{\"t\":\"tc\",\"i\":"
        @"\"9761e19205fd0aa66721dc7a94db4ae2-push_action-u1586420710260\",\"od\":{\"n\":\"a09c5300-7a3b-11ea-ac39-"
        @"29b797ebf207\",\"an\":\"push_action\",\"ct\":\"9761e19205fd0aa66721dc7a94db4ae2\"}}}},{\"notificationId\":"
        @"\"5a3c93c0-7a3b-11ea-a6e5-69f412bc3147\",\"notificationTime\":1586420592380,\"sendId\":\"6y4g8guj-"
        @"u1586420592376_2519\",\"payload\":{\"aps\":{\"alert\":{\"title\":\"Je suis un "
        @"test\",\"body\":\"salut\"},\"mutable-content\":1,\"sound\":\"default\"},\"com.batch\":{\"t\":\"t\",\"l\":"
        @"\"https://"
        @"batch.com\",\"i\":\"6y4g8guj-u1586420592376_2519\",\"od\":{\"n\":\"5a3c93c0-7a3b-11ea-a6e5-69f412bc3147\"}},"
        @"\"eventCTA\":\"event_name_test\",\"phoneCTA\":\"0606060606\"}},{\"notificationId\":\"52fc0a50-7a3b-11ea-9721-"
        @"5dc7a8e0ba90\",\"notificationTime\":1586420580213,\"sendId\":\"6y4g8guj-u1586420580206_a910\",\"payload\":{"
        @"\"aps\":{\"alert\":{\"title\":\"Je suis un test\",\"body\":\"Je suis un "
        @"test\"},\"mutable-content\":1,\"sound\":\"default\"},\"com.batch\":{\"t\":\"t\",\"l\":\"https://"
        @"batch.com\",\"i\":\"6y4g8guj-u1586420580206_a910\",\"od\":{\"n\":\"52fc0a50-7a3b-11ea-9721-5dc7a8e0ba90\"}},"
        @"\"eventCTA\":\"event_name_test\",\"phoneCTA\":\"0606060606\"}},{\"notificationId\":\"4691f090-7a3b-11ea-b23d-"
        @"593c9db5728a\",\"notificationTime\":1586420559385,\"sendId\":\"6y4g8guj-u1586420559374_d395\",\"payload\":{"
        @"\"aps\":{\"alert\":{\"title\":\"rgdrg\",\"body\":\"drgdrg\"},\"mutable-content\":1,\"sound\":\"default\"},"
        @"\"com.batch\":{\"t\":\"t\",\"l\":\"https://"
        @"batch.com\",\"i\":\"6y4g8guj-u1586420559374_d395\",\"od\":{\"n\":\"4691f090-7a3b-11ea-b23d-593c9db5728a\"}}}}"
        @"],\"hasMore\":false,\"timeout\":false}";
    NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
    [client connectionDidFinishLoadingWithData:data];
}

@end
