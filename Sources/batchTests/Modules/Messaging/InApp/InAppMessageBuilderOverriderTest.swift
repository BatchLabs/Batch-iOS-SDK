//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Testing

struct InAppMessageBuilderOverriderTest {
    @Test func overrideValues() async throws {
        #expect(InAppMessageBuilderOverrider.values(format: .fullscreen, values: 2) == nil)
    }

    @Test func keepValues() async throws {
        #expect(InAppMessageBuilderOverrider.values(format: .modal, values: 2) == 2)
    }
}
