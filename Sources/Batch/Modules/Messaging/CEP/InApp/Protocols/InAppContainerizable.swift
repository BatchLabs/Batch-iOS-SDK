//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Will define all rules to correctly display an element into ``InAppContainer``
protocol InAppContainerizable {
    var heightType: InAppHeightType? { get }
    var widthType: InAppWidthType? { get }
    var margins: UIEdgeInsets { get }
    var paddings: UIEdgeInsets { get }
    var verticalAlignment: InAppVerticalAlignment? { get }
    var horizontalAlignment: InAppHorizontalAlignment? { get }
}

/// Each object may have different rules, it's defined default value for every one
extension InAppContainerizable {
    var heightType: InAppHeightType? { nil }
    var widthType: InAppWidthType? { nil }
    var margins: UIEdgeInsets { .zero }
    var paddings: UIEdgeInsets { .zero }
    var verticalAlignment: InAppVerticalAlignment? { nil }
    var horizontalAlignment: InAppHorizontalAlignment? { nil }
}
