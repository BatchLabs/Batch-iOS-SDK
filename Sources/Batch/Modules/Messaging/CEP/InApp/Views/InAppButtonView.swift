//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Represents an in-app button view
class InAppButtonView: UIButton, InAppClosureDelegate {
    // MARK: -

    let baConfiguration: InAppButtonView.Configuration
    let onClosureTap: InAppClosureDelegate.Closure

    lazy var pressedOverlay: UIView = {
        let pressedOverlay = UIView(frame: .zero)
        pressedOverlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        pressedOverlay.isUserInteractionEnabled = false
        pressedOverlay.isHidden = true
        pressedOverlay.isExclusiveTouch = false
        pressedOverlay.translatesAutoresizingMaskIntoConstraints = false

        return pressedOverlay
    }()

    // MARK: -

    init(
        configuration: InAppButtonView.Configuration,
        onClosureTap: @escaping InAppClosureDelegate.Closure
    ) {
        self.baConfiguration = configuration
        self.onClosureTap = onClosureTap

        super.init(frame: .zero)

        configure()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setNeedsDisplay()
    }

    // MARK: -

    var _lastKnownFrame: CGRect = CGRectZero

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        if _lastKnownFrame != rect {
            _lastKnownFrame = rect

            // Corners
            let path = baConfiguration.style.layoutRoundedCorners(on: self)
            // Borders
            baConfiguration.style.layoutBorders(on: self, with: path)

            // Highlighted
            pressedOverlay.frame = bounds
        }
    }

    override var bounds: CGRect {
        didSet {
            let targetWidth = bounds.width - (baConfiguration.placement.paddings.left + baConfiguration.placement.paddings.right)
            if titleLabel?.preferredMaxLayoutWidth != targetWidth {
                titleLabel?.preferredMaxLayoutWidth = targetWidth
                setNeedsUpdateConstraints()
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        var size = titleLabel?.intrinsicContentSize ?? super.intrinsicContentSize
        size.width = size.width + baConfiguration.placement.paddings.left + baConfiguration.placement.paddings.right
        size.height = size.height + baConfiguration.placement.paddings.top + baConfiguration.placement.paddings.bottom

        return size
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: .transitionCrossDissolve,
                animations: { [weak self] in
                    guard let self else { return }

                    pressedOverlay.isHidden = !isHighlighted
                },
                completion: { [weak self] _ in
                    guard let self else { return }

                    if isHighlighted {
                        bringSubviewToFront(pressedOverlay)
                    }
                }
            )
        }
    }

    // MARK: -

    func configure() {
        baConfiguration.apply(to: self)

        addTarget(self, action: #selector(onTap), for: .touchUpInside)

        // Hightlight
        addSubview(pressedOverlay)
    }

    @objc func onTap() {
        onClosureTap(baConfiguration.action, nil)
    }
}

extension InAppButtonView {
    struct Configuration {
        // MARK: -

        let content: Content
        let fontStyle: FontStyle
        let style: Style
        let placement: Placement
        let action: Action?

        // MARK: -

        func apply(to button: InAppButtonView) {
            style.apply(on: button)
            fontStyle.apply(on: button)
            content.apply(on: button, fontStyle: fontStyle)
            placement.apply(on: button)
        }
    }
}

extension InAppButtonView.Configuration {
    struct FontStyle: InAppFontStylizable, InAppFontDecorationStylizable {
        // MARK: -

        let fontSize: Int?
        let fontDecoration: [InAppFontDecoration]?

        // MARK: -

        init(
            fontSize: Int,
            fontDecoration: [InAppFontDecoration]?
        ) {
            self.fontSize = fontSize
            self.fontDecoration = fontDecoration
        }

        // MARK: -

        func apply(on _: InAppButtonView) {}
    }

    struct Style: InAppBorderable, InAppRoundableCorners {
        // MARK: -

        let backgroundColor: UIColor
        let radius: [CGFloat]
        let borderWidth: CGFloat?
        let borderColor: UIColor?
        let textAlign: NSTextAlignment
        let contentHorizontalAlignment: UIControl.ContentHorizontalAlignment
        let textColor: UIColor
        let maxLines: Int

        // MARK: -

        init(backgroundColor: UIColor, radius: [Int], borderWidth: Int?, borderColor: UIColor?, textAlign: InAppHorizontalAlignment, textColor: UIColor, maxLines: Int) {
            self.backgroundColor = backgroundColor
            self.radius = radius.map(CGFloat.init)
            self.borderWidth = borderWidth.map(CGFloat.init)
            self.borderColor = borderColor
            self.textAlign = switch textAlign {
                case .left: .left
                case .center: .center
                case .right: .right
            }
            self.contentHorizontalAlignment = switch textAlign {
                case .left: .left
                case .center: .center
                case .right: .right
            }
            self.textColor = textColor
            self.maxLines = maxLines
        }

        // MARK: -

        func apply(on button: InAppButtonView) {
            button.backgroundColor = backgroundColor

            button.titleLabel?.textColor = textColor
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.titleLabel?.lineBreakStrategy = .standard
            button.titleLabel?.numberOfLines = maxLines
            button.titleLabel?.textAlignment = textAlign
            button.contentHorizontalAlignment = contentHorizontalAlignment
            button.titleLabel?.adjustsFontForContentSizeCategory = BAMessagingCenter.instance().enableDynamicType

            if #available(iOS 15.0, *) {
                button.maximumContentSizeCategory = UIContentSizeCategory.extraExtraExtraLarge
            }
        }
    }

    struct Placement: InAppContainerizable {
        // MARK: -

        let margins: UIEdgeInsets
        let widthType: InAppWidthType?
        let paddings: UIEdgeInsets
        let horizontalAlignment: InAppHorizontalAlignment?
        let verticalAlignment: InAppVerticalAlignment? = .top

        // MARK: -

        func apply(on button: UIButton) {
            button.titleEdgeInsets = paddings
            button.contentEdgeInsets = .zero
        }
    }

    struct Action: InAppCTAComponent {
        // MARK: -

        let analyticsIdentifier: String
        let action: BAMSGAction?
        let type: InAppCTAType = .button
    }

    struct Content {
        // MARK: -

        let text: String

        // MARK: -

        func apply(on button: InAppButtonView, fontStyle: InAppFontStylizable & InAppFontDecorationStylizable) {
            guard let label = button.titleLabel else { return }

            let attributedString = (try? InAppFontStyleBuilder.attributedString(text: text, fontStyle: fontStyle, labelFont: label.font)) ?? NSAttributedString(string: text)
            button.setAttributedTitle(attributedString, for: .normal)
            button.accessibilityLabel = attributedString.string
        }
    }
}
