//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Testing

@testable import Batch

struct InAppLabelViewTests {
    let text = "Je suis un label"
    let fontSize: Int = 18
    let maxLines: Int = 2
    let textAlign: InAppHorizontalAlignment = .left
    let textColor: UIColor = .blue

    let margins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
    let analyticsIdentifier = "analyticsIdentifier_image"

    let fontDecoration: [InAppFontDecoration] = [.bold, .italic]

    @MainActor
    @Test func testConfiguration() async throws {
        let labelView = InAppLabelView(
            configuration: InAppLabelView.Configuration(
                content: InAppLabelView.Configuration.Content(
                    text: text
                ),
                fontStyle: InAppLabelView.Configuration.FontStyle(
                    fontSize: fontSize,
                    fontDecoration: fontDecoration
                ),
                style: InAppLabelView.Configuration.Style(
                    textAlign: textAlign,
                    color: textColor,
                    maxLines: maxLines
                ),
                placement: InAppLabelView.Configuration.Placement(
                    margins: margins
                )
            )
        )

        labelView.configure()

        labelView.drawText(in: .infinite)

        // Content
        let decoratedText = InAppFontStyleBuilder.addDecoration(to: text, fontDecorationStyle: labelView.configuration.fontStyle)
        #expect(decoratedText == "<i><b>\(text)</b></i>")
        #expect(labelView.attributedText?.string == text)

        // Accessibility
        #expect(labelView.accessibilityLabel == text)

        // Style
        #expect(labelView.textColor == textColor)
        #expect(labelView.textAlignment == .left)
    }
}
