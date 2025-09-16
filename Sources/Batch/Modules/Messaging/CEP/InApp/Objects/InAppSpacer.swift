//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app spacer
public struct InAppSpacer: Codable, InAppTypedComponent, InAppExpandableComponent {
    // MARK: -

    public let type: InAppComponent
    let height: String

    // MARK: -

    public init(height: String) {
        self.type = .spacer
        self.height = height
    }
}
