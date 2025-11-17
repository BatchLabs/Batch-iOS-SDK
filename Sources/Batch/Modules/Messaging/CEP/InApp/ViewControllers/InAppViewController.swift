//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Main view controller to handle all common interaction and behavior for in-app messages.
/// This class serves as the base for all other specific message format view controllers (Modal, Banner, etc.).
/// It is inspired by the legacy `BAMSGViewController`.
class InAppViewController: UIViewController, InAppViewCountdownClose, BatchMessagingViewController {
    // MARK: - Properties

    /// The configuration object containing all the styling and behavioral parameters for the message.
    let configuration: Configuration

    /// A flag to track whether the message has been dismissed, preventing duplicate dismissal calls.
    var isDismissed: Bool = false

    /// The timestamp when the auto-closing countdown started.
    var autoclosingStartTime: TimeInterval = 0

    /// The total duration of the auto-closing countdown.
    var autoclosingDuration: TimeInterval = 0

    /// A wrapper for handling analytics tracking for the in-app message.
    let analyticManager: InAppAnalyticWrapper

    /// Indicates whether the message should be displayed in a new, separate window.
    var shouldDisplayInSeparateWindow: Bool { true }

    // MARK: - Initialization

    /// Initializes the view controller with a specific configuration and message data.
    /// - Parameters:
    ///   - configuration: The configuration for the message's appearance and behavior.
    ///   - message: The raw campaign message data used for analytics.
    init(configuration: Configuration) {
        self.configuration = configuration
        self.analyticManager = InAppAnalyticWrapper(message: configuration.content.message)
        super.init(nibName: nil, bundle: nil)
    }

    /// Storyboard/XIB initialization is not supported.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Ensures the view scales properly with Dynamic Type settings.
        view.maximumContentSizeCategory = UIContentSizeCategory.extraExtraExtraLarge

        // Attempt to configure and set up the main view contents.
        do {
            try messageContentView.configure()
            try setupViewContents()
        } catch {
            // If setup fails, log the error and dismiss the view controller.
            BALogger.error(domain: String(describing: Self.self), message: error.localizedDescription)
            _ = dismiss()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start the auto-close countdown if configured.
        startAutoclosingCountdownIfNeeded(configuration: configuration)
        // Track the "shown" event for analytics.
        analyticManager.track(.shown)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Track the "dismissed" event and update the state.
        analyticManager.track(.dismissed)
        isDismissed = true
    }

    /// Responds to device orientation or size changes.
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Trigger a layout update to adapt to the new size.
        view.layoutSubviews()
    }

    /// Responds to changes in trait collections, like dark mode or size class.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Trigger a constraint update to adapt to new traits.
        view.updateConstraints()
    }

    // MARK: - UI Components (Lazy-loaded)

    /// The countdown view that shows the remaining time before auto-closing.
    lazy var countdownView: BAMSGCountdownView = {
        let countdownView = BAMSGCountdownView()
        countdownView.clipsToBounds = true
        countdownView.layer.masksToBounds = true
        countdownView.translatesAutoresizingMaskIntoConstraints = false
        return countdownView
    }()

    /// The close button for the message. Returns nil if not configured.
    lazy var closeButton: InAppCloseButton? = {
        guard let cross = configuration.closeConfiguration.cross else { return nil }
        return InAppCloseButton(
            configuration: .init(style: .init(color: cross.color, backgroundColor: cross.backgroundColor)),
            onClosureTap: onClosureTap,
            analyticTrigger: analyticManager.track(_:)
        )
    }()

    /// The scroll view that contains the message content, allowing for vertical scrolling if needed.
    lazy var scrollableViewContent: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        return scrollView
    }()

    /// The main container view that holds all the message's content (text, images, buttons).
    lazy var messageContentView: InAppRootContainerView = {
        let inAppView = InAppRootContainerView(
            configuration: .init(
                builder: .init(viewsBuilder: configuration.builder.viewsBuilder),
                placement: .init(margins: configuration.placement.margins)
            ),
            onClosureTap: onClosureTap,
            onError: { [weak self] error, component in
                guard let self else { return }

                BALogger.error(domain: String(describing: component), message: error.localizedDescription)
                // If an image fails to load and it's the only one, dismiss the message.
                if case .image = component, configuration.builder.isOnlyOneImage {
                    BAThreading.performBlock(onMainThreadAsync: { [weak self] in
                        self?.dismiss()
                    })
                }
            }
        )
        inAppView.translatesAutoresizingMaskIntoConstraints = false
        return inAppView
    }()

    /// The closure that handles tap events on actions (like buttons or the close icon).
    lazy var onClosureTap: InAppClosureDelegate.Closure = { [weak self] component, _ in
        guard let self else { return }

        if let component {
            analyticManager.track(.cta(component: component))
        }

        dismiss()
            .then { [configuration = self.configuration] _ in
                if let component, let action = component.action {
                    let sourceMessage = configuration.content.message.sourceMessage
                    BAMessagingCenter.instance()
                        .perform(
                            action,
                            source: sourceMessage,
                            ctaIdentifier: component.analyticsIdentifier,
                            messageIdentifier: sourceMessage.devTrackingIdentifier
                        )
                }
            }
    }

    // MARK: - Layout and Constraints

    /// Sets up the scroll view and its content. This method is crucial for enabling scrolling.
    func setupViewContent(contentView: UIView) {
        contentView.addSubview(scrollableViewContent)
        scrollableViewContent.addSubview(messageContentView)

        // Pin the scroll view to its container.
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollableViewContent.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollableViewContent.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollableViewContent.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollableViewContent.bottomAnchor),
        ])

        // This low-priority constraint helps resolve layout ambiguity, suggesting the scroll view
        // should be at least as tall as its content.
        let scrollSizeConstraint = NSLayoutConstraint(
            item: scrollableViewContent,
            attribute: .height,
            relatedBy: .greaterThanOrEqual,
            toItem: messageContentView,
            attribute: .height,
            multiplier: 1,
            constant: 0
        )
        scrollSizeConstraint.priority = .init(200)
        scrollableViewContent.addConstraint(scrollSizeConstraint)

        // Set up constraints for the message content within the scroll view.
        // Pinning to the edges and setting the width allows the content's intrinsic height
        // to define the scrollable area.
        NSLayoutConstraint.activate([
            messageContentView.topAnchor.constraint(equalTo: scrollableViewContent.topAnchor),
            messageContentView.leadingAnchor.constraint(equalTo: scrollableViewContent.leadingAnchor),
            messageContentView.trailingAnchor.constraint(equalTo: scrollableViewContent.trailingAnchor),
            messageContentView.bottomAnchor.constraint(greaterThanOrEqualTo: scrollableViewContent.bottomAnchor),
            messageContentView.widthAnchor.constraint(equalTo: scrollableViewContent.widthAnchor),
        ])
    }

    /// Adds the close button to the view and sets its constraints.
    func setupCloseButton(in view: UIView) {
        guard let closeButton else { return }
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 8),
        ])
    }

    /// Abstract method to be implemented by subclasses to set up their specific view hierarchies.
    func setupViewContents() throws {
        fatalError("You must override setupViewContents in a subclass")
    }

    // MARK: - Actions and Dismissal

    /// Action for the close button.
    @objc func closeButtonAction() {
        analyticManager.track(.closed)

        dismiss()
    }

    /// Public method to initiate the dismissal of the view controller.
    @discardableResult
    func dismiss() -> BAPromise<NSObject> {
        guard !isDismissed else {
            let promise = BAPromise()
            promise.resolve(nil)
            return promise
        }

        return doDismiss()
    }

    /// Abstract method to be implemented by subclasses to handle their specific dismissal logic.
    func doDismiss() -> BAPromise<NSObject> {
        fatalError("You must override doDismiss in a subclass")
    }

    /// Handles dismissing a modally presented view controller.
    func doDismissSelfModal() -> BAPromise<NSObject> {
        let promise = BAPromise()
        if presentingViewController != nil {
            // Only dismiss if we are not currently presenting another view controller.
            if presentedViewController == nil {
                dismiss(animated: true) { promise.resolve(nil) }
            } else {
                BALogger.debug(domain: String(describing: self), message: "Refusing to dismiss modal: something is covering us.")
                promise.reject(nil)
            }
        } else {
            BALogger.debug(domain: String(describing: self), message: "Refusing to dismiss modal: no presenting view controller.")
            promise.reject(nil)
        }
        return promise
    }

    /// Called when the autoclosing timer fires.
    func autoclosingDidFire() {
        analyticManager.track(.automaticallyClosed)
        dismiss()
    }
}
