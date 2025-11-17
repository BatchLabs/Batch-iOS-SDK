//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// A lightweight struct that acts as a "recipe" or "blueprint" for creating a `UIView` on demand.
/// This defers the actual view initialization until it's needed, which can improve performance.
struct InAppViewBuilder {
    // MARK: - Properties

    /// The original data model component (e.g., `InAppButton`, `InAppImage`).
    let component: InAppTypedComponent

    /// Caches the expandability information for the view to be built.
    let expandable: InAppExpandableView

    /// A closure that, when executed, builds and returns the fully configured `UIView`.
    /// It must be called on the main actor.
    /// - Parameters:
    ///   - onClosureTap: A closure to handle user actions (e.g., button taps).
    ///   - onError: A closure to handle errors (e.g., image loading failure).
    let content:
        @MainActor (
            _ onClosureTap: @escaping InAppClosureDelegate.Closure,
            _ onError: @escaping InAppErrorDelegate.Closure
        ) throws -> UIView
}
