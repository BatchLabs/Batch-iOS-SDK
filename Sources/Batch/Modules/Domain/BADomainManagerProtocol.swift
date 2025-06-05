//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

@objc
public protocol BADomainManagerProtocol {
    /// Update current domain if needed
    func updateDomainIfNeeded()

    /// Updates the date of the last check performed on the domain.
    func updateLastCheckDomainDate()

    /// Reset current domain to the orgininal one
    func resetDomainToOriginal()

    /// Resets the error count if needed, for instance if a success api call was done on the current domain.
    func resetErrorCountIfNeeded()

    /// Determines if the original domain can be checked for availability.
    func canCheckOriginalDomainAvalaibility() -> Bool

    /// Returns the URL associated with a specific service.
    /// The `overrideWithOriginal` parameter determines whether the URL should be based on the original domain or the current domain.
    func url(for service: BADomainService, overrideWithOriginal: Bool) -> String
}
