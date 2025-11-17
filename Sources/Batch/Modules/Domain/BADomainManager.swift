//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

private let loggerDomain = "BADomainManager"

@objc
@objcMembers
public class BADomainManager: NSObject, BADomainManagerProtocol {
    // MARK: Singelton

    public static let sharedInstance = BADomainManager()

    // MARK: Parameters

    let isFeatureActivated: Bool

    let store: BADomainStoreProtocol

    public static let domains: [String] = [
        kParametersDomainOriginal,
        "batch.io",
    ]

    // MARK: - Initializer

    init(store: BADomainStoreProtocol = BADomainStore(), isFeatureActivated: Bool = NSNumber(value: kParametersDNSFallbackFeatureFlag).boolValue) {
        self.store = store
        self.isFeatureActivated = isFeatureActivated

        BALogger.debug(domain: loggerDomain, message: "Is feature activated ? '\(isFeatureActivated)'")
    }

    // MARK: Private functions

    func nextDomain() -> String {
        // Feature flag check
        guard isFeatureActivated else { return kParametersDomainOriginal }

        // Get the current domain index
        guard let currentDomainIndex = Self.domains.firstIndex(of: store.currentDomain) else { return kParametersDomainOriginal }

        // Determine the next domain index
        let index = Self.domains.index(after: currentDomainIndex)
        // Check the range of the next domain index
        if [Self.domains.startIndex - 1, Self.domains.endIndex - 1].contains(index) {
            // Return the new domain
            return Self.domains[index]
        } else {
            return store.currentDomain
        }
    }

    // MARK: Public functions

    public func updateDomainIfNeeded() {
        // Feature flag check
        guard isFeatureActivated else { return }

        // No previous error case
        guard let lastErrorUpdateDate = store.lastErrorUpdateDate() else {
            store.incrementErrorCount()
            return
        }

        // Throttler guard case
        guard abs(lastErrorUpdateDate.timeIntervalSinceNow) > TimeInterval(kParametersDomainErrorMinDelaySecond) else { return }

        let errorCount = store.incrementErrorCount()

        // Domain limit error reached case
        guard errorCount >= kParametersDomainErrorLimitCount else { return }

        // Determine the next domaine to use
        let newValue = nextDomain()

        guard newValue != store.currentDomain else {
            BALogger.debug(domain: loggerDomain, message: "The current domain and the new value are the same so no need to update the domain")
            return
        }

        // Update the current domain with the next domain
        store.updateDomain(with: newValue)
    }

    public func canCheckOriginalDomainAvalaibility() -> Bool {
        // Feature flag check
        guard isFeatureActivated else { return false }

        return store.canCheckOriginalDomainAvalaibility()
    }

    public func updateLastCheckDomainDate() {
        // Feature flag check
        guard isFeatureActivated else { return }

        store.updateLastCheckDomainDate()
    }

    public func resetDomainToOriginal() {
        // Feature flag check
        guard isFeatureActivated else { return }

        store.resetDomainToOriginal()
    }

    public func resetErrorCountIfNeeded() {
        // Feature flag check
        guard isFeatureActivated else { return }

        store.resetErrorCountIfNeeded()
    }

    public func url(for service: BADomainService, overrideWithOriginal: Bool) -> String {
        return service.url(domain: (overrideWithOriginal || !isFeatureActivated) ? kParametersDomainOriginal : store.currentDomain)
    }
}
