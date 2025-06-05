//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Class to store for in app and mobile landing, the font to use
@objc
@objcMembers
public class InAppFont: NSObject {
    // MARK: -

    static var fontOverride: UIFont? = nil
    static var fontBoldOverride: UIFont? = nil
    static var fontItalicOverride: UIFont? = nil
    static var fontBoldItalicOverride: UIFont? = nil

    /// Override the current wanted font
    /// - Parameters:
    ///   - font: The font
    ///   - boldFont: The bold font
    ///   - italicFont: The italic font
    ///   - boldItalicFont: The bold and italic font
    public static func setFontOverride(_ font: UIFont, boldFont: UIFont? = nil, italicFont: UIFont? = nil, boldItalicFont: UIFont? = nil) {
        fontOverride = font
        fontBoldOverride = boldFont
        fontItalicOverride = italicFont
        fontBoldItalicOverride = boldItalicFont
    }

    /// Reset to nil all fonts
    public static func reset() {
        fontOverride = nil
        fontBoldOverride = nil
        fontItalicOverride = nil
        fontBoldItalicOverride = nil
    }
}
