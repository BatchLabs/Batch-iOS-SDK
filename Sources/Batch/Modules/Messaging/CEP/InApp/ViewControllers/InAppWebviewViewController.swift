//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit
import WebKit

// MARK: - Constants

private let webviewDevMenuTitle = "Development menu"
private let webviewDevMenuReload = "Reload"

/// In-app webview view controller for displaying web content.
/// Inspired by `BAMSGWebviewViewController`.
/// Conforms to BAMSGWindowHolder to support window-based presentation for better webview management.
///
/// This implementation supports the Mobile Landing v2 (CEP) format as described in the RFC, including:
/// - JavaScript bridge support for webview communication with the Batch SDK
/// - Analytics tracking for webview interactions using the new CTA identifier format
/// - Backwards compatibility with MEP format analytics
/// - Error handling and logging as specified in the RFC
class InAppWebviewViewController:
    InAppFullscreenViewController,
    BAMSGWindowHolder,
    BATWebviewJavascriptBridgeDelegate,
    BATWebviewBridgeLegacyWKHandlerWebViewSource
{
    /// Window used for presenting the webview controller when displayed in a separate window.
    var presentingWindow: UIWindow?
    /// Optional overlayed window for additional UI elements.
    var overlayedWindow: UIWindow?

    // MARK: - Properties

    var isDevMode: Bool

    // Loading indicator shown while webview is loading
    private var loaderView: UIActivityIndicatorView!

    /// Override for navigation errors
    private var nextNavigationErrorOverride: Error?

    /// JavaScript bridge for handling webview communication
    private var bridge: BATWebviewJavascriptBridge?

    var webView: WKWebView? {
        guard configuration.builder.viewsBuilder.first(where: { $0.component.type == .webview }) != nil else { return nil }

        return view.findFirstSubview(ofType: WKWebView.self)
    }

    /// Enables safe area handling for the countdown view in webview presentations.
    override var setupCountdownViewIfNeededWithSafeArea: Bool { true }

    // MARK: - Initialization

    /// Initializes the webview controller with configuration and message data.
    /// - Parameters:
    ///   - configuration: The configuration for the message's appearance and behavior.
    ///   - message: The raw campaign message data used for analytics.
    override init(configuration: Configuration) {
        self.isDevMode = (configuration.builder.viewsBuilder.first(where: { $0.component.type == .webview })?.component as? InAppWebview)?.devMode ?? false
        super.init(configuration: configuration)

        self.modalPresentationStyle = .overCurrentContext

        nextNavigationErrorOverride = nil

        bridge = BATWebviewJavascriptBridge(message: configuration.content.message, delegate: self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupActivityIndicator()
        setupConstraints()
        setupWebviewSettings()
        setupDevModeInteraction()
    }

    // MARK: - Setup Methods

    private func setupDevModeInteraction() {
        // On dev mode we want to add actions on long pressing close
        if isDevMode {
            // Use UILongPressGestureRecognizer instead of UIContextMenuInteraction
            // to avoid the white background animation from _UIPlatterTransformView
            closeButton?.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressCloseButton)))
        }
    }

    private func setupActivityIndicator() {
        loaderView = UIActivityIndicatorView(style: .large)
        loaderView.translatesAutoresizingMaskIntoConstraints = false
        loaderView.hidesWhenStopped = true
        loaderView.startAnimating()

        view.addSubview(loaderView)
    }

    private func setupConstraints() {
        // Center the loader view
        NSLayoutConstraint.activate([
            loaderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loaderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func setupWebviewSettings() {
        webView?.navigationDelegate = self
        webView?.uiDelegate = self

        // Configure JavaScript bridge handlers for communication with webview content
        guard let webView, let bridge else {
            BALogger.debug(domain: String(describing: Self.self), message: "Webview or bridge not available for JavaScript bridge setup")
            return
        }

        let userContentController = webView.configuration.userContentController

        // Use the modern script message handler for iOS 14+
        userContentController.addScriptMessageHandler(BATWebviewBridgeWKHandler(bridge: bridge), contentWorld: WKContentWorld.page, name: "batchBridge")
        BALogger.debug(domain: String(describing: Self.self), message: "JavaScript bridge configured successfully")
    }

    private func reloadWebView() {
        loadWebviewWithCacheEnabled(false)
    }

    private func loadWebviewWithCacheEnabled(_ cacheEnabled: Bool) {
        guard let webView,
            let webviewComponent = configuration.builder.viewsBuilder.first(where: { $0.component.type == .webview })?.component as? InAppWebview,
            let url = (webView as? InAppWebviewView)?.webviewConfiguration.content.url
        else {
            BALogger.debug(domain: String(describing: Self.self), message: "Webview component not found for reload")
            return
        }

        let request = NSMutableURLRequest(url: url)
        if webviewComponent.timeout > 0 {
            request.timeoutInterval = webviewComponent.timeout
        }

        // Add custom headers if needed
        let region = BatchUser.region()
        if !region.isEmpty {
            request.addValue(region, forHTTPHeaderField: "X-Batch-Custom-Region")
        }
        let language = BatchUser.language()
        if !language.isEmpty {
            request.addValue(language, forHTTPHeaderField: "X-Batch-Custom-Language")
        }
        if !cacheEnabled {
            request.cachePolicy = .reloadIgnoringCacheData
        }
        loaderView.startAnimating()
        webView.alpha = 0.0

        webView.load(request as URLRequest)
    }

    /// Overrides the base dismissal to handle window-based presentation.
    /// Uses BAMessagingCenter for window dismissal when presented in a separate window,
    /// otherwise falls back to standard modal dismissal.
    override func doDismiss() -> BAPromise<NSObject> {
        if let presentingWindow {
            return BAMessagingCenter.instance().dismiss(presentingWindow as? BAMSGOverlayWindow)
        } else {
            return doDismissSelfModal()
        }
    }

    // MARK: - Development Menu

    /// Handles long press gesture on close button to display development menu
    /// Uses UIAlertController instead of UIContextMenuInteraction to avoid
    /// the white background animation issue from _UIPlatterTransformView
    @objc
    func handleLongPressCloseButton(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let alert = UIAlertController(title: webviewDevMenuTitle, message: nil, preferredStyle: .actionSheet)

        let reloadAction = UIAlertAction(title: webviewDevMenuReload, style: .default) { [weak self] _ in
            self?.reloadWebView()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(reloadAction)
        alert.addAction(cancelAction)

        // Configure popover presentation for iPad compatibility
        if let popover = alert.popoverPresentationController {
            popover.sourceView = closeButton
            popover.sourceRect = closeButton?.bounds ?? .zero
        }

        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension InAppWebviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        loaderView.stopAnimating()
        webView.alpha = 1.0
    }

    func webView(_ webView: WKWebView, didCommit _: WKNavigation!) {
        webView.setNeedsLayout()
        webView.alpha = 1.0
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var shouldOverrideHandling = false

        // Do not handle iframe requests
        if navigationAction.targetFrame?.isMainFrame == true {
            if let targetURL = navigationAction.request.url {
                let scheme = targetURL.scheme?.lowercased()
                let host = targetURL.host?.lowercased()

                // WKWebView disallows navigation to anything else than http/https by default
                // Override this, and handle those links ourselves
                if let scheme, scheme != "https", scheme != "http" {
                    shouldOverrideHandling = true
                }

                // Special case for iTunes and App Store links
                if let host, host == "itunes.apple.com" || host == "apps.apple.com" {
                    shouldOverrideHandling = true
                }

                if shouldOverrideHandling {
                    decisionHandler(.cancel)
                    // Handle external links (simplified for now)
                    if UIApplication.shared.canOpenURL(targetURL) {
                        UIApplication.shared.open(targetURL)
                    }
                    return
                }
            }
        }

        decisionHandler(.allow)
    }

    func webView(_: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard navigationResponse.isForMainFrame,
            let httpResponse = navigationResponse.response as? HTTPURLResponse
        else {
            decisionHandler(.allow)
            return
        }

        let statusCode = httpResponse.statusCode

        if statusCode == 310 || statusCode >= 400 {
            decisionHandler(.cancel)
            nextNavigationErrorOverride = NSError(
                domain: "WebViewError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "HTTP Error Code \(statusCode)"]
            )
        } else {
            decisionHandler(.allow)
        }
    }

    private func handleNavigationError(_ error: Error) {
        // Ignoring iOS-specific WebKit error PlugInLoadFailed
        if (error as NSError).code == 204 {
            return
        }

        let finalError = nextNavigationErrorOverride ?? error
        nextNavigationErrorOverride = nil

        if isDevMode == true {
            let errorMessage = "The WebView encountered an error and will be closed.\nThis error will only be shown during development.\n\nCause: \(finalError.localizedDescription)"
            showDevelopmentError(errorMessage, sourceError: finalError)
        } else {
            closeAfterError(finalError)
        }
    }

    func webViewWebContentProcessDidTerminate(_: WKWebView) {
        if isDevMode {
            showDevelopmentError("The WebView crashed and will be closed.\nThis error will only be shown during development.", sourceError: nil)
        } else {
            closeAfterError(nil)
        }
    }

    // MARK: - Helper Methods

    private func showDevelopmentError(_ errorMessage: String, sourceError: Error?) {
        let alert = UIAlertController(title: "WebView Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: .cancel) { _ in
                self.closeAfterError(sourceError)
            }
        )
        present(alert, animated: true)
    }

    private func closeAfterError(_ error: Error?) {
        if let error {
            BALogger.error(domain: String(describing: Self.self), message: "WebView closed due to error: \(error.localizedDescription)")
            // Track close error for analytics
            let closeError = BATMessagingCloseErrorHelper.guessErrorCause(forError: error)
            analyticManager.track(.closeError(closeError))
        }

        dismiss()
    }
}

// MARK: - WKUIDelegate

extension InAppWebviewViewController: WKUIDelegate {
    func webView(_: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame _: WKFrameInfo, completionHandler: @escaping () -> Void) {
        guard !isDismissed else {
            completionHandler()
            return
        }

        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: .cancel) { _ in
                completionHandler()
            }
        )
        present(alert, animated: true)
    }

    func webView(_: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame _: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        guard !isDismissed else {
            completionHandler(false)
            return
        }

        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(true)
            }
        )
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            }
        )
        present(alert, animated: true)
    }

    func webView(_: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame _: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        guard !isDismissed else {
            completionHandler(defaultText)
            return
        }

        let alert = UIAlertController(title: prompt, message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }

        alert.addAction(
            UIAlertAction(title: "OK", style: .default) { _ in
                let text = alert.textFields?.first?.text
                completionHandler(text)
            }
        )

        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(nil)
            }
        )

        present(alert, animated: true)
    }

    func webView(_: WKWebView, createWebViewWith _: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures _: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            if let targetURL = navigationAction.request.url {
                openDeeplink(url: targetURL.absoluteString, openInAppOverride: nil, analyticsID: nil)
            } else {
                BALogger.error(domain: String(describing: Self.self), message: "Could not open target=_blank link: no target URL")
            }
        }
        return nil
    }

    func webViewDidClose(_: WKWebView) {
        dismiss()
    }
}

// MARK: - BATWebviewJavascriptBridgeDelegate

extension InAppWebviewViewController {
    func bridge(_: BATWebviewJavascriptBridge, shouldDismissMessageWithAnalyticsID analyticsIdentifier: String?) {
        dismissWithAnalyticsID(analyticsIdentifier)
    }

    func bridge(_: BATWebviewJavascriptBridge, shouldOpenDeeplink url: String, openInAppOverride: NSNumber?, analyticsID analyticsIdentifier: String?) {
        openDeeplink(url: url, openInAppOverride: openInAppOverride, analyticsID: analyticsIdentifier)
    }

    func bridge(_: BATWebviewJavascriptBridge, shouldPerformAction action: String, arguments: [String: Any], analyticsID analyticsIdentifier: String?) {
        do {
            try performAction(actionIdentifier: action, arguments: arguments, analyticsID: analyticsIdentifier)
        } catch {
            BALogger.debug(domain: String(describing: Self.self), message: error.description)
        }
    }
}

// MARK: - BATWebviewBridgeLegacyWKHandlerWebViewSource

extension InAppWebviewViewController {
    func backingWebView(forLegacyHandler _: BATWebviewBridgeLegacyWKHandler) -> WKWebView? { webView }
}

// MARK: - Bridge Action Handlers

extension InAppWebviewViewController {
    enum InternalError: Error {
        case actionWithUnsupportedParameters(name: String, key: String)

        var description: String {
            return switch self {
            case let .actionWithUnsupportedParameters(name, key):
                "Action (\(name)) with unsupported parameters for key: \(key)"
            }
        }
    }

    private func dismissWithAnalyticsID(_ analyticsID: String?) {
        do {
            try performAction(actionIdentifier: "batch.dismiss", arguments: [:], analyticsID: analyticsID)
        } catch {
            BALogger.debug(domain: String(describing: Self.self), message: error.description)
        }
    }

    private func openDeeplink(url: String, openInAppOverride: NSNumber?, analyticsID analyticsIdentifier: String?) {
        var analyticsID = analyticsIdentifier

        // If there is no explicit analyticsIdentifier, try to extract it from the URL
        if analyticsID?.isEmpty != false {
            analyticsID = BATWebviewUtils.analyticsId(forURL: url)
        }

        let deeplinkArgs: [String: Any] = [
            "l": url,
            "li": NSNumber(value: openInAppOverride?.boolValue ?? (webView as? InAppWebviewView)?.webviewConfiguration.inAppDeeplinks ?? true),
        ]

        do {
            try performAction(actionIdentifier: "batch.deeplink", arguments: deeplinkArgs, analyticsID: analyticsID)
        } catch {
            BALogger.debug(domain: String(describing: Self.self), message: error.description)
        }
    }

    private func performAction(actionIdentifier: String, arguments: [String: Any], analyticsID analyticsIdentifier: String?) throws(InternalError) {
        let action = BAMSGAction()
        action.actionIdentifier = actionIdentifier

        var args: [String: NSObject] = [:]
        for row in arguments {
            if let value = row.value as? NSObject {
                args[row.key] = value
            } else {
                throw InternalError.actionWithUnsupportedParameters(name: actionIdentifier, key: row.key)
            }
        }

        action.actionArguments = args

        // Sanitize analyticsIdentifier
        var sanitizedAnalyticsID = analyticsIdentifier
        if let id = analyticsIdentifier, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if id.count > 30 {
                BALogger.public(
                    domain: "Messaging",
                    message:
                        "Could not track webview event: The analytics ID is invalid: it should be 30 characters or less. The action will be tracked without an analytics ID, but will still be performed."
                )
                sanitizedAnalyticsID = nil
            }
        } else {
            sanitizedAnalyticsID = nil
        }

        // Create a webview CTA component for analytics
        let component = WebviewCTAComponent(
            analyticsIdentifier: sanitizedAnalyticsID ?? "",
            action: action
        )

        // Track webview click using the new analytics format
        analyticManager.track(.webView(component: component))

        dismiss()
            .then { [configuration = self.configuration] _ in
                if let action = component.action {
                    BAMessagingCenter.instance()
                        .perform(
                            action,
                            source: configuration.content.message.sourceMessage,
                            ctaIdentifier: component.analyticsIdentifier,
                            messageIdentifier: configuration.content.message.sourceMessage.devTrackingIdentifier
                        )
                }
            }
    }
}

extension UIView {
    /// Recursively finds the first subview of a specified type in the view hierarchy.
    ///
    /// - Parameter type: The type of the subview to find.
    /// - Returns: The first subview of the specified type found, or `nil` if none exists.
    fileprivate func findFirstSubview<T: UIView>(ofType type: T.Type) -> T? {
        // Check if the current view is of the desired type
        if let webView = self as? T {
            return webView
        }

        // Recursively search in the subviews
        for subview in subviews {
            if let foundWebView = subview.findFirstSubview(ofType: type) {
                return foundWebView
            }
        }

        return nil
    }
}
