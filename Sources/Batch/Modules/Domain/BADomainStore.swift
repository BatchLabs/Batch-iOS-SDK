//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

fileprivate let loggerDomain = "BADomainStore"

public struct BADomainStore: BADomainStoreProtocol {
    // MARK: - Parameters

    public var currentDomain: String {
        BAParameter.object(forKey: kParametersDomainKey, fallback: kParametersDomainOriginal) as? String ?? kParametersDomainOriginal
    }

    // MARK: - Initializer

    public init() {
        BALogger.debug(domain: loggerDomain, message: "Start with '\(currentDomain)' as the current domain.")
    }

    // MARK: - Functions

    public func updateDomain(with domain: String?) {
        // Reset domain error parameter values
        resetErrorCountIfNeeded()

        if let domain {
            // Save the new domain
            BALogger.debug(domain: loggerDomain, message: "Set BAParameter key: '\(kParametersDomainKey)' with '\(domain)'.")
            BAParameter.setValue(domain, forKey: kParametersDomainKey, saved: true)
        } else {
            // Reset the domain
            BALogger.debug(domain: loggerDomain, message: "Remove BAParameter key: '\(kParametersDomainKey)'.")
            BAParameter.removeObject(forKey: kParametersDomainKey)
        }

        // Update domain last update date
        BAParameter.setValue(Date().timeIntervalSince1970, forKey: kParametersDomainLastUpdateDate, saved: true)

        BALogger.debug(domain: loggerDomain, message: "New current domain: '\(currentDomain)'.")
    }

    @discardableResult
    public func incrementErrorCount() -> Int {
        // Get domain error count
        let errorCount = BAParameter.object(forKey: kParametersDomainErrorCountKey, fallback: 0) as? Int ?? 0

        // Increment the counter
        let newValue = errorCount + 1
        let errorUpdateDate = Date()

        BALogger.debug(domain: loggerDomain, message: "Increment BAParameter key: '\(kParametersDomainErrorCountKey)' by 1, (old value: \(errorCount), new value: \(newValue), domain: \(currentDomain)). \(errorUpdateDate)")

        // Save new the domain error values
        BAParameter.setValue(newValue, forKey: kParametersDomainErrorCountKey, saved: true)
        BAParameter.setValue(errorUpdateDate.timeIntervalSince1970, forKey: kParametersDomainErrorUpdateDate, saved: true)

        // Add metric
        let metricRegistry = BAInjection.inject(BAMetricRegistry.self)
        (metricRegistry?.dnsErrorCount().labels(["KO"]) as? BACounter)?.increment()

        // Return the new counter value
        return newValue
    }

    public func resetDomainToOriginal() {
        // Reset the current domain with the orignal one
        updateDomain(with: nil)
    }

    public func resetErrorCountIfNeeded() {
        // No domain error count case
        guard (BAParameter.object(forKey: kParametersDomainErrorCountKey, fallback: 0) as? Int ?? 0) > 0 else { return }

        // Reset domain error count
        BAParameter.removeObject(forKey: kParametersDomainErrorCountKey)
        BAParameter.removeObject(forKey: kParametersDomainErrorUpdateDate)

        let metricRegistry = BAInjection.inject(BAMetricRegistry.self)
        (metricRegistry?.dnsErrorCount().labels(["OK"]) as? BACounter)?.reset()
    }

    public func updateLastCheckDomainDate() {
        BAParameter.setValue(Date().timeIntervalSince1970, forKey: kParametersDomainLastCheckDate, saved: true)
    }

    public func canCheckOriginalDomainAvalaibility() -> Bool {
        // No domain changes
        let currentDomain = BAParameter.object(forKey: kParametersDomainKey, fallback: nil) as? String
        let lastDomainUpdateDate = (BAParameter.object(forKey: kParametersDomainLastUpdateDate, fallback: nil) as? TimeInterval).flatMap(Date.init(timeIntervalSince1970:))
        guard lastDomainUpdateDate != nil else { return false }
        guard currentDomain != nil else { return false }

        // Current domain is the original one
        guard currentDomain != kParametersDomainOriginal else { return false }

        // Never check case
        guard let lastDomainCheckDate = (BAParameter.object(forKey: kParametersDomainLastCheckDate, fallback: nil) as? TimeInterval).flatMap(Date.init(timeIntervalSince1970:)) else { return true }

        // Throttler guard case
        guard lastDomainCheckDate.timeIntervalSinceNow > Double(kParametersDomainLastCheckMinDelaySecond) else { return false }

        // All good
        return true
    }

    public func lastErrorUpdateDate() -> Date? {
        return (BAParameter.object(forKey: kParametersDomainErrorUpdateDate, fallback: nil) as? TimeInterval)
            .flatMap(Date.init(timeIntervalSince1970:))
    }
}
