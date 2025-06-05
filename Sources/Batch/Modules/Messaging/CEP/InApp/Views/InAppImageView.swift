//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Represents an in-app image view
class InAppImageView: UIImageView, InAppContainerizable, InAppClosureDelegate {
    // MARK: -

    let configuration: InAppImageView.Configuration
    let onClosureTap: Closure
    let onError: InAppErrorDelegate.Closure
    var gifAnimator: BATGIFAnimator?
    var heightConstraint: NSLayoutConstraint?

    lazy var loadingOverlay: UIActivityIndicatorView = {
        let loadingView = UIActivityIndicatorView(style: .medium)
        loadingView.sizeToFit()
        loadingView.isHidden = true
        loadingView.isExclusiveTouch = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        return loadingView
    }()

    // MARK: -

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

        // Corners
        configuration.style.layoutRoundedCorners(on: self)

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

    // MARK: -

    func addLoadingOverlay() {
        guard loadingOverlay.superview == nil else { return }

        addSubview(loadingOverlay)
        bringSubviewToFront(loadingOverlay)

        NSLayoutConstraint.activate([
            loadingOverlay.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingOverlay.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    func showLoadingOverlay() {
        loadingOverlay.startAnimating()
        DispatchQueue.main.async { [weak self] in
            self?.loadingOverlay.isHidden = false
        }
    }

    func hideLoadingOverlay() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingOverlay.isHidden = true
            self?.loadingOverlay.stopAnimating()
        }
    }

    func configure() {
        configuration.apply(to: self)

        addLoadingOverlay()

        showLoadingOverlay()
        if configuration.action?.action != nil {
            isUserInteractionEnabled = true
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCTATap))
            addGestureRecognizer(tapGestureRecognizer)
        }

        load(url: configuration.url)
    }

    @objc func handleCTATap() {
        onClosureTap(configuration.action, nil)
    }
}

extension InAppImageView {
    struct Configuration {
        // MARK: -

        private static let BAMESSAGING_DEFAULT_TIMEOUT: TimeInterval = 30

        // MARK: -

        let url: URL
        let style: Style
        let placement: Placement
        let action: Action?
        let accessibility: Accessibility
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

        func apply(to image: InAppImageView) {
            style.apply(on: image)
            accessibility.apply(on: image)
            placement.applyHeightConstraint(on: image)
        }
    }
}

extension InAppImageView.Configuration {
    struct Placement: InAppContainerizable {
        // MARK: -

        let heightType: InAppHeightType?
        let margins: UIEdgeInsets
        let estimateHeight: Int?
        let estimateWidth: Int?

        let horizontalAlignment: InAppHorizontalAlignment? = .left
        let verticalAlignment: InAppVerticalAlignment? = .top

        func applyHeightConstraint(on image: InAppImageView) {
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

    struct Style: InAppRoundableCorners {
        // MARK: -

        let aspect: UIImageView.ContentMode
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

        func apply(on image: InAppImageView) {
            image.clipsToBounds = true
            image.layer.masksToBounds = true
            image.contentMode = aspect
        }
    }

    struct Action: InAppCTAComponent {
        // MARK: -

        let analyticsIdentifier: String
        let action: BAMSGAction?
        let type: InAppCTAType = .image
    }

    struct Accessibility {
        // MARK: -

        let label: String?

        // MARK: -

        func apply(on image: InAppImageView) {
            image.accessibilityLabel = label
            image.accessibilityIgnoresInvertColors = true
            image.isAccessibilityElement = true
        }
    }
}

extension InAppImageView {
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

    func loadImage(loadedImage: UIImage?) {
        BAThreading.performBlock(onMainThreadAsync: { [weak self] in
            self?.image = loadedImage
            self?.layoutSubviews()
        })
    }

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

            let fallbackImage = UIImage(data: data)

            loadImage(loadedImage: fallbackImage)
        }
    }
}

// MARK: - GIF Animator delegate methods

extension InAppImageView: BATGIFAnimatorDelegate {
    func animator(_: BATGIFAnimator, needsToDisplay image: UIImage) {
        self.image = image
        self.layoutSubviews()
    }
}
