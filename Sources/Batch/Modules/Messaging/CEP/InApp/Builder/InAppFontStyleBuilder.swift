//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

struct InAppFontStyleBuilder {
    static func attributedString(text: String, fontStyle: InAppFontStylizable & InAppFontDecorationStylizable, labelFont: UIFont) throws -> NSAttributedString {
        var rules: [String: String] = [:]
        fontStyle.fontSize.map { size in rules["font-size"] = size.formatted() }

        let font = BAMSGStylableViewHelper.font(fromRules: rules, baseFont: fontStyle.fontOverride, baseBoldFont: fontStyle.fontBoldOverride)
        let text = addDecoration(to: text, fontDecorationStyle: fontStyle)
        return try fontStyle.buildAttributedString(with: text, font: font ?? labelFont)
    }

    static func addDecoration(to text: String, fontDecorationStyle: InAppFontDecorationStylizable) -> String {
        guard let fontDecoration = fontDecorationStyle.fontDecoration else { return text }

        return fontDecoration.reduce(text) { partialResult, decoration in
            return decoration.wrapped(content: partialResult)
        }
    }
}

/// According the decoration, wrap the content by the right tag
/// Should be the same tags unsed in
/// ``- (BATTextModifiers)modifierForTag:(NSString *)tag``
extension InAppFontDecoration {
    fileprivate func wrapped(content: String) -> String {
        return switch self {
        case .bold: "<b>\(content)</b>"
        case .italic: "<i>\(content)</i>"
        case .stroke: "<s>\(content)</s>"
        case .underline: "<u>\(content)</u>"
        }
    }
}
