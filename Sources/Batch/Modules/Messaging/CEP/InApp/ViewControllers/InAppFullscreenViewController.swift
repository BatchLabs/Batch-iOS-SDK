//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// A view controller for displaying an in-app message in a fullscreen format.
/// It handles setting up a view that covers the entire screen and places the content
/// within the safe area of the device.
/// Inspired by the legacy `BAMSGInterstitialViewController`.
class InAppFullscreenViewController: InAppViewController,
    UIAdaptivePresentationControllerDelegate, InAppRoundableCorners
{
    // MARK: - Style Properties

    /// Default corner radius for the fullscreen message container.
    let radius: [CGFloat] = [8, 8, 8, 8]

    // MARK: - Protocol Conformances

    /// Fullscreen messages are displayed within the current application's window.
    override var shouldDisplayInSeparateWindow: Bool { false }

    // MARK: - View Lifecycle

    override func loadView() {
        // Use a gradient view as the base, though it can also be a solid color.
        view = BAMSGGradientView()
        view.backgroundColor = configuration.style.backgroundColor
        // Set that delegate to make swipe to dismiss listenable
        presentationController?.delegate = self
    }

    /// Indicates whether the countdown view should be set up with safe area constraints.
    /// Subclasses can override this to enable safe area handling for countdown display.
    var setupCountdownViewIfNeededWithSafeArea: Bool { false }

    // MARK: - View Setup

    /// Overrides the base implementation to set up the specific hierarchy for a fullscreen message.
    override func setupViewContents() throws {
        view.isOpaque = false
        view.alpha = 1

        // Create a "safeView" that is constrained to the view's safe area layout guide.
        // All message content will be placed within this view.
        let safeView = UIView()
        safeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(safeView)

        NSLayoutConstraint.activate([
            safeView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            safeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            safeView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            safeView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        // Set up the main scrollable content within the safe view.
        setupViewContent(contentView: safeView)

        // Add the countdown and close buttons.
        // Use the subclass-configurable safe area setting for countdown positioning.
        setupCountdownViewIfNeeded(in: safeView, withSafeArea: setupCountdownViewIfNeededWithSafeArea)
        setupCloseButton(in: safeView)
    }

    /// Overrides the base content setup to add fullscreen-specific constraints.
    override func setupViewContent(contentView: UIView) {
        super.setupViewContent(contentView: contentView)

        // Ensure the message content is at least as tall as the scroll view,
        // and that its bottom is pinned to the scroll view's bottom.
        // This helps the content fill the available space vertically.
        messageContentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollableViewContent.heightAnchor, multiplier: 1).isActive = true
        messageContentView.bottomAnchor.constraint(equalTo: scrollableViewContent.bottomAnchor).isActive = true
    }

    // MARK: - Delegate Methods

    /// Ensures the presentation style remains consistent.
    func adaptivePresentationStyle(for _: UIPresentationController, traitCollection _: UITraitCollection) -> UIModalPresentationStyle {
        return modalPresentationStyle
    }

    /// Called when the view is dismissed by a swipe-down gesture on the presentation controller.
    func presentationControllerDidDismiss(_: UIPresentationController) {
        analyticManager.track(.closed)
    }

    // MARK: - Dismissal

    /// Overrides the base dismissal to use the standard modal dismissal logic.
    override func doDismiss() -> BAPromise<NSObject> {
        doDismissSelfModal()
    }
}
