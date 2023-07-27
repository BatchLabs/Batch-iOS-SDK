//
//  cssTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import XCTest

class cssTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEnvironment() {
        let env = BACSSEnvironment()

        XCTAssertTrue(env.environmentMatchesQuery("@ios"))
        XCTAssertFalse(env.environmentMatchesQuery("@android"))

        // Test dark mode
        env.darkMode = false

        XCTAssertTrue(env.environmentMatchesQuery("@ios and light"))
        XCTAssertFalse(env.environmentMatchesQuery("@android and light"))
        XCTAssertFalse(env.environmentMatchesQuery("@ios and dark"))

        env.darkMode = true

        XCTAssertFalse(env.environmentMatchesQuery("@ios and light"))
        XCTAssertFalse(env.environmentMatchesQuery("@android and dark"))
        XCTAssertTrue(env.environmentMatchesQuery("@ios and dark"))

        // Test size
        env.viewSize = CGSize(width: 800, height: 600)
        XCTAssertTrue(env.environmentMatchesQuery("@media ios and (min-width:800)"))
        XCTAssertTrue(env.environmentMatchesQuery("@media ios and (min-width:799)"))
        XCTAssertFalse(env.environmentMatchesQuery("@media android and (min-width:800)"))
        XCTAssertFalse(env.environmentMatchesQuery("@media ios and (min-width:801)"))

        XCTAssertTrue(env.environmentMatchesQuery("@media ios and (min-height:600)"))
        XCTAssertTrue(env.environmentMatchesQuery("@media ios and (min-height:599)"))
        XCTAssertFalse(env.environmentMatchesQuery("@media android and (min-height:600)"))
        XCTAssertFalse(env.environmentMatchesQuery("@media ios and (min-height:601)"))

        XCTAssertTrue(env.environmentMatchesQuery("@media ios and (max-width:800)"))
        XCTAssertTrue(env.environmentMatchesQuery("@media ios and (max-width:801)"))
        XCTAssertFalse(env.environmentMatchesQuery("@media android and (max-width:800)"))
        XCTAssertFalse(env.environmentMatchesQuery("@media ios and (max-width:799)"))

        XCTAssertTrue(env.environmentMatchesQuery("@media ios and (max-height:600)"))
        XCTAssertTrue(env.environmentMatchesQuery("@media ios and (max-height:601)"))
        XCTAssertFalse(env.environmentMatchesQuery("@media android and (max-height:600)"))
        XCTAssertFalse(env.environmentMatchesQuery("@media ios and (max-height:599)"))
    }
}
