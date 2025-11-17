//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

// A generic validation error used to surface a message to the developer
// Helps to enforce the good practice to have throwing methods with testable errors
// leaving choice to the caller on how to deal with this.
// Note: do not expose those errors to developers directly, have custom NSError wrappers
// or Obj-C code handling it to expose documented NSErrorDomains and code enums.
enum BATSDKError: Error {
    case sdkInternal(subcode: Int, reason: String? = nil)
    case userInputValidation(String)
}

extension BATSDKError: CustomNSError {
    public static var errorDomain: String = "BatchSDKError"

    public var errorCode: Int {
        switch self {
        case .sdkInternal:
            return 1
        case .userInputValidation:
            return 20
        }
    }

    public var errorUserInfo: [String: Any] {
        return [:]
    }
}

extension BATSDKError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .sdkInternal(subcode, reason):
            var description = "Internal error (code \(subcode))"
            if let reason {
                description += " Reason: \(reason)"
            }
            return description
        case let .userInputValidation(reason):
            return reason
        }
    }
}
