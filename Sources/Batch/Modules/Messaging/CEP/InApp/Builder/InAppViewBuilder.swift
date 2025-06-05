//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Light struct to build view on demand
struct InAppViewBuilder {
    // MARK: -

    let component: InAppTypedComponent

    let content: @MainActor (
        @escaping InAppClosureDelegate.Closure,
        @escaping InAppErrorDelegate.Closure
    ) throws -> UIView
}
