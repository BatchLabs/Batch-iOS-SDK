//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Testing

@testable import Batch

struct InAppSpacerViewTests {
    static let heightType: InAppHeightType = .fill

    @MainActor
    @Test func testConfiguration() async throws {
        let spacerView = InAppSpacerView(
            configuration: InAppSpacerView.Configuration(
                placement: InAppSpacerView.Configuration.Placement(heightType: Self.heightType)
            )
        )

        #expect(spacerView.configuration.placement.isExpandable == true)
        #expect(spacerView.configuration.placement is InAppExpandableView)
        #expect(spacerView.configuration.placement.verticalAlignment == .top)
    }
}
