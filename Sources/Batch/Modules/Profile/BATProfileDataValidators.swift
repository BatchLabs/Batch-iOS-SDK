//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

@objc
@objcMembers
public class BATProfileDataValidators: NSObject {
    static let loggingDomain = "ProfileDataValidator"

    static let emailAddressPattern = "^[^@\\s]+@[A-z0-9\\-\\.]+\\.[A-z0-9]+$"
    static let phoneNumberPattern = "^\\+[0-9]{1,15}$"

    public static let emailMaxLength = 256
    public static let customIDMaxLength = 1024

    static let blocklistedCustomIDs = ["undefined", "null", "nil", "(null)", "[object object]", "true", "false", "nan", "infinity", "-infinity"]

    public static func isValidEmail(_ email: String) -> Bool {
        let regexp = BATRegularExpression(pattern: emailAddressPattern)
        return regexp.matches(email)
    }

    public static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let regexp = BATRegularExpression(pattern: phoneNumberPattern)
        return regexp.matches(phoneNumber)
    }

    public static func isEmailTooLong(_ email: String) -> Bool {
        return email.count > emailMaxLength
    }

    public static func isCustomIDAllowed(_ customID: String) -> Bool {
        if customID.contains("\n") {
            return false
        }

        if customID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }

        return true
    }

    public static func isCustomIDTooLong(_ customID: String) -> Bool {
        if customID.count > customIDMaxLength {
            return true
        }

        return false
    }

    public static func isCustomIDBlocklisted(_ customID: String) -> Bool {
        return blocklistedCustomIDs.contains(customID.lowercased())
    }
}
