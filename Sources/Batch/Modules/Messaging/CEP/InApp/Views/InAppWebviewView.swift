//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit
import WebKit

/// Represents an in-app webview view
class InAppWebviewView: WKWebView, InAppErrorDelegate {
    // MARK: -

    let webviewConfiguration: InAppWebviewView.Configuration
    let onError: InAppErrorDelegate.Closure

    // MARK: -

    init(
        configuration: InAppWebviewView.Configuration,
        onError: @escaping InAppErrorDelegate.Closure
    ) {
        self.webviewConfiguration = configuration
        self.onError = onError

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = [.audio]

        super.init(frame: .zero, configuration: webConfiguration)

        configure()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setNeedsDisplay()
    }

    // MARK: -

    private func setupWebView() {
        if #available(iOS 16.4, *) {
            isInspectable = true
        }

        clipsToBounds = true
        isOpaque = false
        backgroundColor = .clear
        alpha = 0  // Hidden until loaded
        allowsBackForwardNavigationGestures = false
        scrollView.alwaysBounceVertical = false
        scrollView.bounces = false
    }

    func configure() {
        setupWebView()

        webviewConfiguration.apply(to: self)

        loadWebContent()
    }

    private func loadWebContent() {
        var request = URLRequest(url: webviewConfiguration.content.url, timeoutInterval: TimeInterval(webviewConfiguration.timeout))

        // Disable cache in dev mode
        if webviewConfiguration.devMode {
            request.cachePolicy = .reloadIgnoringCacheData
        }

        load(request)
    }
}

extension InAppWebviewView {
    struct Placement: InAppContainerizable {
        let heightType: InAppHeightType = .fill
        let verticalAlignment: InAppVerticalAlignment = .top
        let horizontalAlignment: InAppHorizontalAlignment = .left
    }

    struct Configuration {
        // MARK: -

        let content: Content
        let placement: Placement = .init()
        let inAppDeeplinks: Bool
        let devMode: Bool
        let timeout: TimeInterval

        // MARK: -

        func apply(to _: InAppWebviewView) {
            // Nothing to do
        }
    }
}

extension InAppWebviewView.Configuration {
    struct Content {
        // MARK: -

        let url: URL
    }
}
