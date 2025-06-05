//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Define radius to round corner
/// Will be use to generalize apply on views
protocol InAppRoundableCorners {
    var radius: [CGFloat] { get }
}

/// Extend ``InAppRoundableCorners``protocol to centralize the method
extension InAppRoundableCorners {
    @discardableResult
    func layoutRoundedCorners(on view: UIView) -> CGPath {
        // Corners
        let mask = CAShapeLayer()
        let cgPath = InAppRoundedCornersPathBuilder(
            tl: radius[edge: .topLeft],
            tr: radius[edge: .topRight],
            bl: radius[edge: .bottomLeft],
            br: radius[edge: .bottomRight]
        ).build(in: view.frame).cgPath
        mask.path = cgPath
        view.layer.mask = mask

        return cgPath
    }
}

/// Ease the get of edge radius
fileprivate extension Collection<Int> {
    subscript(edge value: InAppRadiusIndexHelper) -> CGFloat {
        self.map(CGFloat.init)[edge: value]
    }
}

/// Ease the get of edge inset
fileprivate extension Collection<CGFloat> {
    subscript(edge value: InAppRadiusIndexHelper) -> CGFloat {
        let index = index(startIndex, offsetBy: value.rawValue)
        return indices.contains(index) ? self[index] : 0
    }
}
