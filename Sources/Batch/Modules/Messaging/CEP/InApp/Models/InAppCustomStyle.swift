//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

extension InAppViewController {
    /// Represents a custom style to handle overleap safe area as MEP
    /// Should only be used in ``InAppViewController``
    struct InAppCustomStyle: InAppBorderable & InAppRoundableCorners {
        let borderWidth: CGFloat?
        let borderColor: UIColor?
        let radius: [CGFloat]

        init(borderWidth: CGFloat?, borderColor: UIColor?, radius: [CGFloat]) {
            self.borderWidth = borderWidth
            self.borderColor = borderColor
            self.radius = radius
        }

        static func empty() -> Self {
            Self(
                borderWidth: nil,
                borderColor: nil,
                radius: []
            )
        }
    }
}

extension InAppViewController.Configuration {
    func customStyle() -> InAppViewController.InAppCustomStyle {
        return InAppViewController.InAppCustomStyle(
            borderWidth: style.borderWidth,
            borderColor: style.borderColor,
            radius: style.radius
        )
    }
}
