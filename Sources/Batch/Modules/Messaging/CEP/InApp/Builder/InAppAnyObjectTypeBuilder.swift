//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Must only be used in ``InAppMessageBuilder`` and ``InAppColumnsViewTests``
struct InAppAnyObjectTypeBuilder {
    /// Build ``InAppViewBuilder`` array
    /// - Parameters
    ///  - urls: In app's urls
    ///  - texts: In app's texts
    ///  - codables: Objects' codable
    /// - Returns: The builders
    static func build(
        urls: [String: String],
        texts: [String: String],
        actions: [String: InAppAction],
        componentTypes: [InAppAnyTypedComponent?]
    ) -> [InAppViewBuilder?] {
        return componentTypes.map { componentType -> InAppViewBuilder? in
            guard let component = componentType?.component else { return nil }

            return component.uiBuilder(urls: urls, texts: texts, actions: actions)
        }
    }
}
