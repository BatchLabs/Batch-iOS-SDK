//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import XCTest

final class BADomainStoreTests: XCTestCase {
    // MARK: - Setup

    let store: BADomainStoreProtocol = BADomainStore()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Remove local config
        BAParameter.removeObject(forKey: kParametersDomainKey)
        BAParameter.removeObject(forKey: kParametersDomainErrorCountKey)
        BAParameter.removeObject(forKey: kParametersDomainErrorUpdateDate)
        BAParameter.removeObject(forKey: kParametersDomainLastUpdateDate)
        BAParameter.removeObject(forKey: kParametersDomainLastCheckDate)
    }

    // MARK: CurrentDomain

    /// ``BADomainStore.getter:currentDomain``

    func testCurrentDomain() throws {
        // Given a domain
        let domain = BADomainManager.domains[1]
        BAParameter.setValue(domain, forKey: kParametersDomainKey, saved: true)

        // When get current domain value
        // Then current domain should be `BADomainManager.domains[1]`
        XCTAssertEqual(store.currentDomain, domain)
    }

    func testCurrentDomainWithNil() throws {
        // No given domain
        BAParameter.removeObject(forKey: kParametersDomainKey)

        // When get current domain value
        // Then current domain should be `kParametersDomainOriginal`
        XCTAssertEqual(store.currentDomain, kParametersDomainOriginal)
    }

    // MARK: UpdateDomain

    /// ``BADomainStore.updateDomain(with:)``

    func testUpdateDomain() throws {
        // Given the new domain
        let newDomain = BADomainManager.domains[1]

        // When we update the domain
        store.updateDomain(with: newDomain)
        let updateDate = Date().timeIntervalSince1970

        // Then the new domain should be the second element of `BADomainManager.domains`
        let savedDomain = BAParameter.object(
            forKey: kParametersDomainKey,
            fallback: nil
        ) as? String

        XCTAssertEqual(newDomain, savedDomain)

        // Then sdk saved value should be reseted
        XCTAssertNil(BAParameter.object(forKey: kParametersDomainErrorCountKey, fallback: nil))
        XCTAssertNil(BAParameter.object(forKey: kParametersDomainErrorUpdateDate, fallback: nil))

        // Then domain last update date sould be updated
        let savedUpdateDate = BAParameter.object(
            forKey: kParametersDomainLastUpdateDate,
            fallback: nil
        ) as? TimeInterval

        XCTAssertNotNil(savedUpdateDate)
        XCTAssertEqual(savedUpdateDate!, updateDate, accuracy: 0.1)
    }

    func testUpdateDomainWithNil() throws {
        // Not given domain
        // When we update the current domain
        store.updateDomain(with: nil)
        let updateDate = Date().timeIntervalSince1970

        // Then the new domain should be nil
        let savedDomain = BAParameter.object(
            forKey: kParametersDomainKey,
            fallback: nil
        ) as? String

        XCTAssertNil(savedDomain)

        // Then sdk saved value should be reseted
        XCTAssertNil(BAParameter.object(forKey: kParametersDomainErrorCountKey, fallback: nil))
        XCTAssertNil(BAParameter.object(forKey: kParametersDomainErrorUpdateDate, fallback: nil))
        XCTAssertNil(BAParameter.object(forKey: kParametersDomainKey, fallback: nil))
        XCTAssertNil(BAParameter.object(forKey: kParametersDomainLastCheckDate, fallback: nil))

        // Then domain last update date sould be updated
        let savedUpdateDate = BAParameter.object(
            forKey: kParametersDomainLastUpdateDate,
            fallback: nil
        ) as? TimeInterval

        XCTAssertNotNil(savedUpdateDate)
        XCTAssertEqual(savedUpdateDate!, updateDate, accuracy: 0.1)
    }

    // MARK: - IncrementErrorCount

    /// ``BADomainStore.incrementErrorCount()``

    func testIncrementErrorCountInitialState() throws {
        // Given intial state of domain error count
        // When the error count is incremented
        let errorCount = store.incrementErrorCount()
        let errorDate = Date().timeIntervalSince1970

        // Then domain error cound should be 1
        XCTAssertEqual(errorCount, 1)
        let errorUpdateDate = BAParameter.object(forKey: kParametersDomainErrorUpdateDate, fallback: nil) as? TimeInterval
        XCTAssertEqual(errorUpdateDate!, errorDate, accuracy: 0.1)
    }

    func testIncrementErrorCountAdvancedState() throws {
        // Given advanced state of domain error count
        let initialCount = 2
        BAParameter.setValue(initialCount, forKey: kParametersDomainErrorCountKey, saved: true)

        // When the error count is incremented
        let errorCount = store.incrementErrorCount()
        let errordate = Date().timeIntervalSince1970

        // Then domain error cound should be 3
        XCTAssertEqual(errorCount, initialCount + 1)
        let errorUpdateDate = BAParameter.object(forKey: kParametersDomainErrorUpdateDate, fallback: nil) as? TimeInterval
        XCTAssertEqual(errorUpdateDate!, errordate, accuracy: 0.1)
    }

    // MARK: - resetErrorCountIfNeeded

    /// ``BADomainStore.resetErrorCountIfNeeded()``

    func testresetErrorCountIfNeeded() throws {
        // Given domain error count set
        BAParameter.setValue(2, forKey: kParametersDomainErrorCountKey, saved: true)

        // When the domain error count is reset
        store.resetErrorCountIfNeeded()

        // Then domain error cound should be nil
        let errorCount = BAParameter.object(forKey: kParametersDomainErrorCountKey, fallback: nil) as? Int
        let errorUpdateDate = BAParameter.object(forKey: kParametersDomainErrorUpdateDate, fallback: nil) as? TimeInterval
        XCTAssertNil(errorCount)
        XCTAssertNil(errorUpdateDate)
    }

    // MARK: - UpdateLastCheckDomainDate

    /// ``BADomainStore.updateLastCheckDomainDate()``

    func testUpdateLastCheckDomainDate() throws {
        // Given un sdk start
        // When the last domain check date is updated
        store.updateLastCheckDomainDate()
        let savedDate = Date().timeIntervalSince1970

        // Then last domain check date should be set
        let lastCheckDate = BAParameter.object(forKey: kParametersDomainLastCheckDate, fallback: nil) as? TimeInterval
        XCTAssertEqual(lastCheckDate!, savedDate, accuracy: 0.1)
    }

    // MARK: - CanCheckOriginalDomainAvalaibility

    /// ``BADomainStore.canCheckOriginalDomainAvalaibility()``

    func testCanCheckOriginalDomainAvalaibilityNoDomainChange() throws {
        // Given no domain change
        BAParameter.removeObject(forKey: kParametersDomainKey)
        BAParameter.removeObject(forKey: kParametersDomainLastUpdateDate)

        // When check avalaibility
        let canCheck = store.canCheckOriginalDomainAvalaibility()

        // Then should be false because no domain change
        XCTAssertFalse(canCheck)
    }

    func testCanCheckOriginalDomainAvalaibilityWithOriginalDomain() throws {
        // Given current domain is the original one
        store.updateDomain(with: kParametersDomainOriginal)

        // When check avalaibility
        let canCheck = store.canCheckOriginalDomainAvalaibility()

        // Then should be false because it's the original one
        XCTAssertFalse(canCheck)
    }

    func testCanCheckOriginalDomainAvalaibilityFirstCheck() throws {
        // Given a first check
        store.updateDomain(with: BADomainManager.domains[1])

        // When check avalaibility
        let canCheck = store.canCheckOriginalDomainAvalaibility()

        // Then should be true because it's the first check
        XCTAssertTrue(canCheck)
    }

    func testCanCheckOriginalDomainAvalaibilityLessThanThrottle() throws {
        // Given multiple check
        store.updateDomain(with: BADomainManager.domains[1])
        store.updateLastCheckDomainDate()

        // When check avalaibility
        let canCheck = store.canCheckOriginalDomainAvalaibility()

        // Then should be false because it's less than the throttle condition
        XCTAssertFalse(canCheck)
    }

    func testCanCheckOriginalDomainAvalaibilityMoreThanThrottle() throws {
        // Given a check date greater than the throttler condition
        store.updateDomain(with: BADomainManager.domains[1])

        let lastCheckDate = Date().addingTimeInterval(-Double(kParametersDomainLastCheckMinDelaySecond + 1))
        BAParameter.setValue(lastCheckDate, forKey: kParametersDomainLastCheckDate, saved: true)

        // When check avalaibility
        let canCheck = store.canCheckOriginalDomainAvalaibility()

        // Then should be true because it's greater than the throttle condition
        XCTAssertTrue(canCheck)
    }
}
