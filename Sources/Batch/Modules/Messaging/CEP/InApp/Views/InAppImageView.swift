//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// A `UIImageView` subclass designed to display remote images or GIFs with support for loading indicators,
/// tap actions, and custom styling within an in-app message.
class InAppImageView: UIImageView, InAppContainerizable, InAppClosureDelegate {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: image?.size.width ?? -1, height: -1)
    }

    // MARK: -

    /// The configuration that defines the image's appearance, content, and behavior.
    let configuration: InAppImageView.Configuration

    /// A closure that is executed when the image is tapped.
    let onClosureTap: Closure

    /// A closure that is executed when an error occurs, such as a failure to download the image.
    let onError: InAppErrorDelegate.Closure

    /// The animator responsible for playing GIF files.
    var gifAnimator: BATGIFAnimator?

    /// The layout constraint that manages the view's height, if specified.
    var heightConstraint: NSLayoutConstraint?

    /// An activity indicator that displays while the image is being downloaded.
    lazy var loadingOverlay: UIActivityIndicatorView = {
        let loadingView = UIActivityIndicatorView(style: .medium)
        loadingView.sizeToFit()
        loadingView.isHidden = true
        loadingView.isExclusiveTouch = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        return loadingView
    }()

    // MARK: -

    /// Initializes the image view with a given configuration and event handlers.
    /// - Parameters:
    ///   - configuration: The configuration object defining the image's style and behavior.
    ///   - onClosureTap: The closure to execute when the image is tapped.
    ///   - onError: The closure to execute if an error occurs.
    init(
        configuration: InAppImageView.Configuration,
        onClosureTap: @escaping InAppClosureDelegate.Closure,
        onError: @escaping InAppErrorDelegate.Closure
    ) {
        self.configuration = configuration
        self.onClosureTap = onClosureTap
        self.onError = onError

        super.init(frame: .zero)

        configure()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Apply corner radius from the style configuration.
        configuration.style.layoutRoundedCorners(on: self)

        // If height is set to auto, dynamically calculate it based on the image's aspect ratio.
        if case .auto = configuration.placement.heightType, let image {
            heightConstraint?.constant = (frame.width / image.size.width) * image.size.height
            updateConstraints()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateConstraints()
        setNeedsDisplay()
    }

    // MARK: - Loading Overlay

    /// Adds the loading overlay to the view's hierarchy.
    func addLoadingOverlay() {
        guard loadingOverlay.superview == nil else { return }

        addSubview(loadingOverlay)
        bringSubviewToFront(loadingOverlay)

        NSLayoutConstraint.activate([
            loadingOverlay.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingOverlay.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    /// Shows the loading overlay and starts its animation.
    func showLoadingOverlay() {
        loadingOverlay.startAnimating()
        DispatchQueue.main.async { [weak self] in
            self?.loadingOverlay.isHidden = false
        }
    }

    /// Hides the loading overlay and stops its animation.
    func hideLoadingOverlay() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingOverlay.isHidden = true
            self?.loadingOverlay.stopAnimating()
        }
    }

    // MARK: - Configuration

    /// Applies the initial configuration to the view.
    func configure() {
        configuration.apply(to: self)

        addLoadingOverlay()
        showLoadingOverlay()

        // If an action is defined, enable user interaction and add a tap gesture recognizer.
        if configuration.action?.action != nil {
            isUserInteractionEnabled = true
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCTATap))
            addGestureRecognizer(tapGestureRecognizer)
        }

        load(url: configuration.url)
    }

    /// Handles the tap gesture by invoking the `onClosureTap` callback.
    @objc func handleCTATap() {
        onClosureTap(configuration.action, nil)
    }
}

// MARK: - Configuration Structures

extension InAppImageView {
    /// A structure that encapsulates all display and behavioral settings for an `InAppImageView`.
    struct Configuration {
        // MARK: -

        private static let BAMESSAGING_DEFAULT_TIMEOUT: TimeInterval = 30

        // MARK: -

        /// The URL of the image to display.
        let url: URL
        /// The styling rules for the image view, such as aspect ratio and corners.
        let style: Style
        /// The layout and positioning rules for the image view.
        let placement: Placement
        /// The call-to-action to perform when the image is tapped.
        let action: Action?
        /// The accessibility attributes for the image view.
        let accessibility: Accessibility
        /// The timeout interval for downloading the image.
        let timeout: TimeInterval

        // MARK: -

        init(url: URL, style: Style, placement: Placement, action: Action?, accessibility: Accessibility, timeout: TimeInterval = BAMESSAGING_DEFAULT_TIMEOUT) {
            self.url = url
            self.style = style
            self.placement = placement
            self.action = action
            self.accessibility = accessibility
            self.timeout = timeout
        }

        // MARK: -

        /// Applies the configuration's settings to a given image view.
        /// - Parameter image: The `InAppImageView` to configure.
        func apply(to image: InAppImageView) {
            style.apply(on: image)
            accessibility.apply(on: image)
            placement.applyHeightConstraint(on: image)
        }
    }
}

extension InAppImageView.Configuration {
    /// Encapsulates layout properties, such as sizing, margins, and alignment.
    struct Placement: InAppContainerizable {
        // MARK: -

        /// The vertical sizing behavior, based on `InAppHeightType`.
        let heightType: InAppHeightType?
        /// The horizontal sizing behavior, defaulting to 100% width.
        let widthType: InAppWidthType? = .percent(value: 100)
        /// The margins around the image view.
        let margins: UIEdgeInsets
        /// An estimated height used for initial layout calculations.
        let estimateHeight: Int?
        /// An estimated width used for initial layout calculations.
        let estimateWidth: Int?

        let horizontalAlignment: InAppHorizontalAlignment? = .left
        let verticalAlignment: InAppVerticalAlignment? = .top

        /// Applies the height constraint to the image view based on the `heightType`.
        /// - Parameter image: The `InAppImageView` to apply the constraint to.
        func applyHeightConstraint(on image: InAppImageView) {
            guard heightType != .fill else { return }

            let constant: CGFloat = switch heightType {
                case let .fixed(value): CGFloat(value)
                case .auto:
                    if let estimateHeight, let estimateWidth { (image.frame.width / CGFloat(estimateWidth)) * CGFloat(estimateHeight)
                    } else { 0 }
                default: 0
            }

            image.heightConstraint = image.heightAnchor.constraint(equalToConstant: constant)

            guard let heightConstraint = image.heightConstraint else { return }

            NSLayoutConstraint.activate([
                heightConstraint,
            ])
        }
    }

    /// Defines the visual appearance of the image view, including aspect ratio and corner radius.
    struct Style: InAppRoundableCorners {
        // MARK: -

        /// The content mode, determining how the image is scaled.
        let aspect: UIImageView.ContentMode
        /// The corner radius values for each corner.
        let radius: [CGFloat]

        // MARK: -

        init(aspect: InAppAspectRatio, radius: [Int]) {
            self.aspect = switch aspect {
                case .fill: .scaleAspectFill
                case .fit: .scaleAspectFit
            }
            self.radius = radius.map(CGFloat.init)
        }

        // MARK: -

        /// Applies the style attributes to the image view.
        /// - Parameter image: The `InAppImageView` to style.
        func apply(on image: InAppImageView) {
            image.clipsToBounds = true
            image.layer.masksToBounds = true
            image.contentMode = aspect
        }
    }

    /// Defines a Call-To-Action (CTA) associated with tapping the image.
    struct Action: InAppCTAComponent {
        // MARK: -

        /// The identifier used for analytics.
        let analyticsIdentifier: String
        /// The underlying action object.
        let action: BAMSGAction?
        let type: InAppCTAType = .image
    }

    /// Defines accessibility attributes for the image view.
    struct Accessibility {
        // MARK: -

        /// A textual description of the image for screen readers.
        let label: String?

        // MARK: -

        /// Applies the accessibility attributes to the image view.
        /// - Parameter image: The `InAppImageView` to configure.
        func apply(on image: InAppImageView) {
            image.accessibilityLabel = label
            image.accessibilityIgnoresInvertColors = true
            image.isAccessibilityElement = true
        }
    }
}

// MARK: - Image and GIF Loading

extension InAppImageView {
    /// Initiates the download of an image from a URL.
    /// - Parameter url: The URL of the image to download.
    func load(url: URL) {
        BAMSGImageDownloader.downloadImage(
            for: url,
            downloadTimeout: configuration.timeout
        ) { [weak self] data, isGif, image, error in
            guard let self else { return }

            if let error {
                onError(error, .image)
                return
            }

            hideLoadingOverlay()

            if isGif {
                loadGif(data: data)
            } else {
                loadImage(loadedImage: image)
            }
        }
    }

    /// Sets a standard `UIImage` as the view's image.
    /// - Parameter loadedImage: The image to display.
    func loadImage(loadedImage: UIImage?) {
        BAThreading.performBlock(onMainThreadAsync: { [weak self] in
            self?.image = loadedImage
            self?.invalidateIntrinsicContentSize()
            self?.layoutSubviews()
        })
    }

    /// Loads and begins animating a GIF from raw data.
    /// - Parameter data: The raw `Data` of the GIF file.
    func loadGif(data: Data?) {
        guard let data else { return }
        do {
            let gifFile = try BATGIFFile(data: data)

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                gifAnimator = BATGIFAnimator(file: gifFile)
                gifAnimator?.delegate = self
                gifAnimator?.startAnimating()
            }
        } catch let error as NSError {
            BALogger.debug(domain: "Messaging", message: "Could not load gif file: \(error.code) \(error.localizedDescription)")

            // If GIF loading fails, attempt to display it as a static image.
            let fallbackImage = UIImage(data: data)
            loadImage(loadedImage: fallbackImage)
        }
    }
}

// MARK: - BATGIFAnimatorDelegate

extension InAppImageView: BATGIFAnimatorDelegate {
    /// Updates the view's image to the current frame provided by the GIF animator.
    /// - Parameters:
    ///   - animator: The animator instance.
    ///   - image: The `UIImage` object for the current frame.
    func animator(_: BATGIFAnimator, needsToDisplay image: UIImage) {
        self.image = image
        self.layoutSubviews()
    }
}
