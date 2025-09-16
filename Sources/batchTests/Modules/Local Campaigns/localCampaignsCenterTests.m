//
//  localCampaignsCenterTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@import XCTest;
#import "OCMock.h"
@import Batch.Batch_Private;

@interface localCampaignsCenterTests : XCTestCase
@end

@interface BALocalCampaignsCenter (Tests)
- (void)loadCampaignCache;
@end

@implementation localCampaignsCenterTests

- (void)testPersistence {
    @autoreleasepool {
        BAMutableDateProvider *dateProvider = [[BAMutableDateProvider alloc] initWithTimestamp:1000];

        id mockPersistence = OCMProtocolMock(@protocol(BALocalCampaignsPersisting));
        [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:mockPersistence];

        BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
        [lcCenter setValue:dateProvider forKey:@"dateProvider"];

        [mockPersistence setExpectationOrderMatters:YES];

        OCMExpect([mockPersistence deleteCampaigns]);
        [lcCenter handleWebserviceResponsePayload:@{@"error" : @{@"code" : @(2), @"reason" : @"internal error"}}];

        OCMExpect([mockPersistence deleteCampaigns]);
        [lcCenter handleWebserviceResponsePayload:[self invalidCampaignsTypePayload]];

        // Saves an empty campaign list (ch17038)
        OCMExpect([mockPersistence persistCampaigns:[self emptyPayloadWithDate]]);
        [lcCenter handleWebserviceResponsePayload:[self emptyPayload]];

        // Ignores unknown keys
        OCMExpect([mockPersistence persistCampaigns:[self emptyPayloadWithDate]]);
        [lcCenter handleWebserviceResponsePayload:[self emptyWithUnknownKeyPayload]];

        // Saves campaigns
        OCMExpect([mockPersistence persistCampaigns:[self singleCampaignPayloadWithDate]]);
        [lcCenter handleWebserviceResponsePayload:[self singleCampaignPayload]];

        // Doesn't save campaigns with persist: false
        OCMExpect([mockPersistence persistCampaigns:[self singleCampaignPayloadWithDate]]);
        [lcCenter handleWebserviceResponsePayload:[self singlePersistableCampaignWithTransientPayload]];

        XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for persistence background tasks"];

        dispatch_async(lcCenter.persistenceQueue, ^{
          [expectation fulfill];
        });

        [self waitForExpectations:@[ expectation ] timeout:10];
        OCMVerifyAll(mockPersistence);
    }
}

- (void)testLoadExpiredCampaigns {
    @autoreleasepool {
        BAMutableDateProvider *dateProvider =
            [[BAMutableDateProvider alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970]];
        BALocalCampaignsFilePersistence *campaignPersister = [BALocalCampaignsFilePersistence new];

        [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:campaignPersister];
        BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
        [lcCenter setValue:dateProvider forKey:@"dateProvider"];

        NSMutableDictionary *payload = [[self singleCampaignPayload] mutableCopy];
        [payload setObject:[NSNumber numberWithDouble:[[dateProvider currentDate] timeIntervalSince1970]]
                    forKey:@"cache_date"];

        [campaignPersister persistCampaigns:payload];

        [dateProvider setTime:[[NSDate date] timeIntervalSince1970] + (15 * 86400)];

        [lcCenter loadCampaignCache];

        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

        XCTAssertEqual(0, [[[lcCenter campaignManager] campaignList] count]);
    }
}

- (void)testHandleWebserviceResponsePayload {
    BAMutableDateProvider *dateProvider =
        [[BAMutableDateProvider alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970]];
    BALocalCampaignsFilePersistence *campaignPersister = [BALocalCampaignsFilePersistence new];

    [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:campaignPersister];
    BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
    [lcCenter setValue:dateProvider forKey:@"dateProvider"];

    NSMutableDictionary *payload = [[self singleCampaignPayload] mutableCopy];
    [lcCenter handleWebserviceResponsePayload:payload];

    XCTAssertFalse([[lcCenter campaignManager] isJITServiceAvailable]);
}

- (void)testHandleWebserviceResponsePayloadWithCampaignsVersionMEP {
    BAMutableDateProvider *dateProvider =
        [[BAMutableDateProvider alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970]];
    BALocalCampaignsFilePersistence *campaignPersister = [BALocalCampaignsFilePersistence new];

    [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:campaignPersister];
    BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
    [lcCenter setValue:dateProvider forKey:@"dateProvider"];

    NSMutableDictionary *payload = [[self singleCampaignPayload] mutableCopy];
    [lcCenter handleWebserviceResponsePayload:payload];

    XCTAssertEqual(BALocalCampaignsVersionMEP, [[lcCenter campaignManager] version]);
}

- (void)testHandleWebserviceResponsePayloadWithCampaingsVersionCEP {
    BAMutableDateProvider *dateProvider =
        [[BAMutableDateProvider alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970]];
    BALocalCampaignsFilePersistence *campaignPersister = [BALocalCampaignsFilePersistence new];

    [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:campaignPersister];
    BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
    [lcCenter setValue:dateProvider forKey:@"dateProvider"];

    NSMutableDictionary *payload = [[self singleCampaignPayloadCEP] mutableCopy];
    [lcCenter handleWebserviceResponsePayload:payload];

    XCTAssertEqual(BALocalCampaignsVersionCEP, [[lcCenter campaignManager] version]);
}

- (void)testHandleWebserviceResponsePayloadWithDelay {
    BAMutableDateProvider *dateProvider =
        [[BAMutableDateProvider alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970]];
    BALocalCampaignsFilePersistence *campaignPersister = [BALocalCampaignsFilePersistence new];

    [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:campaignPersister];
    BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
    [lcCenter setValue:dateProvider forKey:@"dateProvider"];

    NSMutableDictionary *payload = [[self singleCampaignPayloadDelay] mutableCopy];
    [lcCenter handleWebserviceResponsePayload:payload];

    BALocalCampaign *campaign = [[[lcCenter campaignManager] campaignList] firstObject];

    XCTAssertNotNil(campaign);
    XCTAssertEqual(campaign.displayDelaySec, 45);
}

- (void)testHandleWebserviceResponsePayloadMissingVersion {
    BAMutableDateProvider *dateProvider =
        [[BAMutableDateProvider alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970]];
    BALocalCampaignsFilePersistence *campaignPersister = [BALocalCampaignsFilePersistence new];

    [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:campaignPersister];
    BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
    [lcCenter setValue:dateProvider forKey:@"dateProvider"];

    NSMutableDictionary *payload = [[self singleCampaignPayloadMissingVersion] mutableCopy];
    [lcCenter handleWebserviceResponsePayload:payload];

    XCTAssertEqual([[lcCenter campaignManager] version], BALocalCampaignsVersionUnknown);
}

- (void)testHandleWebserviceResponsePayloadUnknownVersionn {
    BAMutableDateProvider *dateProvider =
        [[BAMutableDateProvider alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970]];
    BALocalCampaignsFilePersistence *campaignPersister = [BALocalCampaignsFilePersistence new];

    [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:campaignPersister];
    BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
    [lcCenter setValue:dateProvider forKey:@"dateProvider"];

    NSMutableDictionary *payload = [[self singleCampaignPayloadUnknownVersion] mutableCopy];
    [lcCenter handleWebserviceResponsePayload:payload];

    XCTAssertEqual([[lcCenter campaignManager] version], BALocalCampaignsVersionUnknown);
}

- (void)testHandleWebserviceResponsePayloadWithQuietHours {
    BAMutableDateProvider *dateProvider =
        [[BAMutableDateProvider alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970]];
    BALocalCampaignsFilePersistence *campaignPersister = [BALocalCampaignsFilePersistence new];

    [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:campaignPersister];
    BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
    [lcCenter setValue:dateProvider forKey:@"dateProvider"];

    NSMutableDictionary *payload = [[self singleCampaignPayloadQuietHours] mutableCopy];
    [lcCenter handleWebserviceResponsePayload:payload];

    BALocalCampaign *campaign = [[[lcCenter campaignManager] campaignList] firstObject];

    XCTAssertNotNil(campaign);
    XCTAssertEqual(campaign.quietHours.startHour, 10);
    XCTAssertEqual(campaign.quietHours.startMin, 15);
    XCTAssertEqual(campaign.quietHours.endHour, 18);
    XCTAssertEqual(campaign.quietHours.endMin, 0);
    NSArray<NSNumber *> *expected = [[NSArray alloc] initWithObjects:@0, @1, @2, @3, @4, @5, @6, nil];
    XCTAssertTrue([campaign.quietHours.quietDaysOfWeek isEqual:expected]);
}

- (NSDictionary *)invalidCampaignsTypePayload {
    return @{@"campaigns_version" : @"MEP", @"campaigns" : @{}};
}

- (NSDictionary *)emptyWithUnknownKeyPayload {
    return @{@"invalid" : @(1), @"campaigns" : @[], @"campaigns_version" : @"MEP"};
}

- (NSDictionary *)emptyPayload {
    return @{@"campaigns_version" : @"MEP", @"campaigns" : @[]};
}

- (NSDictionary *)emptyPayloadWithDate {
    return @{
        @"campaigns_version" : @"MEP",
        @"campaigns" : @[],
        @"cache_date" : @1000,
    };
}

- (NSDictionary *)singleCampaignPayload {
    return @{
        @"campaigns_version" : @"MEP",
        @"campaigns" : @[ @{
            @"campaignId" : @"25876676",
            @"campaignToken" : @"ffed98550583631424ab69225b4f74aa",
            @"minimumApiLevel" : @(1),
            @"priority" : @(1),
            @"minDisplayInterval" : @(0),
            @"startDate" : @{@"ts" : @(1672603200000), @"userTZ" : @(false)},
            @"triggers" : @[ @{@"type" : @"EVENT", @"event" : @"_DUMMY_EVENT"} ],
            @"persist" : @(true),
            @"eventData" : @{},
            @"output" : @{
                @"type" : @"LANDING",
                @"payload" : @{@"id" : @"25876676", @"did" : [NSNull null], @"ed" : @{}, @"kind" : @"_dummy"}
            }
        } ]
    };
}

- (NSDictionary *)singleCampaignPayloadCEP {
    return @{
        @"campaigns_version" : @"CEP",
        @"campaigns" : @[ @{
            @"campaignId" : @"25876676",
            @"campaignToken" : @"ffed98550583631424ab69225b4f74aa",
            @"minimumApiLevel" : @(1),
            @"priority" : @(1),
            @"minDisplayInterval" : @(0),
            @"startDate" : @{@"ts" : @(1672603200000), @"userTZ" : @(false)},
            @"triggers" : @[ @{@"type" : @"EVENT", @"event" : @"_DUMMY_EVENT"} ],
            @"persist" : @(false),
            @"eventData" : @{},
            @"output" : @{
                @"type" : @"LANDING",
                @"payload" : @{@"id" : @"25876676", @"did" : [NSNull null], @"ed" : @{}, @"kind" : @"_dummy"}
            }
        } ]
    };
}

- (NSDictionary *)singleCampaignPayloadMissingVersion {
    return @{
        @"campaigns" : @[ @{
            @"campaignId" : @"25876676",
            @"campaignToken" : @"ffed98550583631424ab69225b4f74aa",
            @"minimumApiLevel" : @(1),
            @"priority" : @(1),
            @"minDisplayInterval" : @(0),
            @"startDate" : @{@"ts" : @(1672603200000), @"userTZ" : @(false)},
            @"triggers" : @[ @{@"type" : @"EVENT", @"event" : @"_DUMMY_EVENT"} ],
            @"persist" : @(false),
            @"eventData" : @{},
            @"output" : @{
                @"type" : @"LANDING",
                @"payload" : @{@"id" : @"25876676", @"did" : [NSNull null], @"ed" : @{}, @"kind" : @"_dummy"}
            }
        } ]
    };
}

- (NSDictionary *)singleCampaignPayloadUnknownVersion {
    return @{
        @"campaigns_version" : @"CEPPPP",
        @"campaigns" : @[ @{
            @"campaignId" : @"25876676",
            @"campaignToken" : @"ffed98550583631424ab69225b4f74aa",
            @"minimumApiLevel" : @(1),
            @"priority" : @(1),
            @"minDisplayInterval" : @(0),
            @"startDate" : @{@"ts" : @(1672603200000), @"userTZ" : @(false)},
            @"triggers" : @[ @{@"type" : @"EVENT", @"event" : @"_DUMMY_EVENT"} ],
            @"persist" : @(false),
            @"eventData" : @{},
            @"output" : @{
                @"type" : @"LANDING",
                @"payload" : @{@"id" : @"25876676", @"did" : [NSNull null], @"ed" : @{}, @"kind" : @"_dummy"}
            }
        } ]
    };
}

- (NSDictionary *)singleCampaignPayloadDelay {
    return @{
        @"campaigns_version" : @"CEP",
        @"campaigns" : @[ @{
            @"campaignId" : @"25876676",
            @"campaignToken" : @"ffed98550583631424ab69225b4f74aa",
            @"minimumApiLevel" : @(1),
            @"priority" : @(1),
            @"minDisplayInterval" : @(0),
            @"startDate" : @{@"ts" : @(1672603200000), @"userTZ" : @(false)},
            @"triggers" : @[ @{@"type" : @"EVENT", @"event" : @"_DUMMY_EVENT"} ],
            @"persist" : @(false),
            @"displayDelaySec" : @(45),
            @"eventData" : @{},
            @"output" : @{
                @"type" : @"LANDING",
                @"payload" : @{@"id" : @"25876676", @"did" : [NSNull null], @"ed" : @{}, @"kind" : @"_dummy"}
            }
        } ]
    };
}

- (NSDictionary *)singleCampaignPayloadQuietHours {
    return @{
        @"campaigns_version" : @"CEP",
        @"campaigns" : @[ @{
            @"campaignId" : @"25876676",
            @"campaignToken" : @"ffed98550583631424ab69225b4f74aa",
            @"minimumApiLevel" : @(1),
            @"priority" : @(1),
            @"minDisplayInterval" : @(0),
            @"startDate" : @{@"ts" : @(1672603200000), @"userTZ" : @(false)},
            @"triggers" : @[ @{@"type" : @"EVENT", @"event" : @"_DUMMY_EVENT"} ],
            @"persist" : @(false),
            @"eventData" : @{},
            @"quietHours" : @{
                @"startHour" : @10,
                @"startMin" : @15,
                @"endHour" : @18,
                @"endMin" : @0,
                @"quietDaysOfWeek" : @[ @0, @1, @2, @3, @4, @5, @6 ]
            },
            @"output" : @{
                @"type" : @"LANDING",
                @"payload" : @{@"id" : @"25876676", @"did" : [NSNull null], @"ed" : @{}, @"kind" : @"_dummy"}
            }
        } ]
    };
}

- (NSDictionary *)singleCampaignPayloadWithDate {
    return @{
        @"campaigns_version" : @"MEP",
        @"campaigns" : @[ @{
            @"campaignId" : @"25876676",
            @"campaignToken" : @"ffed98550583631424ab69225b4f74aa",
            @"minimumApiLevel" : @(1),
            @"priority" : @(1),
            @"minDisplayInterval" : @(0),
            @"startDate" : @{@"ts" : @(1672603200000), @"userTZ" : @(false)},
            @"triggers" : @[ @{@"type" : @"EVENT", @"event" : @"_DUMMY_EVENT"} ],
            @"persist" : @(true),
            @"eventData" : @{},
            @"output" : @{
                @"type" : @"LANDING",
                @"payload" : @{@"id" : @"25876676", @"did" : [NSNull null], @"ed" : @{}, @"kind" : @"_dummy"}
            }
        } ],
        @"cache_date" : @1000
    };
}

- (NSDictionary *)singlePersistableCampaignWithTransientPayload {
    return @{
        @"campaigns_version" : @"MEP",
        @"campaigns" : @[
            @{
                @"campaignId" : @"25876676",
                @"campaignToken" : @"ffed98550583631424ab69225b4f74aa",
                @"minimumApiLevel" : @(1),
                @"priority" : @(1),
                @"minDisplayInterval" : @(0),
                @"startDate" : @{@"ts" : @(1672603200000), @"userTZ" : @(false)},
                @"triggers" : @[ @{@"type" : @"EVENT", @"event" : @"_DUMMY_EVENT"} ],
                @"persist" : @(true),
                @"eventData" : @{},
                @"output" : @{
                    @"type" : @"LANDING",
                    @"payload" : @{@"id" : @"25876676", @"did" : [NSNull null], @"ed" : @{}, @"kind" : @"_dummy"}
                }
            },
            @{
                @"campaignId" : @"123",
                @"campaignToken" : @"ffccddee",
                @"minimumApiLevel" : @(1),
                @"priority" : @(1),
                @"minDisplayInterval" : @(0),
                @"startDate" : @{@"ts" : @(1672603200000), @"userTZ" : @(false)},
                @"triggers" : @[ @{@"type" : @"EVENT", @"event" : @"_DUMMY_EVENT"} ],
                @"persist" : @(false),
                @"eventData" : @{},
                @"output" : @{
                    @"type" : @"LANDING",
                    @"payload" : @{@"id" : @"25876676", @"did" : [NSNull null], @"ed" : @{}, @"kind" : @"_dummy"}
                }
            }
        ]
    };
}

@end
