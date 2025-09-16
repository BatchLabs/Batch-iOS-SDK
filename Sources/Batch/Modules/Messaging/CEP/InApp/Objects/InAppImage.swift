//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app image
public struct InAppImage: Codable, Identifiable, InAppTypedComponent, InAppExpandableComponent {
    // MARK: -

    public let id: String
    public let type: InAppComponent
    let aspect: InAppAspectRatio?
    let margin: [Int]?
    let height: String
    let radius: [Int]?

    // MARK: -

    public init(id: String, aspect: InAppAspectRatio?, margin: [Int]?, height: String, radius: [Int]?) {
        self.id = id
        self.type = .image
        self.aspect = aspect
        self.margin = margin
        self.height = height
        self.radius = radius
    }
}
