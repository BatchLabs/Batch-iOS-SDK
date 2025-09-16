//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// In app modal view controller
/// Inspired by ``BAMSGModalViewController``
class InAppModalViewController: InAppBaseBannerViewController {
    // MARK: -

    override var shouldDisplayInSeparateWindow: Bool { false }

    // MARK: -

    override init(configuration: InAppViewController.Configuration) {
        super.init(configuration: configuration)

        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    override func loadView() {
        super.loadView()

        view.backgroundColor = .black.withAlphaComponent(0.5)
    }
}
