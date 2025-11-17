//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Testing

@testable import Batch

struct InAppWidthTypeTests {
    @Test func testInAppWidthTypeAuto() async throws {
        let stringValue = "auto"
        let widthType = InAppWidthType(stringValue: stringValue)
        #expect(widthType == .auto)
    }

    @Test func testInAppWidthTypePx() async throws {
        let value: Int = 200
        let stringValue = "\(value)%"
        let widthType = InAppWidthType(stringValue: stringValue)
        #expect(widthType == .percent(value: value))
    }

    @Test func testInAppWidthTypeNil() async throws {
        let value: Int = 200
        let stringValue = "\(value)%%%"
        let widthType = InAppWidthType(stringValue: stringValue)
        #expect(widthType == nil)
    }
}
