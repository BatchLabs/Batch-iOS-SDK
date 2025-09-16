// File: InAppContainerizable.swift

//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// A protocol that defines the contract for any configuration object that can be placed inside an `InAppContainer`.
/// It specifies all necessary layout properties, such as sizing, alignment, margins, and padding,
/// allowing the `InAppContainer` to correctly position and size its content.
protocol InAppContainerizable: InAppExpandableView {
    /// The vertical sizing rule for the content (e.g., fixed, auto, fill).
    var heightType: InAppHeightType? { get }
    /// The horizontal sizing rule for the content (e.g., percent, auto).
    var widthType: InAppWidthType? { get }
    /// The outer margins around the container.
    var margins: UIEdgeInsets { get }
    /// The inner padding within the container.
    var paddings: UIEdgeInsets { get }
    /// The vertical alignment of the content within the container.
    var verticalAlignment: InAppVerticalAlignment? { get }
    /// The horizontal alignment of the content within the container.
    var horizontalAlignment: InAppHorizontalAlignment? { get }
}

/// Provides default values for the layout properties, making conformance easier.
extension InAppContainerizable {
    var heightType: InAppHeightType? { nil }
    var widthType: InAppWidthType? { nil }
    var margins: UIEdgeInsets { .zero }
    var paddings: UIEdgeInsets { .zero }
    var verticalAlignment: InAppVerticalAlignment? { nil }
    var horizontalAlignment: InAppHorizontalAlignment? { nil }

    /// A component is considered expandable if its height is set to "fill".
    var isExpandable: Bool { heightType == .fill }
}
