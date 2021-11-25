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

@implementation localCampaignsCenterTests

- (void)testPersistence {
    @autoreleasepool {
        id mockPersistence = OCMProtocolMock(@protocol(BALocalCampaignsPersisting));
        [BAInjection overlayProtocol:@protocol(BALocalCampaignsPersisting) returnedInstance:mockPersistence];
        
        BALocalCampaignsCenter *lcCenter = [BALocalCampaignsCenter new];
        
        [mockPersistence setExpectationOrderMatters:YES];
        
        OCMExpect([mockPersistence deleteCampaigns]);
        [lcCenter handleWebserviceResponsePayload:@{@"error": @{@"code": @(2), @"reason": @"internal error"}}];
        
        OCMExpect([mockPersistence deleteCampaigns]);
        [lcCenter handleWebserviceResponsePayload:[self invalidCampaignsTypePayload]];
        
        // Saves an empty campaign list (ch17038)
        OCMExpect([mockPersistence persistCampaigns:[self emptyPayload]]);
        [lcCenter handleWebserviceResponsePayload:[self emptyPayload]];
        
        // Ignores unknown keys
        OCMExpect([mockPersistence persistCampaigns:[self emptyPayload]]);
        [lcCenter handleWebserviceResponsePayload:[self emptyWithUnknownKeyPayload]];
        
        // Saves campaigns
        OCMExpect([mockPersistence persistCampaigns:[self singleCampaignPayload]]);
        [lcCenter handleWebserviceResponsePayload:[self singleCampaignPayload]];
        
        // Doesn't save campaigns with persist: false
        OCMExpect([mockPersistence persistCampaigns:[self singleCampaignPayload]]);
        [lcCenter handleWebserviceResponsePayload:[self singlePersistableCampaignWithTransientPayload]];
        
        XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for persistence background tasks"];
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            [expectation fulfill];
        });
        
        [self waitForExpectations:@[expectation] timeout:10];
        OCMVerifyAll(mockPersistence);
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
