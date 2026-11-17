//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Define font style for ``InAppLabel`` & ``InAppButton``
/// Will be use to generalize apply
protocol InAppFontStylizable {
    var fontSize: Int? { get }
    var fontOverride: UIFont? { get }
    var fontBoldOverride: UIFont? { get }
    var fontItalicOverride: UIFont? { get }
    var fontBoldItalicOverride: UIFont? { get }
}

extension InAppFontStylizable {
    var fontOverride: UIFont? { InAppFont.fontOverride }
    var fontBoldOverride: UIFont? { InAppFont.fontBoldOverride }
    var fontItalicOverride: UIFont? { InAppFont.fontItalicOverride }
    var fontBoldItalicOverride: UIFont? { InAppFont.fontBoldItalicOverride }
}

extension InAppFontStylizable {
    /// According text's balise create an attributed string to apply
    /// - Parameters:
    ///   - text: Text to inspect
    ///   - font: default font
    /// - Returns: fomtated string to apply
    func buildAttributedString(with text: String, font: UIFont) throws -> NSAttributedString {
        // Parse balises
        let parser = BATHtmlParser(string: text)

        if let error = parser.parse() {
            throw error
        }

        // Set Initial string
        let attText = NSMutableAttributedString(string: parser.text, attributes: [.font: font])
        // Iterate on transforms
        for transform in parser.transforms.reversed() {
            let modifiers = transform.modifiers
            // Apply decoration style
            if modifiers.contains(.bold) || modifiers.contains(.italic) || modifiers.contains(.smallerFont) || modifiers.contains(.biggerFont) {
                var uiFontTraits: UIFontDescriptor.SymbolicTraits = []
                // Italic
                if modifiers.contains(.bold) {
                    uiFontTraits.insert(.traitBold)
                }
                // Bold
                if modifiers.contains(.italic) {
                    uiFontTraits.insert(.traitItalic)
                }

                // Override font
                attText.addAttribute(
                    .font,
                    value: fontVariant(
                        forTraits: uiFontTraits,
                        font: font
                    ),
                    range: transform.range
                )
            }

            // Uderline
            if modifiers.contains(.underline) {
                attText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: transform.range)
            }

            // Strikethrough
            if modifiers.contains(.strikethrough) {
                // Yes, Strikethrough reuses the underline styling enum
                attText.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: transform.range)
            }
        }

        return attText
    }

    func fontVariant(forTraits traits: UIFontDescriptor.SymbolicTraits, font: UIFont) -> UIFont {
        guard !traits.isEmpty else {
            return fontSize.flatMap { font.withSize(CGFloat($0)) } ?? font
        }

        let computedFont =
            if let fontOverride {
                // We have a custom font, work with that
                if traits.contains(.traitBold) {
                    traits.contains(.traitItalic) ? fontItalicOverride : fontBoldOverride
                } else if traits.contains(.traitItalic) {
                    fontBoldItalicOverride
                } else {
                    fontOverride
                }
            } else {
                // System font
                font.fontDescriptor.withSymbolicTraits(traits).map { UIFont(descriptor: $0, size: font.pointSize) }
            }

        return fontSize.map { computedFont?.withSize(CGFloat($0)) ?? font } ?? font
    }
}
