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
        let cgPath = InAppRoundedCornersPathBuilder(
            tl: radius[edge: .topLeft],
            tr: radius[edge: .topRight],
            bl: radius[edge: .bottomLeft],
            br: radius[edge: .bottomRight]
        )
        .build(in: view.frame).cgPath

        // Reuse the existing mask layer and only update its path, instead of swapping in a brand new
        // layer. Keeping the same layer lets a rotation explicitly animate its `path` from the old to
        // the new shape (see InAppViewController.viewWillTransition), so the corners track the animated
        // bounds change. The model path itself is set without an implicit animation so it stays in sync
        // outside of that explicit morph.
        let mask = (view.layer.mask as? CAShapeLayer) ?? CAShapeLayer()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mask.path = cgPath
        if view.layer.mask !== mask {
            view.layer.mask = mask
        }
        CATransaction.commit()

        return cgPath
    }
}

/// Ease the get of edge radius
extension Collection<Int> {
    fileprivate subscript(edge value: InAppRadiusIndexHelper) -> CGFloat {
        self.map(CGFloat.init)[edge: value]
    }
}

/// Ease the get of edge inset
extension Collection<CGFloat> {
    fileprivate subscript(edge value: InAppRadiusIndexHelper) -> CGFloat {
        let index = index(startIndex, offsetBy: value.rawValue)
        return indices.contains(index) ? self[index] : 0
    }
}
