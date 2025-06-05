//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// In app fullscreen view controller
/// Inspired by ``BAMSGInterstitialViewController``
class InAppFullscreenViewController: InAppViewController,
    BatchMessagingViewController,
    UIAdaptivePresentationControllerDelegate, InAppRoundableCorners
{
    let radius: [CGFloat] = [8, 8, 8, 8]

    // MARK: -

    var shouldDisplayInSeparateWindow: Bool { false }

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

    // MARK: -

    override func loadView() {
        view = BAMSGGradientView()
        view.backgroundColor = configuration.style.backgroundColor
    }

    // MARK: - Functions

    func setupViewContents() throws {
        view.isOpaque = false
        view.alpha = 1

        try setupViewContent(contentView: BAMSGGradientView())

        setupCountdownView(in: view, withSafeArea: true)
        setupCloseButton(in: view)
    }

    // MARK: -

    func pannableContainerWasDismissed(_: BAMSGBaseContainerView) {
        dismiss()
    }

    func adaptivePresentationStyle(for _: UIPresentationController, traitCollection _: UITraitCollection) -> UIModalPresentationStyle {
        return modalPresentationStyle
    }

    func presentationControllerDidDismiss(_: UIPresentationController) {
        userDidCloseMessage()
    }

    // MARK: -

    override func doDismiss() -> BAPromise<NSObject> {
        doDismissSelfModal()
    }
}
