//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Testing

@testable import Batch

struct InAppDividerViewTests {
    static let height: Int = 4
    static let color: UIColor = .red
    static let heightType: InAppHeightType = .fixed(value: height)

    @MainActor
    @Test func testConfiguration() async throws {
        let dividerView = InAppDividerView(
            configuration: InAppDividerView.Configuration(
                style: InAppDividerView.Configuration.Style(
                    color: Self.color
                ),
                placement: InAppDividerView.Configuration.Placement(
                    margins: .zero,
                    widthType: nil,
                    heightType: Self.heightType,
                    horizontalAlignment: nil
                )
            )
        )

        dividerView.configure()
        dividerView.layoutSubviews()

        #expect(dividerView.layer.cornerRadius == (CGFloat(Self.height) / 2))
        #expect(dividerView.backgroundColor == Self.color)
    }
}
