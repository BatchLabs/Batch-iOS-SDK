//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

/// A utility for overriding or ignoring certain layout properties based on the message format.
/// This is used to enforce design rules, such as ignoring root container margins on non-modal formats
/// to allow for edge-to-edge designs.
struct InAppMessageBuilderOverrider {
    /// A generic function that returns the provided `values` only if the format is `.modal`.
    /// For other formats (e.g., `.fullscreen`), it returns `nil`, effectively stripping the property.
    /// - Parameters:
    ///   - format: The in-app message format.
    ///   - values: The optional value to potentially override.
    /// - Returns: The original value or `nil`, depending on the format.
    static func values<T>(format: InAppFormat, values: T?) -> T? {
        // Margins, radius, and borders should only apply to modals.
        guard format == .modal else { return nil }
        return values
    }

    /// Overrides spacer behavior based on the format.
    /// It filters out spacers that are not applicable to a given layout, such as an "auto" height spacer
    /// or a "fill" spacer in a modal context, where they would have no effect.
    /// - Parameters:
    ///   - format: The in-app message format.
    ///   - value: The spacer component to evaluate.
    /// - Returns: The original spacer or `nil` if it should be ignored.
    static func expandableComponent<T: InAppExpandableComponent>(format: InAppFormat, value: T) -> T? {
        let heightType = InAppHeightType(stringValue: value.height)

        // Ignore "auto" spacers as they have no height.
        // Ignore "fill" spacers on modals as the layout doesn't support expansion.
        return heightType == .auto || (format == .modal && heightType == .fill) ? nil : value
    }
}
