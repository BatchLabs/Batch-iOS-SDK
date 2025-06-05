//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Main view controller to handle all common interaction and behavior
/// Inspired by: ``BAMSGViewController``
class InAppViewController: UIViewController {
    // MARK: -

    let configuration: Configuration

    var isDismissed: Bool = false

    var autoclosingStartTime: TimeInterval
    var autoclosingDuration: TimeInterval

    var autoclosingRemainingTime: TimeInterval {
        return autoclosingDuration - (BAUptimeProvider.uptime() - autoclosingStartTime)
    }

    let analyticManager: InAppAnalyticWrapper

    // MARK: -

    init(configuration: Configuration, message: BAMSGCEPMessage) {
        self.autoclosingStartTime = 0
        self.autoclosingDuration = 0
        self.configuration = configuration
        self.analyticManager = InAppAnalyticWrapper(message: message)

        // Delegate

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()

        setupRootStyle()

        do {
            try messageContentView.configure()
        } catch {
            BALogger.error(domain: String(describing: Self.self), message: error.localizedDescription)
            _ = dismiss()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let delay = configuration.closeConfiguration.delay {
            startAutoclosingCountdown(delay: delay)
        }

        analyticManager.track(.shown)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        analyticManager.track(.dismissed)

        isDismissed = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        view.layoutSubviews()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        view.updateConstraints()
    }

    // MARK: -

    lazy var closeButton: InAppCloseButton? = {
        guard let cross = configuration.closeConfiguration.cross else { return nil }

        let button = InAppCloseButton(
            configuration: InAppCloseButton.Configuration(style: InAppCloseButton.Configuration.Style(
                color: cross.color,
                backgroundColor: cross.backgroundColor
            )),
            onClosureTap: onClosureTap,
            analyticTrigger: analyticManager.track(_:)
        )

        return button
    }()

    lazy var countdownView: BAMSGCountdownView? = {
        guard let delay = configuration.closeConfiguration.delay else { return nil }

        let view = BAMSGCountdownView()
        view.setColor(delay.color ?? .clear)
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    // MARK: -

    lazy var scrollableViewContent: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false

        if #available(iOS 17.4, visionOS 1.1, *) {
            scrollView.bouncesVertically = false
        }

        scrollView.delaysContentTouches = false
        scrollView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        scrollView.addSubview(messageContentView)

        let scrollSizeConstraint = NSLayoutConstraint(item: scrollView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: messageContentView, attribute: .height, multiplier: 1, constant: 0)
        scrollSizeConstraint.priority = .init(200)
        scrollView.addConstraint(scrollSizeConstraint)
        scrollView.addConstraints(
            [NSLayoutConstraint.Attribute.leading, .trailing, .top, .bottom, .width].map {
                layoutConstraint(item: messageContentView, attribute: $0, relatedBy: .equal, toItem: scrollView)
            } + [
                layoutConstraint(item: messageContentView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: scrollView),
            ]
        )

        return scrollView
    }()

    lazy var messageContentView: InAppRootContainerView = {
        let inAppView = InAppRootContainerView(
            configuration: InAppRootContainerView.Configuration(
                builder: InAppRootContainerView.Configuration.Builder(
                    viewsBuilder: configuration.builder.viewsBuilder
                ),
                placement: InAppRootContainerView.Configuration.Placement(
                    margins: configuration.placement.margins
                )
            ),
            onClosureTap: onClosureTap,
            onError: { [weak self] error, component in
                guard let self else { return }

                BALogger.error(domain: String(describing: component), message: error.localizedDescription)

                switch (component, configuration.builder.isOnlyOneImage) {
                    case (.image, true):
                        BAThreading.performBlock(onMainThreadAsync: { [weak self] in
                            self?.dismiss()
                        })

                    default:
                        break
                }
            }
        )
        inAppView.translatesAutoresizingMaskIntoConstraints = false
        return inAppView
    }()

    lazy var onClosureTap: InAppClosureDelegate.Closure = { [weak self] component, _ in
        guard let self else { return }

        analyticManager.track(.closed)

        dismiss().then { [weak self] _ in
            if let component, let action = component.action {
                self?.analyticManager.track(.cta(action: component))
            }
        }
    }

    func containerizedInnerContent() throws -> InAppContainer {
        let view = try InAppContainer(configuration: configuration.placement) { [weak self] in
            guard let self else { return UIView() }

            let shouldOverleapSafeArea = configuration.shouldOverleapSafeArea(size: traitCollection.horizontalSizeClass)
            let style = if shouldOverleapSafeArea {
                CustomStyle(
                    borderWidth: nil,
                    borderColor: nil,
                    radius: []
                )
            } else {
                CustomStyle(
                    borderWidth: configuration.style.borderWidth,
                    borderColor: configuration.style.borderColor,
                    radius: configuration.style.radius
                )
            }

            let container = InAppRoundedContainer(style: style, isModal: configuration.style.isModal)
            container.backgroundColor = shouldOverleapSafeArea ? nil : configuration.style.backgroundColor
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(scrollableViewContent)

            let constraints = [NSLayoutConstraint.Attribute.leading, .trailing, .top, .bottom, .width].map {
                self.layoutConstraint(item: container, attribute: $0, relatedBy: .equal, toItem: self.scrollableViewContent)
            }

            NSLayoutConstraint.activate(constraints)

            return container
        }

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    // MARK: -

    func layoutConstraint(item: UIView, attribute: NSLayoutConstraint.Attribute, relatedBy: NSLayoutConstraint.Relation, toItem: UIView) -> NSLayoutConstraint {
        NSLayoutConstraint(
            item: item,
            attribute: attribute,
            relatedBy: relatedBy,
            toItem: toItem,
            attribute: attribute,
            multiplier: 1,
            constant: 0
        )
    }

    func setupVerticalConstraints(for contentView: UIView, viewGuide: UILayoutGuide) -> [NSLayoutConstraint] {
        let constraints = switch configuration.placement.position {
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

        return constraints
    }

    func setupCloseButton(in view: UIView) {
        guard let closeButton else { return }

        closeButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(closeButton)

        let constraints = [
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 8),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func setupCountdownView(in view: UIView, withSafeArea: Bool) {
        guard let countdownView else { return }

        countdownView.translatesAutoresizingMaskIntoConstraints = false
        countdownView.layer.masksToBounds = true
        view.addSubview(countdownView)

        var constraints = [
            countdownView.heightAnchor.constraint(equalToConstant: 2),
        ]

        if withSafeArea {
            constraints += [
                countdownView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: countdownView.trailingAnchor),
            ]
        } else {
            constraints += [
                countdownView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: countdownView.trailingAnchor),
            ]
        }

        let additionnalBorderWidth: CGFloat = (configuration.style.borderWidth ?? 0) / 2
        let anchorConstraint: NSLayoutConstraint = if configuration.style.isModal {
            switch configuration.placement.position {
                case .top: countdownView.bottomAnchor.constraint(equalTo: withSafeArea ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor, constant: -additionnalBorderWidth)
                case .center, .bottom: countdownView.topAnchor.constraint(equalTo: withSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor, constant: additionnalBorderWidth)
                @unknown default: countdownView.topAnchor.constraint(equalTo: withSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor, constant: additionnalBorderWidth)
            }
        } else {
            countdownView.topAnchor.constraint(equalTo: withSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor, constant: additionnalBorderWidth)
        }

        NSLayoutConstraint.activate(constraints + [anchorConstraint])
    }

    func setupViewContent(contentView: UIView) throws {
        let containerizedInnerContent = try containerizedInnerContent()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        if traitCollection.horizontalSizeClass != .compact {
            contentView.layoutMargins = .zero
        }

        let size = traitCollection.horizontalSizeClass
        if configuration.shouldOverleapSafeArea(size: size) {
            contentView.addSubview(overleapSafeAreaView)
            overleapSafeAreaView.addSubview(containerizedInnerContent)

            let constraints: [NSLayoutConstraint] = [
                overleapSafeAreaView.topAnchor.constraint(equalTo: contentView.topAnchor),
                overleapSafeAreaView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                overleapSafeAreaView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                overleapSafeAreaView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ]

            NSLayoutConstraint.activate(constraints)
        } else {
            contentView.addSubview(containerizedInnerContent)
        }

        view.addSubview(contentView)

        var constraints = [
            contentView.leadingAnchor.constraint(equalTo: containerizedInnerContent.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerizedInnerContent.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: containerizedInnerContent.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerizedInnerContent.bottomAnchor),
        ]

        let viewGuide = traitCollection.horizontalSizeClass == .compact ? view.safeAreaLayoutGuide : view.readableContentGuide

        if configuration.shouldOverleapSafeArea(size: traitCollection.horizontalSizeClass) {
            constraints += [
                contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ]
        } else {
            if configuration.style.isModal {
                constraints += [
                    viewGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    viewGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                ]
            } else {
                constraints += [
                    contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                ]
            }
        }

        constraints += setupVerticalConstraints(for: contentView, viewGuide: viewGuide)

        NSLayoutConstraint.activate(constraints)
    }

    lazy var overleapSafeAreaView: UIView = {
        let style = CustomStyle(
            borderWidth: configuration.style.borderWidth,
            borderColor: configuration.style.borderColor,
            radius: configuration.style.radius
        )

        let view = InAppRoundedContainer(style: style, isModal: configuration.style.isModal)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = configuration.style.backgroundColor
        view.clipsToBounds = true

        return view
    }()

    func setupRootStyle() {
        view.maximumContentSizeCategory = UIContentSizeCategory.extraExtraExtraLarge
    }

    // MARK: -

    func startAutoclosingCountdown(delay: Configuration.CloseConfiguration.Delay) {
        autoclosingDuration = TimeInterval(delay.value)
        autoclosingStartTime = BAUptimeProvider.uptime()
        let autoCloseTime = DispatchTime.now().advanced(by: .seconds(delay.value))
        DispatchQueue.main.asyncAfter(deadline: autoCloseTime) { [weak self] in
            self?.internalAutoclosingDidFire()
        }

        doAnimateAutoclosing()
    }

    func internalAutoclosingDidFire() {
        guard !isDismissed else { return }

        autoclosingDidFire()
    }

    func doAnimateAutoclosing() {
        guard autoclosingDuration > 0, let countdownView else { return }

        let timeLeft = autoclosingRemainingTime
        countdownView.setPercentage(Float(timeLeft) / Float(autoclosingDuration))

        view.layoutSubviews()
        countdownView.layoutIfNeeded()

        UIView.animate(withDuration: timeLeft, delay: 0, options: .curveLinear, animations: { [weak countdownView] in
            countdownView?.setPercentage(0)
        })
    }

    func autoclosingDidFire() {
        analyticManager.track(.automaticallyClosed)

        dismiss()
    }

    // MARK: -

    @objc func closeButtonAction() {
        dismiss()
    }

    @discardableResult
    func dismiss() -> BAPromise<NSObject> {
        guard !isDismissed else {
            let promise = BAPromise()
            promise.resolve(nil)
            return promise
        }

        return doDismiss()
    }

    func doDismiss() -> BAPromise<NSObject> {
        fatalError("You must override doDismiss in a subclass")
    }

    func doDismissSelfModal() -> BAPromise<NSObject> {
        let promise = BAPromise()
        if self.presentingViewController != nil {
            if self.presentedViewController == nil {
                dismiss(animated: true) {
                    promise.resolve(nil)
                }
            } else {
                BALogger.debug(domain: String(describing: self), message: "Refusing to dismiss modal: something is covering us.")
                promise.reject(nil)
            }
        } else {
            BALogger.debug(domain: String(describing: self), message: "Refusing to dismiss modal: no presenting view controller. We're probably not on screen.")
            promise.reject(nil)
        }

        return promise
    }

    func userDidCloseMessage() {
        if isDismissed {
            return
        }
        isDismissed = true

        analyticManager.track(.closed)
    }
}

extension InAppViewController {
    /// Represents a custom style to handle overleap safe area as MEP
    /// Should only be used in ``InAppViewController``
    struct CustomStyle: InAppBorderable & InAppRoundableCorners {
        let borderWidth: CGFloat?
        let borderColor: UIColor?
        let radius: [CGFloat]

        init(borderWidth: CGFloat?, borderColor: UIColor?, radius: [CGFloat]) {
            self.borderWidth = borderWidth
            self.borderColor = borderColor
            self.radius = radius
        }
    }
}
