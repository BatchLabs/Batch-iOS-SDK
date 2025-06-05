//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app button
public struct InAppButton: Codable, Identifiable, InAppTypedComponent, InAppFontDecorationStylizable {
    // MARK: -

    public let id: String
    public let type: InAppComponent
    let margin: [Int]?
    let padding: [Int]?
    let width: String?
    let align: InAppHorizontalAlignment?
    let backgroundColor: [String]
    let radius: [Int]?
    let borderWidth: Int?
    let borderColor: [String]?
    let fontSize: Int
    let textAlign: InAppHorizontalAlignment?
    let textColor: [String]
    let maxLines: Int?
    let fontDecoration: [InAppFontDecoration]?

    // MARK: -

    public init(
        id: String,
        margin: [Int]?,
        padding: [Int]?,
        width: String?,
        align: InAppHorizontalAlignment?,
        backgroundColor: [String],
        radius: [Int]?,
        borderWidth: Int?,
        borderColor: [String]?,
        fontSize: Int,
        textAlign: InAppHorizontalAlignment?,
        textColor: [String],
        maxLines: Int?,
        fontDecoration: [InAppFontDecoration]?
    ) {
        self.id = id
        self.type = .button
        self.margin = margin
        self.padding = padding
        self.width = width
        self.align = align
        self.backgroundColor = backgroundColor
        self.radius = radius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.fontSize = fontSize
        self.textAlign = textAlign
        self.textColor = textColor
        self.maxLines = maxLines
        self.fontDecoration = fontDecoration
    }
}
