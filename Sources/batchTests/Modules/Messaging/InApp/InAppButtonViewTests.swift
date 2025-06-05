//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Testing

struct InAppButtonViewTests {
    let text = "Je suis un button"
    let fontSize: Int = 18
    let maxLines: Int = 2
    let textAlign: InAppHorizontalAlignment = .left
    let textColor: UIColor = .blue

    let margins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
    let paddings = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
    static let heightValue: CGFloat = 200
    let height = "\(heightValue)px"

    let radius = [4, 4, 4, 4]
    let analyticsIdentifier = "analyticsIdentifier_image"

    var action: BAMSGAction = {
        let action = BAMSGAction()
        action.actionIdentifier = "batch.dismiss"
        return action
    }()

    let fontDecoration: [InAppFontDecoration] = [.bold, .italic]

    let backgroundColor: UIColor = .red

    let borderWidth: Int = 2
    let borderColor: UIColor = .yellow

    @MainActor
    @Test func testConfiguration() async throws {
        await confirmation("Should pass through `onClosureTap`") { @MainActor confirm in
            let buttonView = InAppButtonView(
                configuration: InAppButtonView.Configuration(
                    content: InAppButtonView.Configuration.Content(
                        text: text
                    ),
                    fontStyle: InAppButtonView.Configuration.FontStyle(
                        fontSize: fontSize,
                        fontDecoration: fontDecoration
                    ),
                    style: InAppButtonView.Configuration.Style(
                        backgroundColor: backgroundColor,
                        radius: radius,
                        borderWidth: borderWidth,
                        borderColor: borderColor,
                        textAlign: textAlign,
                        textColor: textColor,
                        maxLines: maxLines
                    ),
                    placement: InAppButtonView.Configuration.Placement(
                        margins: margins,
                        widthType: .auto,
                        paddings: paddings,
                        horizontalAlignment: textAlign
                    ),
                    action: InAppButtonView.Configuration.Action(
                        analyticsIdentifier: analyticsIdentifier,
                        action: action
                    )
                ),
                onClosureTap: { component, _ in
                    #expect(component?.type == .button)
                    #expect(component?.analyticsIdentifier == analyticsIdentifier)
                    #expect(component?.action?.actionIdentifier == action.actionIdentifier)
                    confirm()
                }
            )

            buttonView.draw(.infinite)

            // Content
            let decoratedText = InAppFontStyleBuilder.addDecoration(to: text, fontDecorationStyle: buttonView.baConfiguration.fontStyle)
            #expect(decoratedText == "<i><b>\(text)</b></i>")
            #expect(buttonView.attributedTitle(for: .normal)?.string == text)

            // Accessibility
            #expect(buttonView.accessibilityLabel == text)

            // Placement
            #expect(buttonView.titleEdgeInsets == paddings)
            #expect(buttonView.contentEdgeInsets == .zero)

            // Style
            let path = buttonView.baConfiguration.style.layoutRoundedCorners(on: buttonView)
            buttonView.baConfiguration.style.layoutBorders(on: buttonView, with: path)

            #expect((buttonView.layer.mask as? CAShapeLayer)?.path == path)
            let shapeLayer = buttonView.layer.sublayers?.first(where: { $0 is CAShapeLayer }) as? CAShapeLayer
            #expect(shapeLayer?.fillColor == UIColor.clear.cgColor)
            #expect(shapeLayer?.strokeColor == borderColor.cgColor)
            #expect(shapeLayer?.lineWidth == CGFloat(borderWidth))

            #expect(buttonView.backgroundColor == backgroundColor)
            #expect(buttonView.titleLabel?.textColor == textColor)
            #expect(buttonView.titleLabel?.numberOfLines == maxLines)
            #expect(buttonView.titleLabel?.textAlignment == .left)

            // Tap
            buttonView.onTap()
        }
    }
}
