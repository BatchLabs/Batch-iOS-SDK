//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app action
public struct InAppAction: Codable {
    // MARK: -

    let action: String
    let params: [String: AnyCodable]?

    // MARK: -

    public init(action: String, params: [String: AnyCodable]? = nil) {
        self.action = action
        self.params = params
    }
}
