//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Represents an in-app divider view
class InAppDividerView: UIView {
    // MARK: -

    let configuration: InAppDividerView.Configuration

    // MARK: -

    init(configuration: Configuration) {
        self.configuration = configuration

        super.init(frame: .zero)

        configure()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        if case let .fixed(value) = configuration.placement.heightType {
            layer.cornerRadius = CGFloat(value / 2)
        }
    }

    // MARK: -

    func configure() {
        configuration.apply(to: self)
    }
}

extension InAppDividerView {
    struct Configuration {
        // MARK: -

        let style: Style
        let placement: Placement

        // MARK: -

        func apply(to divider: InAppDividerView) {
            style.apply(on: divider)
        }
    }
}

extension InAppDividerView.Configuration {
    struct Style {
        // MARK: -

        let color: UIColor

        // MARK: -

        func apply(on divider: InAppDividerView) {
            divider.backgroundColor = color
        }
    }

    struct Placement: InAppContainerizable {
        // MARK: -

        let margins: UIEdgeInsets
        let widthType: InAppWidthType?
        let heightType: InAppHeightType?
        let horizontalAlignment: InAppHorizontalAlignment?
    }
}
