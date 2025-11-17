// File: InAppContainer.swift

//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// A powerful layout wrapper view that applies complex sizing and alignment rules to a single child view.
/// It uses a configuration conforming to `InAppContainerizable` to set up its constraints,
/// acting as the core layout engine for individual message components.
final class InAppContainer: UIView, InAppExpandableView {
    // MARK: - Properties

    /// A boolean indicating if the container should expand to fill available space.
    public let isExpandable: Bool

    // MARK: - Initialization

    /// Initializes the container with a configuration and a view builder closure.
    /// - Parameters:
    ///   - configuration: An object conforming to `InAppContainerizable` that defines the layout rules.
    ///   - viewBuilder: A closure that creates the child view to be placed inside the container.
    public init(configuration: InAppContainerizable, viewBuilder: @escaping () throws -> UIView) throws {
        self.isExpandable = configuration.isExpandable
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

    // MARK: - Configuration

    /// Configures the container by creating the child view and setting up all layout constraints.
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

        clipsToBounds = true

        addSubview(view)

        // Set up horizontal and vertical constraints and activate them.
        let constraints =
            setupHorizontal(view: view, type: widthType, alignment: horizontalAlignment, margins: margins, paddings: paddings)
            + setupVertical(view: view, type: heightType, alignment: verticalAlignment, margins: margins, paddings: paddings)

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Constraint Setup

    /// Sets up vertical constraints for the child view based on sizing and alignment rules.
    func setupVertical(view: UIView, type: InAppHeightType, alignment: InAppVerticalAlignment, margins: UIEdgeInsets, paddings _: UIEdgeInsets) -> [NSLayoutConstraint] {
        let heightConstraints: [NSLayoutConstraint?]

        switch type {
        case .auto, .fill:
            // For auto and fill, the container's height is determined by the child's height plus margins.
            heightConstraints = [heightAnchor.constraint(equalTo: view.heightAnchor, constant: margins.top + margins.bottom)]
        case let .fixed(value):
            // For fixed height, both the child and the container have a fixed height.
            heightConstraints = [
                view.heightAnchor.constraint(equalToConstant: CGFloat(value)),
                heightAnchor.constraint(equalToConstant: CGFloat(value) + margins.top + margins.bottom),
            ]
        }

        return setupVerticalAlignment(view: view, alignment: alignment, top: margins.top, bottom: margins.bottom)
            + heightConstraints.compactMap { $0 }
    }

    /// Sets up vertical alignment constraints (top, center, bottom).
    func setupVerticalAlignment(view: UIView, alignment: InAppVerticalAlignment, top: CGFloat, bottom: CGFloat) -> [NSLayoutConstraint] {
        return switch alignment {
        case .top:
            [
                view.topAnchor.constraint(equalTo: topAnchor, constant: top),
                bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor, constant: bottom),
            ]
        case .center:
            [
                view.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]
        case .bottom:
            [
                view.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: top),
                bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottom),
            ]
        }
    }

    /// Sets up horizontal constraints for the child view based on sizing and alignment rules.
    func setupHorizontal(view: UIView, type: InAppWidthType, alignment: InAppHorizontalAlignment, margins: UIEdgeInsets, paddings _: UIEdgeInsets) -> [NSLayoutConstraint] {
        let widthConstraint: NSLayoutConstraint

        switch type {
        case .auto:
            // For auto width, the container's width is determined by the child's width plus margins.
            widthConstraint = widthAnchor.constraint(equalTo: view.widthAnchor, constant: margins.left + margins.right)
        case let .percent(value):
            // For percent width, the child's width is a percentage of the container's width.
            widthConstraint = view.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(value) / 100, constant: -(margins.left + margins.right))
        }

        return setupHorizontalAlignment(view: view, alignment: alignment, left: margins.left, right: margins.right)
            + [widthConstraint]
    }

    /// Sets up horizontal alignment constraints (left, center, right).
    func setupHorizontalAlignment(view: UIView, alignment: InAppHorizontalAlignment, left: CGFloat, right: CGFloat) -> [NSLayoutConstraint] {
        return switch alignment {
        case .left:
            [
                view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: left),
                trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor, constant: right),
            ]
        case .center:
            [
                view.centerXAnchor.constraint(equalTo: centerXAnchor)
            ]
        case .right:
            [
                view.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: left),
                trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: right),
            ]
        }
    }
}
