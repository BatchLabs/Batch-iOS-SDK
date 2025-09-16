//
//  UITestAppTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Testing

@Suite(.serialized, .disabled("Fail randomly on CI, needs more investigation"))
struct InAppImageViewTests {
    let aspect = InAppAspectRatio.fit
    let margins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
    static let heightValue: CGFloat = 200
    let height = "\(heightValue)px"
    let radius = [4, 4, 4, 4]
    let contentDescription = "image"
    let analyticsIdentifier = "analyticsIdentifier_image"
    var action: BAMSGAction = {
        let action = BAMSGAction()
        action.actionIdentifier = "batch.dismiss"
        return action
    }()

    @MainActor
    @Test func testConfiguration() async throws {
        let url = try #require(URL(string: "https://static.batch.com/sample/1.jpeg"))

        await confirmation("Should pass through `onClosureTap`") { @MainActor confirm in
            let imageView = InAppImageView(
                configuration: InAppImageView.Configuration(
                    url: url,
                    style: InAppImageView.Configuration.Style(aspect: aspect, radius: radius),
                    placement: InAppImageView.Configuration.Placement(heightType: InAppHeightType(stringValue: height), margins: margins, estimateHeight: nil, estimateWidth: nil),
                    action: InAppImageView.Configuration.Action(analyticsIdentifier: analyticsIdentifier, action: action),
                    accessibility: InAppImageView.Configuration.Accessibility(label: contentDescription)
                ),
                onClosureTap: { [self] component, _ in
                    #expect(component?.type == .image)
                    #expect(component?.analyticsIdentifier == analyticsIdentifier)
                    #expect(component?.action?.actionIdentifier == action.actionIdentifier)
                    confirm()
                },
                onError: { _, _ in }
            )

            imageView.configure()
            imageView.layoutSubviews()

            #expect(imageView.heightConstraint?.constant == 0)

            await InAppWaitingForTests.wait(for: 5)

            // Style
            #expect(imageView.contentMode == .scaleAspectFit)
            #expect((imageView.layer.mask as? CAShapeLayer)?.path == imageView.configuration.style.layoutRoundedCorners(on: imageView))

            // Action
            let containsGesture = imageView.gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) ?? false
            #expect(containsGesture == true)

            // Accessibility
            #expect(imageView.accessibilityLabel == contentDescription)

            // Tap
            imageView.handleCTATap()
        }
    }

    @MainActor
    @Test func testHeightConstraint() async throws {
        let url = try #require(URL(string: "https://static.batch.com/sample/1.jpeg"))

        let imageView = InAppImageView(
            configuration: InAppImageView.Configuration(
                url: url,
                style: InAppImageView.Configuration.Style(aspect: aspect, radius: radius),
                placement: InAppImageView.Configuration.Placement(heightType: InAppHeightType(stringValue: height), margins: margins, estimateHeight: 200, estimateWidth: 200),
                action: InAppImageView.Configuration.Action(analyticsIdentifier: analyticsIdentifier, action: action),
                accessibility: InAppImageView.Configuration.Accessibility(label: contentDescription)
            ),
            onClosureTap: { _, _ in
                Issue.record("Should not be called")
            },
            onError: { _, _ in
                Issue.record("Should not be called")
            }
        )

        imageView.configure()
        imageView.layoutSubviews()

        await InAppWaitingForTests.wait(for: 5)

        #expect(imageView.heightConstraint != nil)
    }

    @MainActor
    @Test func testHeightFillConstraint() async throws {
        let url = try #require(URL(string: "https://static.batch.com/sample/1.jpeg"))

        let imageView = InAppImageView(
            configuration: InAppImageView.Configuration(
                url: url,
                style: InAppImageView.Configuration.Style(aspect: aspect, radius: radius),
                placement: InAppImageView.Configuration.Placement(heightType: InAppHeightType.fill, margins: margins, estimateHeight: 200, estimateWidth: 200),
                action: InAppImageView.Configuration.Action(analyticsIdentifier: analyticsIdentifier, action: action),
                accessibility: InAppImageView.Configuration.Accessibility(label: contentDescription)
            ),
            onClosureTap: { _, _ in
                Issue.record("Should not be called")
            },
            onError: { _, _ in
                Issue.record("Should not be called")
            }
        )

        imageView.configure()
        imageView.layoutSubviews()

        await InAppWaitingForTests.wait(for: 5)

        #expect(imageView.heightConstraint == nil)
    }

    @Test
    @MainActor
    func testFailLoading() async throws {
        let unreachableUrl = try #require(URL(string: "https://static.batch.com/sample/1000.jpeg"))

        // Because of retry expectedCount is 2
        await confirmation("Unreachable image url, should be completed with error", expectedCount: 2) { @MainActor confirm in
            let imageView = InAppImageView(
                configuration: InAppImageView.Configuration(
                    url: unreachableUrl,
                    style: InAppImageView.Configuration.Style(aspect: aspect, radius: radius),
                    placement: InAppImageView.Configuration.Placement(heightType: InAppHeightType(stringValue: height), margins: margins, estimateHeight: nil, estimateWidth: nil),
                    action: InAppImageView.Configuration.Action(analyticsIdentifier: analyticsIdentifier, action: action),
                    accessibility: InAppImageView.Configuration.Accessibility(label: contentDescription)
                ),
                onClosureTap: { _, _ in
                    Issue.record("On error only should be called")
                },
                onError: { _, component in
                    #expect(component == .image)
                    confirm()
                }
            )

            imageView.configure()

            await InAppWaitingForTests.wait(for: 5)
        }
    }
}
