//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import XCTest

@testable import Batch

fileprivate struct TestResponses {
    static let cappingPayload: [AnyHashable: Any] = [
        "cappings": [
            "session": 2,
            "time": [
                ["views": 1, "duration": 3600]
            ],
        ]
    ]
}

class localCampaignsTrackerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSessionTracker() {

        let tracker = BALocalCampaignsTracker()
        XCTAssertEqual(0, tracker.sessionViewsCount)

        tracker.trackEvent(forCampaignID: "campaign_id", kind: BALocalCampaignTrackerEventKind.view)
        XCTAssertEqual(1, tracker.sessionViewsCount)

        tracker.resetSessionViewsCount()
        XCTAssertEqual(0, tracker.sessionViewsCount)
    }

    func testIsOverGlobalCappings() {
        //Cappings: (2/session & 1/h)
        let dateProvider = BAMutableDateProvider(timestamp: Date().timeIntervalSince1970)
        let viewTracker = BALocalCampaignsTracker()
        viewTracker.clear()
        let campaignManager = BALocalCampaignsManager(dateProvider: dateProvider, viewTracker: viewTracker)

        let cappings = BALocalCampaignsParser.parseCappings(TestResponses.cappingPayload, outPersistable: nil)
        campaignManager.cappings = cappings
        XCTAssertFalse(campaignManager.isOverGlobalCappings())

        // Tracking event
        viewTracker.trackEvent(forCampaignID: "campaign_id", kind: BALocalCampaignTrackerEventKind.view)

        // Time-based cappings reached
        XCTAssertTrue(campaignManager.isOverGlobalCappings())

        // Adding 1h
        dateProvider.setTime(Date().timeIntervalSince1970 + 3600)

        // Time-based cappings released
        XCTAssertFalse(campaignManager.isOverGlobalCappings())

        // Tracking another event
        viewTracker.trackEvent(forCampaignID: "campaign_id", kind: BALocalCampaignTrackerEventKind.view)

        // Adding 1h
        dateProvider.setTime(Date().timeIntervalSince1970 + 3600)

        // Session capping reached
        XCTAssertTrue(campaignManager.isOverGlobalCappings())

        // Closing db
        viewTracker.clear()
        viewTracker.close()
    }

}
