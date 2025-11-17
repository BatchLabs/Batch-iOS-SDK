//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app rounded container
/// Override style for modal format and regular horizontalSizeClass
class InAppRoundedContainer<T: InAppRoundableCorners & InAppBorderable>: UIView {
    // MARK: -

    let style: T
    private let regularStyle = InAppRoundedContainerIpadStyle(radius: [8, 8, 8, 8])
    let format: InAppFormat

    // MARK: -

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        layoutStyle()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layoutStyle()
    }

    func layoutStyle() {
        let styleToUse: any InAppRoundableCorners & InAppBorderable =
            if traitCollection.horizontalSizeClass != .compact, format == .modal {
                regularStyle
            } else {
                style
            }

        // Corners
        let path = styleToUse.layoutRoundedCorners(on: self)

        // Borders
        styleToUse.layoutBorders(on: self, with: path)
    }

    // MARK: -

    init(style: T, format: InAppFormat) {
        self.style = style
        self.format = format

        super.init(frame: .zero)

        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct InAppRoundedContainerIpadStyle: InAppRoundableCorners, InAppBorderable {
    let radius: [CGFloat]
    let borderWidth: CGFloat? = nil
    let borderColor: UIColor? = nil
}
