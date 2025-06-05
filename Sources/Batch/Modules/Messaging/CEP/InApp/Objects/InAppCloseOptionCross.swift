//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app close cross button
public struct InAppCloseOptionCross: Codable {
    // MARK: -

    let color: [String]
    let backgroundColor: [String]?

    // MARK: -

    public init(color: [String], backgroundColor: [String]?) {
        self.color = color
        self.backgroundColor = backgroundColor
    }
}
