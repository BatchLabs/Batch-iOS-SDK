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
    // \r\n\t is \s but for some reason \S doesn't validate those in a negation so we explicitly use those
    static let emailValidationRegexpPattern = "^[^@\\r\\n\\t]+@[A-z0-9\\-\\.]+\\.[A-z0-9]+$"

    public static let emailMaxLength = 256
    public static let customIDMaxLength = 1024

    public static func isValidEmail(_ email: String) -> Bool {
        let regexp = BATRegularExpression(pattern: emailValidationRegexpPattern)
        guard regexp.regexpFailedToInitialize == false else {
            BALogger.debug(domain: loggingDomain, message: "Email regexp unavailable")
            return false
        }

        return regexp.matches(email)
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
}
