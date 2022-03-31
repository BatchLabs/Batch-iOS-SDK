//
//  localCampaignsParserTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation
import Batch.Batch_Private
import XCTest

fileprivate struct TestResponses {
    static let empty: [AnyHashable: Any] = [
        "campaigns": []
    ]
    
    static let cappingPayload: [AnyHashable: Any] = [
        "cappings": [
            "session": 2,
            "time": [
                ["views": 1, "duration": 3600],
                ["views": 0, "duration": 3600],
                ["views": 1, "duration": 0]
            ]
        ],
    ]
}

class localCampaignsParserTests: XCTestCase {
    func testParserPersistence() {
        // Test that the parser returns a non nil outPersist when no campaigns are to
        // be persisted
        var outPersistable: NSDictionary? = nil
        let campaigns = try! BALocalCampaignsParser.parseCampaigns(TestResponses.empty, outPersistable: &outPersistable)
        XCTAssertEqual(0, campaigns.count)
        XCTAssertNotNil(outPersistable)
        let persistedCampaigns = outPersistable?["campaigns"] as! NSArray
        XCTAssertEqual(0, persistedCampaigns.count)
    }
    
    func testParseCappings() {
        var outPersistable: NSDictionary? = nil
        let cappings = BALocalCampaignsParser.parseCappings(TestResponses.cappingPayload, outPersistable: &outPersistable)
        XCTAssertNotNil(cappings)
        XCTAssertEqual(2, cappings?.session)
        XCTAssertEqual(1, cappings?.timeBasedCappings?.count)
        XCTAssertNotNil(outPersistable)
        XCTAssertNotNil(outPersistable?["cappings"])

    }
}
