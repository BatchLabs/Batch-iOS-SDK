//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// A base view controller for banner-style in-app messages (including modals).
/// It provides a pannable (swipe-to-dismiss) container and handles complex layout logic
/// related to screen position, size classes, and safe area insets.
/// It is inspired by the legacy `BAMSGBaseBannerViewController`.
class InAppBaseBannerViewController: InAppViewController,
    BAMSGPannableContainerViewDelegate,
    BAMSGWindowHolder
{
    // MARK: - Window Management Properties

    /// The window that presents this view controller. Used for dismissal.
    var presentingWindow: UIWindow?

    /// The window that this view controller is displayed in.
    var overlayedWindow: UIWindow?

    // MARK: - Protocol Conformances

    /// Indicates whether the message should be displayed in a new, separate window.
    override var shouldDisplayInSeparateWindow: Bool { true }

    /// Banners typically do not hide the status bar.
    override var prefersStatusBarHidden: Bool { false }

    // MARK: - Initialization

    override init(configuration: InAppViewController.Configuration) {
        super.init(configuration: configuration)
        // Banners and modals are presented over the current screen content.
        modalPresentationStyle = .overFullScreen
    }

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Computed Properties

    private var shouldOverleapSafeAreaForCurrentSize: Bool {
        configuration.shouldOverleapSafeArea(size: traitCollection.horizontalSizeClass)
    }

    // MARK: - View Creation and Hierarchy

    /// Factory method to create the main content view, which is a pannable container.
    func makeContentView() -> UIView {
        let contentView = PannableAlertContainerView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.shadowColor = .black
        contentView.shadowRadius = 15
        contentView.shadowOpacity = 0.3
        contentView.touchPassthrough = false
        contentView.scrollableContentView = scrollableViewContent
        contentView.delegate = self
        return contentView
    }

    /// A view used to create a background that can "overleap" or extend into the safe area,
    /// typically for edge-to-edge designs.
    lazy var overleapSafeAreaView: UIView = {
        let style = configuration.customStyle()
        let view = InAppRoundedContainer(style: style, format: configuration.format)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = configuration.style.backgroundColor
        view.clipsToBounds = true
        return view
    }()

    /// The main content view container, lazily created.
    lazy var contentView: UIView = makeContentView()

    /// A container that holds the final, styled inner content.
    var containerizedInnerContentView: UIView?

    // MARK: - View Lifecycle

    override func loadView() {
        // The root view is a pannable container that allows touch passthrough by default.
        let pannableAlertContainerView = PannableAlertContainerView()
        pannableAlertContainerView.delegate = self
        pannableAlertContainerView.touchPassthrough = true
        view = pannableAlertContainerView
    }

    /// Responds to changes in trait collections to update the layout dynamically.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        let viewGuide: UILayoutGuide = traitCollection.horizontalSizeClass == .compact ? view.safeAreaLayoutGuide : view.readableContentGuide

        // Re-evaluate and apply constraints for overleap and horizontal/vertical positioning.
        setupOverleap(contentView: contentView, viewGuide: viewGuide)

        if let containerizedInnerContentView = self.containerizedInnerContentView ?? (try? containerizedInnerContent()) {
            if let previousTraitCollection, let previousConstraints = horizontalConstraints[previousTraitCollection.horizontalSizeClass] {
                NSLayoutConstraint.deactivate(previousConstraints)
            }
            horizontalConstraints[traitCollection.horizontalSizeClass] = setupHorizontalConstraints(for: containerizedInnerContentView, viewGuide: viewGuide)
            verticalConstraints[traitCollection.horizontalSizeClass] = setupVerticalConstraints(for: containerizedInnerContentView, viewGuide: viewGuide)
        }
    }

    // MARK: - View Setup

    /// Sets up the main view hierarchy and constraints.
    override func setupViewContents() throws {
        view.isOpaque = false

        // Inform the pannable container about its main visible content.
        if let view = view as? BAMSGPannableAnchoredContainerView {
            view.biggestUserVisibleView = contentView
        }

        view.addSubview(contentView)
        containerizedInnerContentView = try containerizedInnerContent()
        try setupContainerView(contentView: contentView, containerView: containerizedInnerContentView!)

        // Pin the inner content to the main content view.
        NSLayoutConstraint.activate([
            containerizedInnerContentView!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerizedInnerContentView!.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerizedInnerContentView!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerizedInnerContentView!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    /// Sets up the nested container views and their constraints.
    func setupContainerView(contentView: UIView, containerView: UIView) throws {
        contentView.addSubview(containerView)

        // Use different layout guides for compact vs. regular width.
        let viewGuide: UILayoutGuide = traitCollection.horizontalSizeClass == .compact ? view.safeAreaLayoutGuide : view.readableContentGuide

        // Store constraints to manage them when traits change.
        verticalConstraints[traitCollection.horizontalSizeClass] = setupVerticalConstraints(for: containerView, viewGuide: viewGuide)
        horizontalConstraints[traitCollection.horizontalSizeClass] = setupHorizontalConstraints(for: containerView, viewGuide: viewGuide)

        setupOverleap(contentView: contentView, viewGuide: viewGuide)
        setupCloseButton(in: scrollableViewContent)

        // Place the countdown view either inside the overleap view or the main content, depending on the layout.
        if shouldOverleapSafeAreaForCurrentSize {
            setupCountdownViewIfNeeded(in: overleapSafeAreaView, withSafeArea: false)
        } else {
            setupCountdownViewIfNeeded(in: scrollableViewContent, withSafeArea: true)
        }
    }

    /// Creates the innermost container that holds the actual message content (text, image, etc.).
    func containerizedInnerContent() throws -> InAppContainer {
        let view = try InAppContainer(configuration: configuration.placement) { [weak self] in
            guard let self else { return UIView() }

            let style: InAppCustomStyle = shouldOverleapSafeAreaForCurrentSize ? .empty() : configuration.customStyle()

            let container = InAppRoundedContainer(style: style, format: configuration.format)
            container.backgroundColor = shouldOverleapSafeAreaForCurrentSize ? nil : configuration.style.backgroundColor
            container.translatesAutoresizingMaskIntoConstraints = false

            setupViewContent(contentView: container)

            return container
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    // Dictionaries to hold constraints for different size classes.
    var horizontalConstraints: [UIUserInterfaceSizeClass: [NSLayoutConstraint]] = [:]
    var verticalConstraints: [UIUserInterfaceSizeClass: [NSLayoutConstraint]] = [:]

    /// Sets up horizontal constraints to pin the content to the provided layout guide.
    func setupHorizontalConstraints(for contentView: UIView, viewGuide: UILayoutGuide) -> [NSLayoutConstraint] {
        let constraints = [
            viewGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            viewGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Sets up vertical constraints based on the message's configured position (top, center, bottom).
    func setupVerticalConstraints(for contentView: UIView, viewGuide: UILayoutGuide) -> [NSLayoutConstraint] {
        let constraints =
            switch configuration.placement.position {
            case .top:
                [
                    contentView.topAnchor.constraint(equalTo: viewGuide.topAnchor),
                    viewGuide.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor),
                ]
            case .center:
                [
                    contentView.topAnchor.constraint(greaterThanOrEqualTo: viewGuide.topAnchor),
                    contentView.centerYAnchor.constraint(equalTo: viewGuide.centerYAnchor),
                    viewGuide.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor),
                ]
            case .bottom:
                [
                    contentView.topAnchor.constraint(greaterThanOrEqualTo: viewGuide.topAnchor),
                    contentView.bottomAnchor.constraint(equalTo: viewGuide.bottomAnchor),
                ]
            @unknown default:
                [
                    contentView.topAnchor.constraint(equalTo: viewGuide.topAnchor),
                    contentView.bottomAnchor.constraint(equalTo: viewGuide.bottomAnchor),
                ]
            }

        NSLayoutConstraint.activate(constraints)

        return constraints
    }

    /// Sets up the `overleapSafeAreaView` if the configuration requires it.
    func setupOverleap(contentView: UIView, viewGuide: UILayoutGuide) {
        guard shouldOverleapSafeAreaForCurrentSize else {
            overleapSafeAreaView.removeFromSuperview()
            return
        }

        contentView.insertSubview(overleapSafeAreaView, at: 0)

        let constraints: [NSLayoutConstraint] = {
            if traitCollection.horizontalSizeClass == .compact {
                var compactConstraints = [
                    overleapSafeAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    overleapSafeAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                ]

                switch configuration.placement.position {
                case .top:
                    compactConstraints += [
                        overleapSafeAreaView.topAnchor.constraint(equalTo: view.topAnchor),
                        overleapSafeAreaView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                    ]
                case .bottom:
                    compactConstraints += [
                        overleapSafeAreaView.topAnchor.constraint(equalTo: contentView.topAnchor),
                        overleapSafeAreaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    ]
                case .center:
                    // This path should not be taken as `shouldOverleapSafeAreaForCurrentSize`
                    // is false for center-aligned banners.
                    break
                @unknown default:
                    break
                }
                return compactConstraints
            } else {
                return [
                    overleapSafeAreaView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    overleapSafeAreaView.leadingAnchor.constraint(equalTo: viewGuide.leadingAnchor),
                    overleapSafeAreaView.trailingAnchor.constraint(equalTo: viewGuide.trailingAnchor),
                    overleapSafeAreaView.bottomAnchor.constraint(equalTo: viewGuide.bottomAnchor),
                ]
            }
        }()

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Delegate Methods

    /// Called when the user dismisses the message by panning (swiping).
    func pannableContainerWasDismissed(_: BAMSGBaseContainerView) {
        closeButtonAction()
    }

    /// Ensures the presentation style remains consistent.
    func adaptivePresentationStyle(for _: UIPresentationController, traitCollection _: UITraitCollection) -> UIModalPresentationStyle {
        return self.modalPresentationStyle
    }

    // MARK: - Dismissal

    /// Overrides the base dismissal to handle window-based presentation.
    override func doDismiss() -> BAPromise<NSObject> {
        if let presentingWindow {
            return BAMessagingCenter.instance().dismiss(presentingWindow as? BAMSGOverlayWindow)
        } else {
            return doDismissSelfModal()
        }
    }
}
