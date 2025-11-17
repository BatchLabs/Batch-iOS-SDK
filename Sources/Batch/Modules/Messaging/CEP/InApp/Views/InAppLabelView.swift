//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Represents an in-app label view
class InAppLabelView: UILabel {
    // MARK: -

    let configuration: InAppLabelView.Configuration

    // MARK: -

    init(configuration: InAppLabelView.Configuration) {
        self.configuration = configuration

        super.init(frame: .zero)

        configure()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    func configure() {
        configuration.apply(to: self)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: configuration.placement.paddings))
    }

    override var bounds: CGRect {
        didSet {
            // Substract the padding from the asked width, so that iOS correctly reflows the text if needed
            let targetWidth = bounds.width - (configuration.placement.paddings.left + configuration.placement.paddings.right)
            if preferredMaxLayoutWidth != targetWidth {
                preferredMaxLayoutWidth = targetWidth
                setNeedsUpdateConstraints()
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize

        size.width = size.width + configuration.placement.paddings.left + configuration.placement.paddings.right
        size.height = size.height + configuration.placement.paddings.top + configuration.placement.paddings.bottom

        return size
    }
}

extension InAppLabelView {
    struct Configuration {
        // MARK: -

        let content: Content
        let fontStyle: FontStyle
        let style: Style
        let placement: Placement

        // MARK: -

        func apply(to label: InAppLabelView) {
            style.apply(on: label)
            fontStyle.apply(on: label)
            content.apply(on: label, fontStyle: fontStyle)
        }
    }
}

extension InAppLabelView.Configuration {
    struct Placement: InAppContainerizable {
        // MARK: -

        public let margins: UIEdgeInsets
        let horizontalAlignment: InAppHorizontalAlignment? = .left
        let verticalAlignment: InAppVerticalAlignment? = .top
    }

    struct FontStyle: InAppFontStylizable, InAppFontDecorationStylizable {
        // MARK: -

        let fontSize: Int?
        let fontDecoration: [InAppFontDecoration]?

        // MARK: -

        func apply(on _: InAppLabelView) {}
    }

    struct Style {
        // MARK: -

        let textAlign: NSTextAlignment
        let color: UIColor
        let maxLines: Int

        // MARK: -

        public init(
            textAlign: InAppHorizontalAlignment,
            color: UIColor,
            maxLines: Int
        ) {
            self.textAlign =
                switch textAlign {
                case .left: .left
                case .center: .center
                case .right: .right
                }
            self.color = color
            self.maxLines = maxLines
        }

        // MARK: -

        func apply(on label: InAppLabelView) {
            label.textColor = color
            label.lineBreakMode = .byTruncatingTail
            label.numberOfLines = maxLines
            label.textAlignment = textAlign
            label.adjustsFontForContentSizeCategory = BAMessagingCenter.instance().enableDynamicType

            if #available(iOS 15.0, *) {
                label.maximumContentSizeCategory = UIContentSizeCategory.extraExtraExtraLarge
            }
        }
    }

    struct Content {
        // MARK: -

        let text: String

        // MARK: -

        func apply(on label: InAppLabelView, fontStyle: InAppFontStylizable & InAppFontDecorationStylizable) {
            let attributedString = (try? InAppFontStyleBuilder.attributedString(text: text, fontStyle: fontStyle, labelFont: label.font)) ?? NSAttributedString(string: text)
            label.attributedText = attributedString
            label.accessibilityLabel = attributedString.string
        }
    }
}
