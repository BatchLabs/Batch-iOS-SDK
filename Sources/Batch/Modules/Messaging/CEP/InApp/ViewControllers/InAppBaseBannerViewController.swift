//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// In app banner view controller
/// Inspired by ``BAMSGBaseBannerViewController``
class InAppBaseBannerViewController: InAppViewController,
    BatchMessagingViewController,
    BAMSGPannableContainerViewDelegate,
    BAMSGWindowHolder
{
    // MARK: -

    var presentingWindow: UIWindow?
    var overlayedWindow: UIWindow?

    // MARK: -

    var shouldDisplayInSeparateWindow: Bool { true }
    override var prefersStatusBarHidden: Bool { false }

    // MARK: -

    override init(configuration: InAppViewController.Configuration, message: BAMSGCEPMessage) {
        super.init(configuration: configuration, message: message)

        modalPresentationStyle = .overFullScreen
    }

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeContentView() -> UIView {
        let contentView = PannableAlertContainerView()
        contentView.shadowColor = .black
        contentView.shadowRadius = 15
        contentView.shadowOpacity = 0.3
        contentView.touchPassthrough = false

        // TODO: Will be rework later for a better integration of anchor content
        contentView.scrollableContentView = scrollableViewContent
        contentView.delegate = self

        return contentView
    }

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            try setupViewContents()
        } catch {
            BALogger.error(domain: String(describing: Self.self), message: error.localizedDescription)
            _ = doDismiss()
        }
    }

    override func loadView() {
        let pannableAlertContainerView = PannableAlertContainerView()
        pannableAlertContainerView.delegate = self
        pannableAlertContainerView.touchPassthrough = true

        view = pannableAlertContainerView
    }

    // MARK: -

    func setupViewContents() throws {
        view.isOpaque = false

        let contentView = makeContentView()

        if let view = view as? BAMSGPannableAnchoredContainerView {
            view.biggestUserVisibleView = contentView
        }

        try setupViewContent(contentView: contentView)
        if configuration.shouldOverleapSafeArea(size: traitCollection.horizontalSizeClass) {
            setupCountdownView(in: overleapSafeAreaView, withSafeArea: false)
        } else {
            setupCountdownView(in: scrollableViewContent, withSafeArea: true)
        }
        setupCloseButton(in: scrollableViewContent)
    }

    // MARK: -

    func pannableContainerWasDismissed(_: BAMSGBaseContainerView) {
        dismiss()
    }

    func adaptivePresentationStyle(for _: UIPresentationController, traitCollection _: UITraitCollection) -> UIModalPresentationStyle {
        return self.modalPresentationStyle
    }

    // MARK: -

    override func doDismiss() -> BAPromise<NSObject> {
        if let presentingWindow {
            return BAMessagingCenter.instance().dismiss(presentingWindow as? BAMSGOverlayWindow)
        } else {
            return doDismissSelfModal()
        }
    }
}
