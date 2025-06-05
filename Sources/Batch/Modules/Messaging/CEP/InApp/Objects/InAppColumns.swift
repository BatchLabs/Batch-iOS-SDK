//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app columns
public struct InAppColumns: Codable, InAppTypedComponent {
    // MARK: -

    public let type: InAppComponent
    let children: [InAppAnyTypedComponent?]
    let ratios: [Int]?
    let margin: [Int]?
    let spacing: Int?
    let contentAlign: InAppVerticalAlignment?

    // MARK: -

    public init(children: [InAppAnyTypedComponent?], ratios: [Int]?, margin: [Int]?, spacing: Int?, align: InAppVerticalAlignment?) {
        self.type = .columns
        self.children = children
        self.ratios = ratios
        self.margin = margin
        self.spacing = spacing
        self.contentAlign = align
    }
}
