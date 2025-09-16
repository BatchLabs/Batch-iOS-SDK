//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Represents an in-app spacer view
class InAppSpacerView: UIView {
    // MARK: -

    let configuration: InAppSpacerView.Configuration

    // MARK: -

    init(configuration: Configuration) {
        self.configuration = configuration

        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InAppSpacerView {
    struct Configuration {
        // MARK: -

        let placement: Placement
    }
}

extension InAppSpacerView.Configuration {
    struct Placement: InAppContainerizable {
        // MARK: -

        let widthType: InAppWidthType? = .percent(value: 100)
        let verticalAlignment: InAppVerticalAlignment? = .top
        let heightType: InAppHeightType?
    }
}
