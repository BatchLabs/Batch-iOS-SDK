//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

@objc
@objcMembers
/// Wrapper around BATRegularExpression reducing required boilerplate and common implementation errors
/// If the regexp fails to initialize, the class will not match anything on purpose as it's a very rare case.
/// Feel free to check the property to log if that happened.
public class BATRegularExpression: NSObject {
    public private(set) var regexpFailedToInitialize: Bool = false

    private let backingRegexp: NSRegularExpression?

    public init(pattern: String, options: NSRegularExpression.Options = []) {
        do {
            backingRegexp = try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            backingRegexp = nil
            regexpFailedToInitialize = true
            BALogger.public(domain: "Internal", message: "Failed to initialize regexp: \(error.localizedDescription)")
        }
        super.init()
    }

    // Checks if the string fully matches the regexp
    public func matches(_ target: String) -> Bool {
        guard let backingRegexp else {
            return false
        }

        let fullStringRange = NSRange(location: 0, length: target.utf16.count)
        let matchingRange = backingRegexp.rangeOfFirstMatch(in: target, range: fullStringRange)

        if matchingRange.location == NSNotFound || matchingRange != fullStringRange {
            return false
        }
        return true
    }
}
