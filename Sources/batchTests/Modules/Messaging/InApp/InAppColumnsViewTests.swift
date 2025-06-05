//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Testing

struct InAppColumnsViewTests {
    // Columns
    static let spacing: Int = 2
    static let verticalAlignment: InAppVerticalAlignment = .top
    static let margins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
    static let ratios = [25, 25, 25, 25]

    // Common
    static let action: InAppAction = InAppAction(action: "batch.dismiss")

    // Image

    static let imageId: String = UUID().uuidString
    static let imageURL = "https://static.batch.com/sample/1.jpeg"
    static let aspect = InAppAspectRatio.fit
    static let heightValue: CGFloat = 200
    static let height = "\(heightValue)px"
    static let radius = [4, 4, 4, 4]
    static let margin = [4, 4, 4, 4]
    static let padding = [4, 4, 4, 4]
    static let contentDescription = "image"

    // Texts

    static let titleId: String = UUID().uuidString
    static let title: String = "Je suis un titre"

    static let button1Id: String = UUID().uuidString
    static let button1: String = "Je suis le premier boutton"

    static let button2Id: String = UUID().uuidString
    static let button2: String = "Je suis le second boutton"

    static let fontSize: Int = 18
    static let maxLines: Int = 2
    static let textAlign: InAppHorizontalAlignment = .left
    static let textColor: UIColor = .blue
    static let fontDecoration: [InAppFontDecoration] = [.bold, .italic]

    // Buttons
    static let borderWidth: Int = 2

    static let componentsTypes: [InAppAnyTypedComponent?] = [
        InAppAnyTypedComponent(InAppImage(id: imageId, aspect: aspect, margin: margin, height: height, radius: radius)),
        InAppAnyTypedComponent(InAppLabel(id: titleId, margin: margin, textAlign: textAlign, fontSize: fontSize, color: ["#000000FF", "#FFFFFFFF"], maxLines: maxLines, fontDecoration: fontDecoration)),
        InAppAnyTypedComponent(InAppButton(
            id: button1Id,
            margin: margin,
            padding: padding,
            width: "auto",
            align: textAlign,
            backgroundColor: ["#FFFFFFFF", "#000000FF"],
            radius: radius,
            borderWidth: borderWidth,
            borderColor: ["#FFFFFFFF", "#000000FF"],
            fontSize: fontSize,
            textAlign: textAlign,
            textColor: ["#000000FF", "#FFFFFFFF"],
            maxLines: maxLines,
            fontDecoration: fontDecoration
        )),
        InAppAnyTypedComponent(InAppButton(
            id: button2Id,
            margin: margin,
            padding: padding,
            width: "auto",
            align: textAlign,
            backgroundColor: ["#FFFFFFFF", "#000000FF"],
            radius: radius,
            borderWidth: borderWidth,
            borderColor: ["#FFFFFFFF", "#000000FF"],
            fontSize: fontSize,
            textAlign: textAlign,
            textColor: ["#000000FF", "#FFFFFFFF"],
            maxLines: maxLines,
            fontDecoration: fontDecoration
        )),
    ]

    @MainActor
    @Test func testConfiguration() async throws {
        await confirmation("Should pass through `onClosureTap`") { @MainActor confirm in
            let columnsView = InAppColumnsView(
                configuration: InAppColumnsView.Configuration(
                    builders: InAppAnyObjectTypeBuilder.build(
                        urls: [Self.imageId: Self.imageURL],
                        texts: [Self.titleId: Self.title, Self.button1Id: Self.button1, Self.button2Id: Self.button2],
                        actions: [Self.imageId: Self.action],
                        componentTypes: Self.componentsTypes
                    ),
                    ratios: Self.ratios,
                    style: InAppColumnsView.Configuration.Style(
                        spacing: Self.spacing,
                        verticalAlignment: Self.verticalAlignment
                    ),
                    placement: InAppColumnsView.Configuration.Placement(margins: Self.margins)
                ),
                onClosureTap: { component, _ in
                    #expect(component?.type == .image)
                    #expect(component?.analyticsIdentifier == Self.imageId)
                    #expect(component?.action?.actionIdentifier == Self.action.action)
                    confirm()
                },
                onError: { _, _ in }
            )

            await InAppWaitingForTests.wait()

            #expect(columnsView.arrangedSubviews.count == 4)
            #expect(columnsView.axis == .horizontal)
            #expect(columnsView.distribution == .fillEqually)
            #expect(columnsView.spacing == CGFloat(Self.spacing))
            #expect(columnsView.alignment == .top)

            #expect((columnsView.arrangedSubviews[0] as? InAppPercentedView)?.percent == CGFloat(Self.ratios[0]))
            #expect((columnsView.arrangedSubviews[1] as? InAppPercentedView)?.percent == CGFloat(Self.ratios[1]))
            #expect((columnsView.arrangedSubviews[2] as? InAppPercentedView)?.percent == CGFloat(Self.ratios[2]))
            #expect((columnsView.arrangedSubviews[3] as? InAppPercentedView)?.percent == CGFloat(Self.ratios[3]))

            #expect(((columnsView.arrangedSubviews[0] as? InAppPercentedView)?.subviews[0] as? InAppContainer)?.subviews[0] is InAppImageView)
            #expect(((columnsView.arrangedSubviews[1] as? InAppPercentedView)?.subviews[0] as? InAppContainer)?.subviews[0] is InAppLabelView)
            #expect(((columnsView.arrangedSubviews[2] as? InAppPercentedView)?.subviews[0] as? InAppContainer)?.subviews[0] is InAppButtonView)
            #expect(((columnsView.arrangedSubviews[3] as? InAppPercentedView)?.subviews[0] as? InAppContainer)?.subviews[0] is InAppButtonView)

            // Tap
            (((columnsView.arrangedSubviews[0] as? InAppPercentedView)?.subviews[0] as? InAppContainer)?.subviews[0] as? InAppImageView)?.handleCTATap()
        }
    }

    @MainActor
    @Test func testDistribution() async throws {
        let columnsView = InAppColumnsView(
            configuration: InAppColumnsView.Configuration(
                builders: InAppAnyObjectTypeBuilder.build(
                    urls: [Self.imageId: Self.imageURL],
                    texts: [Self.titleId: Self.title, Self.button1Id: Self.button1, Self.button2Id: Self.button2],
                    actions: [Self.imageId: Self.action],
                    componentTypes: Self.componentsTypes
                ),
                ratios: [25, 20, 25, 30],
                style: InAppColumnsView.Configuration.Style(
                    spacing: Self.spacing,
                    verticalAlignment: Self.verticalAlignment
                ),
                placement: InAppColumnsView.Configuration.Placement(margins: Self.margins)
            ),
            onClosureTap: { _, _ in
                Issue.record("Should not be called")
            },
            onError: { _, _ in
                Issue.record("Should not be called")
            }
        )

        await InAppWaitingForTests.wait()

        #expect(columnsView.distribution == .fillProportionally)
    }

    @MainActor
    @Test func testFailLoading() async throws {
        // Because of retry expectedCount is 2
        await confirmation("Should pass through `onError`", expectedCount: 2) { @MainActor confirm in
            let columnsView = InAppColumnsView(
                configuration: InAppColumnsView.Configuration(
                    builders: InAppAnyObjectTypeBuilder.build(
                        urls: [Self.imageId: "https://static.batch.com/sample/100.jpeg"],
                        texts: [Self.titleId: Self.title, Self.button1Id: Self.button1, Self.button2Id: Self.button2],
                        actions: [Self.imageId: Self.action],
                        componentTypes: Self.componentsTypes
                    ),
                    ratios: Self.ratios,
                    style: InAppColumnsView.Configuration.Style(
                        spacing: Self.spacing,
                        verticalAlignment: Self.verticalAlignment
                    ),
                    placement: InAppColumnsView.Configuration.Placement(margins: Self.margins)
                ),
                onClosureTap: { _, _ in
                    Issue.record("On error only should be called")
                },
                onError: { _, component in
                    #expect(component == .image)
                    confirm()
                }
            )

            columnsView.configure()

            await InAppWaitingForTests.wait()
        }
    }
}
