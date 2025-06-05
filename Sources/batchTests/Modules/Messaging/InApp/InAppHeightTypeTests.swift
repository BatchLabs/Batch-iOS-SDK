//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Testing

struct InAppHeightTypeTests {
    @Test func testInAppHeightTypeAuto() async throws {
        let stringValue = "auto"
        let heightType = InAppHeightType(stringValue: stringValue)
        #expect(heightType == .auto)
    }

    @Test func testInAppHeightTypePx() async throws {
        let value: Int = 200
        let stringValue = "\(value)px"
        let heightType = InAppHeightType(stringValue: stringValue)
        #expect(heightType == .fixed(value: value))
    }

    @Test func testInAppHeightTypeNil() async throws {
        let value: Int = 200
        let stringValue = "\(value)pxxxx"
        let heightType = InAppHeightType(stringValue: stringValue)
        #expect(heightType == nil)
    }
}
