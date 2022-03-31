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

@interface BALocalCampaignsCenter(Tests)
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
        [lcCenter handleWebserviceResponsePayload:@{@"error": @{@"code": @(2), @"reason": @"internal error"}}];
        
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
        
        [self waitForExpectations:@[expectation] timeout:10];
        OCMVerifyAll(mockPersistence);
    }
}

- (void)testLoadExpiredCampaigns {
    @autoreleasepool {
        BAMutableDateProvider *dateProvider = [[BAMutableDateProvider alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970]];
        BALocalCampaignsFilePersistence *campaignPersister = [BALocalCampaignsFilePersistence new];
        
        [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:campaignPersister];
        BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
        [lcCenter setValue:dateProvider forKey:@"dateProvider"];
        
        NSMutableDictionary *payload = [[self singleCampaignPayload] mutableCopy];
        [payload setObject:[NSNumber numberWithDouble:[[dateProvider currentDate] timeIntervalSince1970]] forKey:@"cache_date"];
        
        [campaignPersister persistCampaigns:payload];
        
        [dateProvider setTime:[[NSDate date] timeIntervalSince1970] + (15 * 86400)];
                
        [lcCenter loadCampaignCache];
        
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

        XCTAssertEqual(0, [[[lcCenter campaignManager] campaignList] count]);
    }
}

- (NSDictionary*)invalidCampaignsTypePayload {
    return @{
        @"campaigns": @{}
    };
}

- (NSDictionary*)emptyWithUnknownKeyPayload {
    return @{
        @"invalid": @(1),
        @"campaigns": @[]
    };
}

- (NSDictionary*)emptyPayload {
    return @{
        @"campaigns": @[]
    };
}

- (NSDictionary*)emptyPayloadWithDate {
    return @{
        @"campaigns": @[],
        @"cache_date": @1000,
    };
}

- (NSDictionary*)singleCampaignPayload {
    return @{
        @"campaigns": @[
            @{
               @"campaignId": @"25876676",
               @"campaignToken": @"ffed98550583631424ab69225b4f74aa",
               @"minimumApiLevel": @(1),
               @"priority": @(1) ,
               @"minDisplayInterval": @(0),
               @"startDate": @{ @"ts": @(1672603200000), @"userTZ": @(false)},
               @"triggers": @[@{ @"type": @"EVENT", @"event": @"_DUMMY_EVENT" }],
               @"persist": @(true),
               @"eventData": @{},
               @"output": @{
                   @"type": @"LANDING",
                   @"payload": @{ @"id": @"25876676", @"did": [NSNull null], @"ed": @{}, @"kind": @"_dummy" }
               }
            }
        ]
    };
}

- (NSDictionary*)singleCampaignPayloadWithDate {
    return @{
        @"campaigns": @[
            @{
               @"campaignId": @"25876676",
               @"campaignToken": @"ffed98550583631424ab69225b4f74aa",
               @"minimumApiLevel": @(1),
               @"priority": @(1) ,
               @"minDisplayInterval": @(0),
               @"startDate": @{ @"ts": @(1672603200000), @"userTZ": @(false)},
               @"triggers": @[@{ @"type": @"EVENT", @"event": @"_DUMMY_EVENT" }],
               @"persist": @(true),
               @"eventData": @{},
               @"output": @{
                   @"type": @"LANDING",
                   @"payload": @{ @"id": @"25876676", @"did": [NSNull null], @"ed": @{}, @"kind": @"_dummy" }
               }
            }
        ],
        @"cache_date":@1000
    };
}

- (NSDictionary*)singlePersistableCampaignWithTransientPayload {
    return @{
        @"campaigns": @[
            @{
               @"campaignId": @"25876676",
               @"campaignToken": @"ffed98550583631424ab69225b4f74aa",
               @"minimumApiLevel": @(1),
               @"priority": @(1) ,
               @"minDisplayInterval": @(0),
               @"startDate": @{ @"ts": @(1672603200000), @"userTZ": @(false)},
               @"triggers": @[@{ @"type": @"EVENT", @"event": @"_DUMMY_EVENT" }],
               @"persist": @(true),
               @"eventData": @{},
               @"output": @{
                   @"type": @"LANDING",
                   @"payload": @{ @"id": @"25876676", @"did": [NSNull null], @"ed": @{}, @"kind": @"_dummy" }
               }
            },
            @{
               @"campaignId": @"123",
               @"campaignToken": @"ffccddee",
               @"minimumApiLevel": @(1),
               @"priority": @(1) ,
               @"minDisplayInterval": @(0),
               @"startDate": @{ @"ts": @(1672603200000), @"userTZ": @(false)},
               @"triggers": @[@{ @"type": @"EVENT", @"event": @"_DUMMY_EVENT" }],
               @"persist": @(false),
               @"eventData": @{},
               @"output": @{
                   @"type": @"LANDING",
                   @"payload": @{ @"id": @"25876676", @"did": [NSNull null], @"ed": @{}, @"kind": @"_dummy" }
               }
            }
        ]
    };
}

@end
