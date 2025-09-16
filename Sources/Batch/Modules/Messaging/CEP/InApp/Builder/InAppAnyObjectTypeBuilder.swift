//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// A helper struct that transforms raw in-app message components into an array of UI view builders.
///
/// - Warning: This builder is intended for internal use within `InAppMessageBuilder` and for testing purposes in `InAppColumnsViewTests`.
struct InAppAnyObjectTypeBuilder {
    /// Builds an array of `InAppViewBuilder` from raw message data.
    ///
    /// This static method iterates through a list of component types, finds the associated raw data (text, URLs, actions),
    /// and generates the appropriate UI builder for each component. It must be called on the main actor.
    ///
    /// - Parameters:
    ///   - urls: A dictionary mapping identifiers to URL strings, used for images or other remote content.
    ///   - texts: A dictionary mapping identifiers to localized text strings.
    ///   - actions: A dictionary mapping identifiers to executable `InAppAction` objects.
    ///   - componentTypes: An array of typed components that define the structure and type of each UI element.
    ///   - format: The visual format of the in-app message (e.g., modal, banner).
    /// - Returns: An array of optional `InAppViewBuilder` instances, corresponding to each component type. The order is preserved.
    /// - Throws: An error if a component fails to initialize its corresponding UI builder.
    static func build(
        urls: [String: String],
        texts: [String: String],
        actions: [String: InAppAction],
        componentTypes: [InAppAnyTypedComponent?],
        format: InAppFormat
    ) throws -> [InAppViewBuilder?] {
        return try componentTypes.map { componentType -> InAppViewBuilder? in
            guard let component = componentType?.component else { return nil }

            return try component.uiBuilder(format: format, urls: urls, texts: texts, actions: actions)
        }
    }
}
