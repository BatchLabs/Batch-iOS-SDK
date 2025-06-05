//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import XCTest

final class BADomainManagerTests: XCTestCase {
    // MARK: - Parameters

    static let batch = "batch.com"
    static let test_kParametersWebserviceBase = "https://ws.%@"
    static let test_kParametersMetricWebserviceBase = "https://wsmetrics.%@/api-sdk"

    var mockStore: MockBADomainStore = .init()
    let store: BADomainStore = .init()
    lazy var manager: BADomainManager = .init(store: mockStore, isFeatureActivated: true)

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        manager.resetDomainToOriginal()
    }

    // MARK: - NextDomain

    /// ``BADomainManager.nextDomain()``

    func testNextDomain() throws {
        // Given orignal domain to kParametersDomainOriginal
        // When we get the next domain
        let nextDomain = manager.nextDomain()

        // Then the next domain should be the second element of `BADomainManager.domains`
        XCTAssertEqual(nextDomain, BADomainManager.domains[1])
    }

    func testNextDomainOutOfRange() throws {
        // Given a current domain
        store.updateDomain(with: BADomainManager.domains[1])

        // When we get the next domain
        let nextDomain = manager.nextDomain()

        // Then next domain should be the current one
        XCTAssertEqual(nextDomain, BADomainManager.domains[1])
    }

    func testNextDomainWithUnknonCurrentDomain() throws {
        // Given a current domain to batchy.xyz
        store.updateDomain(with: "batchy.xyz")

        // When we get the next domain
        let nextDomain = manager.nextDomain()

        // Then the new domain should be the orignal one
        XCTAssertEqual(nextDomain, BADomainManager.domains[0])
        XCTAssertEqual(nextDomain, kParametersDomainOriginal)
    }

    // MARK: UpdateDomainIfNeeded

    /// ``BADomainManager.updateDomainIfNeeded()``

    func testUpdateDomainIfNeededNoPreviousError() throws {
        // Given first error
        let exp = expectation(description: "Domain error count should be incremented")

        mockStore.incrementErrorCountCallback = { count in
            XCTAssertEqual(count, 1)

            exp.fulfill()
        }

        // When update domain if needed
        manager.updateDomainIfNeeded()

        // Then domain error should be incremented
        waitForExpectations(timeout: 1)
    }

    func testUpdateDomainIfNeededWithPreviousErrorLessThanThrottle() throws {
        // Given previous error
        store.incrementErrorCount()

        mockStore.incrementErrorCountCallback = { _ in
            // Then domain error should be incremented
            XCTFail("Thottle check should return before incrementing error count")
        }

        // When update domain if needed
        manager.updateDomainIfNeeded()
    }

    func testUpdateDomainIfNeededWithPreviousErrorGreaterThanThrottle() throws {
        // Given previous error
        store.incrementErrorCount()
        BAParameter.setValue(Date().advanced(by: -Double(kParametersDomainErrorMinDelaySecond + 1)).timeIntervalSince1970, forKey: kParametersDomainErrorUpdateDate, saved: true)

        let exp = expectation(description: "Domain error count should be incremented")

        mockStore.incrementErrorCountCallback = { count in
            XCTAssertEqual(count, 2)

            exp.fulfill()
        }

        mockStore.updateDomainCallback = {
            // Then domain error should be incremented but
            XCTFail("Thottle check should return before incrementing error count")
        }

        // When update domain if needed
        manager.updateDomainIfNeeded()

        // Then domain error should be incremented
        waitForExpectations(timeout: 1)
    }

    func testUpdateDomainIfNeededWithPreviousErrorsReachedLimit() throws {
        // Given previous errors
        store.incrementErrorCount()
        store.incrementErrorCount()
        BAParameter.setValue(Date().advanced(by: -Double(kParametersDomainErrorMinDelaySecond + 1)).timeIntervalSince1970, forKey: kParametersDomainErrorUpdateDate, saved: true)

        let exp = expectation(description: "Domain error count should be incremented")
        exp.expectedFulfillmentCount = 2

        mockStore.incrementErrorCountCallback = { count in
            // Then domain error should be incremented
            XCTAssertEqual(count, 3)

            exp.fulfill()
        }

        mockStore.updateDomainCallback = {
            // Then domain should be updated
            exp.fulfill()
        }

        // When update domain if needed
        manager.updateDomainIfNeeded()

        waitForExpectations(timeout: 1)
    }

    // MARK: - Url

    /// ``BADomainStore.url(for:overrideWithOriginal:)``

    func testUrlWebService() throws {
        // Given a current domain
        // When retrive url for webservice
        let url = manager.url(
            for: .web,
            overrideWithOriginal: false
        )

        // Then url should be `https://ws.batch.com`
        XCTAssertEqual(
            url,
            String(format: Self.test_kParametersWebserviceBase, Self.batch)
        )
    }

    func testUrlMetrics() throws {
        // Given a current domain
        // When retrive url for metrics
        let url = manager.url(
            for: .metric,
            overrideWithOriginal: false
        )

        // Then url should be `https://wsmetrics.batch.com/api-sdk`
        XCTAssertEqual(
            url,
            String(
                format: Self.test_kParametersMetricWebserviceBase,
                Self.batch
            )
        )
    }

    func testUrlWebServiceWithNextDomain() throws {
        // Given a next domain
        let nextDomain = BADomainManager.domains[1]
        store.updateDomain(with: nextDomain)

        // When retrive url for webservice
        let url = manager.url(
            for: .web,
            overrideWithOriginal: false
        )

        // Then url should be `https://ws.\(nextDomain)`
        XCTAssertEqual(
            url,
            String(format: Self.test_kParametersWebserviceBase, nextDomain)
        )
    }

    func testUrlMetricsWithNextDomain() throws {
        // Given a next domain
        let nextDomain = BADomainManager.domains[1]
        store.updateDomain(with: nextDomain)

        // When retrive url for metrics
        let url = manager.url(
            for: .metric,
            overrideWithOriginal: false
        )

        // Then url should be `https://wsmetrics\(nextDomain)/api-sdk`
        XCTAssertEqual(
            url,
            String(
                format: Self.test_kParametersMetricWebserviceBase,
                nextDomain
            )
        )
    }

    func testUrlWebServiceWithNextDomainAndOverride() throws {
        // Given a next domain
        store.updateDomain(with: BADomainManager.domains[1])

        // When retrive url for webservice
        let url = manager.url(
            for: .web,
            overrideWithOriginal: true
        )

        // Then url should be `https://ws.batch.com`
        XCTAssertEqual(
            url,
            String(format: Self.test_kParametersWebserviceBase, Self.batch)
        )
    }

    func testUrlMetricsWithNextDomainAndOverride() throws {
        // Given a next domain
        store.updateDomain(with: BADomainManager.domains[1])

        // When retrive url for metrics
        let url = manager.url(
            for: .metric,
            overrideWithOriginal: true
        )

        // Then url should be `https://wsmetrics.batch.com/api-sdk`
        XCTAssertEqual(
            url,
            String(
                format: Self.test_kParametersMetricWebserviceBase,
                Self.batch
            )
        )
    }

    func testFeatureFlagNotActivated() throws {
        // Given the feature disabled
        let nextDomain = BADomainManager.domains[1]
        store.updateDomain(with: nextDomain)
        let manager: BADomainManager = .init(store: store, isFeatureActivated: false)

        // When retrive url for webservice
        let url = manager.url(for: .web, overrideWithOriginal: false)

        // Then url should be `https://ws.batch.com`
        XCTAssertEqual(
            url,
            String(
                format: Self.test_kParametersWebserviceBase,
                Self.batch
            )
        )
    }
}
