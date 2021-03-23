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
}
