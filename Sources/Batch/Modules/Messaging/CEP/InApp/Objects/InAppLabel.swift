//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app label
public struct InAppLabel: Codable, Identifiable, InAppTypedComponent, InAppFontDecorationStylizable {
    // MARK: -

    public let id: String
    public let type: InAppComponent
    let margin: [Int]?
    let textAlign: InAppHorizontalAlignment?
    let fontSize: Int
    let color: [String]
    let maxLines: Int?
    let fontDecoration: [InAppFontDecoration]?

    // MARK: -

    public init(
        id: String,
        margin: [Int]?,
        textAlign: InAppHorizontalAlignment?,
        fontSize: Int,
        color: [String],
        maxLines: Int?,
        fontDecoration: [InAppFontDecoration]?
    ) {
        self.id = id
        self.type = .text
        self.margin = margin
        self.textAlign = textAlign
        self.fontSize = fontSize
        self.color = color
        self.maxLines = maxLines
        self.fontDecoration = fontDecoration
    }
}
