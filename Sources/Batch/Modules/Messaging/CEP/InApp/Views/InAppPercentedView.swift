//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Must only be used in ``InAppColumns`` and ``InAppColumnsViewTests``
/// Represents the ration than the user could set for each column
class InAppPercentedView: UIView {
    // MARK: -

    let percent: CGFloat

    // MARK: -

    override var intrinsicContentSize: CGSize {
        return CGSize(width: percent, height: -1)
    }

    // MARK: -

    init(percent: CGFloat) {
        self.percent = percent

        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
