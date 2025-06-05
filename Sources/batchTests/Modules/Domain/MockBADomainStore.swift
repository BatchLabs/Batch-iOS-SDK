//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch

class MockBADomainStore: BADomainStoreProtocol {
    // MARK: - Parameters

    let store: BADomainStoreProtocol = BADomainStore()

    var currentDomain: String { store.currentDomain }

    // MARK: - Callbacks

    var updateDomainCallback: () -> Void = {}
    var incrementErrorCountCallback: (Int) -> Void = { _ in }
    var updateLastCheckDomainDateCallback: () -> Void = {}
    var resetDomainToOriginalCallback: () -> Void = {}
    var resetErrorCountIfNeededCallback: () -> Void = {}
    var lastErrorUpdateDateCallback: (Date?) -> Void = { _ in }
    var canCheckOriginalDomainAvalaibilityCallback: (Bool) -> Void = { _ in }
    var urlCallback: (String) -> Void = { _ in }

    // MARK: - Functions

    func updateDomain(with domain: String?) {
        updateDomainCallback()
        store.updateDomain(with: domain)
    }

    @discardableResult
    func incrementErrorCount() -> Int {
        let count = store.incrementErrorCount()
        incrementErrorCountCallback(count)
        return count
    }

    func updateLastCheckDomainDate() {
        store.updateLastCheckDomainDate()
        updateLastCheckDomainDateCallback()
    }

    func resetDomainToOriginal() {
        store.resetDomainToOriginal()
        resetDomainToOriginalCallback()
    }

    func resetErrorCountIfNeeded() {
        store.resetErrorCountIfNeeded()
        resetErrorCountIfNeededCallback()
    }

    func lastErrorUpdateDate() -> Date? {
        let date = store.lastErrorUpdateDate()
        lastErrorUpdateDateCallback(date)
        return date
    }

    func canCheckOriginalDomainAvalaibility() -> Bool {
        let can = store.canCheckOriginalDomainAvalaibility()
        canCheckOriginalDomainAvalaibilityCallback(can)
        return can
    }
}
