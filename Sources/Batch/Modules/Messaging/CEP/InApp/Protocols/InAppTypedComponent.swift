//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Define a type to help the deserialization of ``AnyCodable`` by ``AnyCodableBuilder``
public protocol InAppTypedComponent: Codable {
    var type: InAppComponent { get }
}
