//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

extension InAppImageView {
    /// Figma: https://www.figma.com/design/lTSdGYeZ81Dn5bzc4adAWO/%5BSPEC%5D-In-app-composer?node-id=157-9741&t=cfQwlQPvGFqoHHHL-4
    struct Configuration {
        // MARK: - Configuration

        private static let BAMESSAGING_DEFAULT_TIMEOUT: TimeInterval = 30

        // MARK: - Parameters

        let url: URL
        let style: Style
        let placement: Placement
        let action: Action?
        let accessibility: Accessibility
        let timeout: TimeInterval

        // MARK: - Initializer

        init(url: URL, style: Style, placement: Placement, action: Action?, accessibility: Accessibility, timeout: TimeInterval = BAMESSAGING_DEFAULT_TIMEOUT) {
            self.url = url
            self.style = style
            self.placement = placement
            self.action = action
            self.accessibility = accessibility
            self.timeout = timeout
        }

        // MARK: - Functions

        func apply(to image: InAppImageView) {
            style.apply(on: image)
            accessibility.apply(on: image)
        }
    }
}

extension InAppImageView.Configuration {
    struct Placement: InAppContainerizable {
        // MARK: - InAppContainerizable

        let heightType: InAppHeightType?
        let margins: UIEdgeInsets
    }

    struct Style: InAppRoundableCorners {
        // MARK: - Parameters

        let aspect: UIImageView.ContentMode
        let radius: [CGFloat]

        // MARK: - Initializer

        init(aspect: InAppAspectRatio, radius: [Int]) {
            self.aspect = switch aspect {
                case .fill: .scaleAspectFill
                case .fit: .scaleAspectFit
            }
            self.radius = radius.map(CGFloat.init)
        }

        // MARK: - Functions

        func apply(on image: InAppImageView) {
            image.isUserInteractionEnabled = true
            image.clipsToBounds = true
            image.layer.masksToBounds = true
            image.contentMode = aspect
        }
    }

    struct Action: InAppCTAComponent {
        // MARK: - Initializer

        let analyticsIdentifier: String
        let action: BAMSGAction?
        let type: InAppCTAType = .image
    }

    struct Accessibility {
        // MARK: - Parameters

        let label: String?

        // MARK: - Functions

        func apply(on image: InAppImageView) {
            image.accessibilityLabel = label
            image.accessibilityIgnoresInvertColors = true
        }
    }
}

// MARK: - GIF Animator delegate methods

extension InAppImageView: BATGIFAnimatorDelegate {
    func animator(_: BATGIFAnimator, needsToDisplay image: UIImage) {
        self.image = image
    }
}

extension InAppImageView {
    func load(url: URL) {
        showLoadingOverlay()
        BAMSGImageDownloader.downloadImage(
            for: url,
            downloadTimeout: configuration.timeout
        ) { [weak self] data, isGif, image, error in
            self?.hideLoadingOverlay()

            if let error {
                self?.onError(error, .image)

                return
            }

            if isGif {
                self?.loadGif(data: data)
            } else {
                self?.loadImage(loadedImage: image)
            }
        }
    }

    func loadImage(loadedImage: UIImage?) {
        BAThreading.performBlock(onMainThreadAsync: { [weak self] in
            guard let self else { return }

            image = loadedImage

            if let loadedImage {
                NSLayoutConstraint.activate([
                    heightAnchor.constraint(equalToConstant: (frame.width / loadedImage.size.width) * loadedImage.size.height),
                ])
            }
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
