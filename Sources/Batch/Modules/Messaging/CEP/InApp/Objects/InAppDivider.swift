//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app divider
public struct InAppDivider: Codable, InAppTypedComponent {
    // MARK: -

    public let type: InAppComponent
    let color: [String]
    let thickness: Int?
    let margin: [Int]?
    let width: String
    let align: InAppHorizontalAlignment?

    // MARK: -

    public init(color: [String], thickness: Int?, margin: [Int]?, width: String, align: InAppHorizontalAlignment?) {
        self.type = .divider
        self.color = color
        self.thickness = thickness
        self.margin = margin
        self.width = width
        self.align = align
    }
}
