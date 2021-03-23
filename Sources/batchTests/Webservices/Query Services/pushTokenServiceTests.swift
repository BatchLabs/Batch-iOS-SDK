//
//  pushTokenServiceTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation
import XCTest
import Batch.Batch_Private

private let expectedToken = "test_token"

class pushTokenServiceTests: XCTestCase {

    func testIdentifier() {
        XCTAssertEqual(makeService().requestIdentifier, "push")
    }

    func testShortIdentifier() {
        XCTAssertEqual(makeService().requestShortIdentifier, "t")
    }
    
    func makeService() -> BAPushTokenServiceDatasource {
        return BAPushTokenServiceDatasource(token: expectedToken, usesProductionEnvironment: false)
    }
}
