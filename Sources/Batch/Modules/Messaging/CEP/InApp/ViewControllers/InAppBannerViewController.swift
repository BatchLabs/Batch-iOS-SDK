//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// In app banner view controller
/// Inspired by ``BAMSGBannerViewController``
class InAppBannerViewController: InAppBaseBannerViewController {
    // MARK: -

    override init(configuration: InAppViewController.Configuration) {
        super.init(configuration: configuration)
    }

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
