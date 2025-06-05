//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app auto close delay mechanism
public struct InAppCloseOptionDelay: Codable {
    // MARK: -

    let delay: Int
    let color: [String]?

    // MARK: -

    public init(delay: Int, color: [String]?) {
        self.delay = delay
        self.color = color
    }
}
