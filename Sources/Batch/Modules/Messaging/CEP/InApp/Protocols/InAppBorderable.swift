//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Define style to border view
/// Will be use to generalize apply on views
protocol InAppBorderable {
    var borderWidth: CGFloat? { get }
    var borderColor: UIColor? { get }
}

/// Extend ``InAppBorderable``protocol to centralize the method
extension InAppBorderable {
    func layoutBorders(on view: UIView, with cgPath: CGPath) {
        // Border for Mask
        if let borderWidth, let borderColor {
            // Remove previous border if redraw
            view.layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })

            let borderLayer = CAShapeLayer()
            borderLayer.path = cgPath
            borderLayer.lineWidth = borderWidth
            borderLayer.strokeColor = borderColor.cgColor
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.frame = view.bounds
            view.layer.addSublayer(borderLayer)
        }
    }
}
