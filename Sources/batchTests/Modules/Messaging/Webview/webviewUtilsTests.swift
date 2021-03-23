//
//  webviewUtilsTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import XCTest
import Batch.Batch_Private

class webviewUtilsTests: XCTestCase {
    func testAnalyticsIDExtraction() {
        XCTAssertEqual(nil, BATWebviewUtils.analyticsId(forURL: ""))
        XCTAssertEqual(nil, BATWebviewUtils.analyticsId(forURL: "https://batch.com"))
        XCTAssertEqual(nil, BATWebviewUtils.analyticsId(forURL: "https://batch.com/batchAnalyticsID=foo"))
        XCTAssertEqual(nil, BATWebviewUtils.analyticsId(forURL: "https://batch.com/?batchAnalyticsid=foo"))
        XCTAssertEqual("foo", BATWebviewUtils.analyticsId(forURL: "https://batch.com/?batchAnalyticsID=foo"))
        XCTAssertEqual("foo", BATWebviewUtils.analyticsId(forURL: "https://batch.com/index.html?batchAnalyticsID=foo"))
        XCTAssertEqual("foo", BATWebviewUtils.analyticsId(forURL: "https://batch.com/?test=test&batchAnalyticsID=foo"))
        XCTAssertEqual("space example", BATWebviewUtils.analyticsId(forURL: "https://batch.com/?batchAnalyticsID=space%20example"))
    }
}
