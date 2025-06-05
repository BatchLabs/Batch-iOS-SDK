//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// In app container to handle size and aligments of components
final class InAppContainer: UIView {
    // MARK: -

    public init(configuration: InAppContainerizable, viewBuilder: @escaping () throws -> UIView) throws {
        super.init(frame: .zero)

        try configure(
            heightType: configuration.heightType ?? .auto,
            widthType: configuration.widthType ?? .auto,
            margins: configuration.margins,
            paddings: configuration.paddings,
            verticalAlignment: configuration.verticalAlignment ?? .center,
            horizontalAlignment: configuration.horizontalAlignment ?? .center,
            viewBuilder: viewBuilder
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    func configure(
        heightType: InAppHeightType,
        widthType: InAppWidthType,
        margins: UIEdgeInsets,
        paddings: UIEdgeInsets,
        verticalAlignment: InAppVerticalAlignment,
        horizontalAlignment: InAppHorizontalAlignment,
        viewBuilder: @escaping () throws -> UIView
    ) throws {
        translatesAutoresizingMaskIntoConstraints = false

        let view = try viewBuilder()
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        let contraints = setupHorizontal(
            view: view,
            type: widthType,
            alignment: horizontalAlignment,
            margins: margins,
            paddings: paddings
        ) + setupVertical(
            view: view,
            type: heightType,
            alignment: verticalAlignment,
            margins: margins,
            paddings: paddings
        )

        NSLayoutConstraint.activate(contraints)
    }

    func setupVertical(view: UIView,
                       type: InAppHeightType,
                       alignment: InAppVerticalAlignment,
                       margins: UIEdgeInsets,
                       paddings _: UIEdgeInsets) -> [NSLayoutConstraint]
    {
        let heightConstraints = switch (type, alignment) {
            case (.auto, _):
                [
                    heightAnchor.constraint(
                        equalTo: view.heightAnchor,
                        constant: margins.top + margins.bottom
                    ),
                ]
            case let (.fixed(value), _):
                [
                    view.heightAnchor.constraint(equalToConstant: CGFloat(value)),
                    heightAnchor.constraint(
                        equalToConstant: CGFloat(value) + margins.top + margins.bottom
                    ),
                ]
        }

        return setupVerticalAlignment(
            view: view,
            alignment: alignment,
            top: margins.top,
            bottom: margins.bottom
        ) + heightConstraints
    }

    func setupVerticalAlignment(
        view: UIView,
        alignment: InAppVerticalAlignment,
        top: CGFloat,
        bottom: CGFloat
    ) -> [NSLayoutConstraint] {
        return switch alignment {
            case .top:
                [
                    view.topAnchor.constraint(equalTo: topAnchor, constant: top),
                    bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor, constant: bottom),
                ]
            case .center:
                [
                    view.centerYAnchor.constraint(equalTo: centerYAnchor),
                ]
            case .bottom:
                [
                    view.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: top),
                    bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottom),
                ]
        }
    }

    func setupHorizontal(view: UIView,
                         type: InAppWidthType,
                         alignment: InAppHorizontalAlignment,
                         margins: UIEdgeInsets,
                         paddings _: UIEdgeInsets) -> [NSLayoutConstraint]
    {
        let widthConstraint = switch type {
            case .auto:
                widthAnchor.constraint(
                    equalTo: view.widthAnchor,
                    constant: margins.left + margins.right
                )
            case let .percent(value):
                view.widthAnchor.constraint(
                    equalTo: widthAnchor,
                    multiplier: CGFloat(value) / 100,
                    constant: -(margins.left + margins.right)
                )
        }

        return setupHorizontalAlignment(
            view: view,
            alignment: alignment,
            left: margins.left,
            right: margins.right
        ) + [widthConstraint]
    }

    func setupHorizontalAlignment(
        view: UIView,
        alignment: InAppHorizontalAlignment,
        left: CGFloat,
        right: CGFloat
    ) -> [NSLayoutConstraint] {
        return switch alignment {
            case .left:
                [
                    view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: left),
                    trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor, constant: right),
                ]
            case .center:
                [
                    view.centerXAnchor.constraint(equalTo: centerXAnchor),
                ]
            case .right:
                [
                    view.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: left),
                    trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: right),
                ]
        }
    }
}
