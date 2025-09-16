//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// A protocol that defines the properties of a component within an expandable view.
protocol InAppExpandableComponent {
    /// The string representation of the component's desired height, corresponding to the raw value of an ``InAppHeightType``.
    ///
    /// This value is parsed to determine the sizing behavior. Examples include:
    /// - `"auto"`: The height is determined by the component's intrinsic content size.
    /// - `"fill"`: The component expands to fill remaining vertical space.
    /// - `"250px"`: The height is a fixed value.
    var height: String { get }
}
