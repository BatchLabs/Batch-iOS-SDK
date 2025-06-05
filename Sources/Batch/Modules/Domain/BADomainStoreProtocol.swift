//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

public protocol BADomainStoreProtocol {
    /// Determines the current domain.
    /// This domain is typically the one being used in the app for performing operations.
    var currentDomain: String { get }

    /// Updates the current domain with a new provided domain.
    /// If `domain` is nil, it reset the domain to `kParametersDomainOriginal`.
    func updateDomain(with domain: String?)

    /// Increments the error count and returns the new error count value.
    /// Used to track the number of errors related to the domain.
    @discardableResult
    func incrementErrorCount() -> Int

    /// Updates the date of the last check performed on the domain.
    func updateLastCheckDomainDate()

    /// Resets the domain to its original value `kParametersDomainOriginal`.
    func resetDomainToOriginal()

    /// Resets the error count if needed, for instance if a success api call was done on the current domain.
    func resetErrorCountIfNeeded()

    /// Returns the date of the last error update, or nil if no error has been recorded.
    func lastErrorUpdateDate() -> Date?

    /// Determines if the original domain can be checked for availability.
    func canCheckOriginalDomainAvalaibility() -> Bool
}
