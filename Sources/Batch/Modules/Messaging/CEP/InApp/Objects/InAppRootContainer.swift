//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app root container
public struct InAppRootContainer: Codable {
    // MARK: -

    let backgroundColor: [String]?
    let children: [InAppAnyTypedComponent]
    let margin: [Int]?
    let radius: [Int]?
    let borderWidth: Int?
    let borderColor: [String]?

    // MARK: -

    public init(backgroundColor: [String]?, children: [InAppAnyTypedComponent], margin: [Int]?, radius: [Int]?, borderWidth: Int?, borderColor: [String]?) {
        self.backgroundColor = backgroundColor
        self.children = children
        self.margin = margin
        self.radius = radius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }
}
