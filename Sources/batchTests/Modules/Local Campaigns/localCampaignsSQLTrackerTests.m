//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BALocalCampaignsSQLTracker.h"

@interface localCampaignsSQLTrackerTests : XCTestCase {
    BALocalCampaignsSQLTracker *_datasource;
}
@end

@implementation localCampaignsSQLTrackerTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _datasource = [[BALocalCampaignsSQLTracker alloc] init];
    XCTAssertNotNil(_datasource, "Could not instanciate datasource");
    [_datasource clear];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [_datasource clear];
    [_datasource close];
}

- (void)testNumberOfViewEventsSince {
    NSNumber *count = [_datasource numberOfViewEventsSince:[[NSDate date] timeIntervalSince1970] - 60];
    XCTAssertEqual(0, [count intValue]);

    // Track view event
    [_datasource trackEventForCampaignID:@"campaign_id" kind:BALocalCampaignTrackerEventKindView];

    double timestamp = [[NSDate date] timeIntervalSince1970];
    count = [_datasource numberOfViewEventsSince:timestamp - 1];

    // A tracked view event since 1s
    XCTAssertEqual(1, [count intValue]);

    // Adding 1 second
    timestamp += 1;
    count = [_datasource numberOfViewEventsSince:timestamp - 1];

    // 0 tracked view event since 1 sec
    XCTAssertEqual(0, [count intValue]);
}

@end
