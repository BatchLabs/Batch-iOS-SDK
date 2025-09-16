//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// A protocol for views that support an expanded state to show more content.
/// Use for ``InAppContainerizable`` to automatically extend existant view
protocol InAppExpandableView {
    /// A Boolean value that determines whether the view can be expanded.
    ///
    /// Conforming types should return `true` if they support an expanded state, and `false` otherwise.
    var isExpandable: Bool { get }
}
