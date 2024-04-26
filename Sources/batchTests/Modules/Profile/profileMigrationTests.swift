//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import XCTest

class profileMigrationTests: XCTestCase {
    // Mock event tracker
    let eventTracker = MockEventTracker()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Remove project key
        BAParameter.removeObject(forKey: kParametersProjectKey)

        // Register event tracker overlay
        let _ = eventTracker.registerOverlay()
    }

    override func tearDown() {
        // reset event tracker
        eventTracker.reset()
    }

    func testOnProjectChanged() throws {
        let profileCenterMock = TestProfileCenter()
        BAInjection.overlayProtocol(BAProfileCenterProtocol.self, returnedInstance: profileCenterMock)
        XCTAssertFalse(profileCenterMock.onProjectChangedHasBeenCalled)

        triggerMigrationsFromUserDataService()

        XCTAssertTrue(profileCenterMock.onProjectChangedHasBeenCalled)
    }

    func testCustomIDMigration() throws {
        let expectedCustomID = "fake-test-custom-id"

        // Add custom id from compat
        BAUserProfile.default().customIdentifier = expectedCustomID

        // trigger fake project changed
        triggerMigrationsFromUserDataService()

        // Ensure identify event is sent
        XCTAssertNotNil(eventTracker.findEvent(name: .profileIdentify, parameters: [
            "identifiers": [
                "custom_id": expectedCustomID,
                "install_id": BatchUser.installationID!,
            ],
        ]))
    }

    func testCustomIDMigrationDisabled() throws {
        let expectedCustomID = "fake-test-custom-id"

        // Add custom id from compat
        BAUserProfile.default().customIdentifier = expectedCustomID

        BatchSDK.setDisabledMigrations([.customID])

        // trigger fake project changed
        triggerMigrationsFromUserDataService()

        // Ensure identify event is sent
        XCTAssertNil(eventTracker.findEvent(name: .profileIdentify, parameters: nil))
    }

    func testCustomDataMigration() throws {
        // Add custom id from compat
        BAUserProfile.default().language = "fr"
        BAUserProfile.default().region = "FR"

        let datasource = BAUserSQLiteDatasource.instance()
        // Clearing tables to avoid parasites data from other tests
        datasource?.clear()
        datasource?.acquireTransactionLock(withChangeset: 1)
        datasource?.setStringAttribute("teststring", forKey: "string")
        datasource?.setLongLongAttribute(3, forKey: "long")
        datasource?.setURLAttribute(URL(string: "https://batch.com/pricing")!, forKey: "url")
        datasource?.addTag("tag1", toCollection: "testco")
        datasource?.commitTransaction()

        // Force real data source
        BAInjection.overlayProtocol(BAUserDatasourceProtocol.self, returnedInstance: datasource)

        // trigger fake project changed
        triggerMigrationsFromUserDataService()

        // waiting dispatch queue
        waitForQueueLoop(queue: BAUserDataManager.sharedQueue())

        let event = eventTracker.findEvent(name: .profileDataChanged, parameters: nil)
        XCTAssertEqual(event?.parametersDictionary["language"] as? String, "fr")
        XCTAssertEqual(event?.parametersDictionary["region"] as? String, "FR")
        // TODO: fix this test on CI
//        let customAttributes = event?.parametersDictionary["custom_attributes"] as? NSDictionary
//        XCTAssertEqual(customAttributes?["string.s"] as? String, "teststring")
//        XCTAssertEqual(customAttributes?["long.i"] as? Int64, 3)
//        XCTAssertEqual(customAttributes?["url.u"] as? String, "https://batch.com/pricing")
//
//        let tags = ["tag1"]
//        XCTAssertEqual(customAttributes?["testco.a"] as? [String], tags)
    }

    func testCustomDataMigrationDisabled() throws {
        let eventTracker = MockEventTracker()
        let _ = eventTracker.registerOverlay()

        // Add custom id from compat
        BAUserProfile.default().language = "fr"

        BatchSDK.setDisabledMigrations([.customData])

        // trigger fake project changed
        triggerMigrationsFromUserDataService()

        // Ensure identify event is sent
        XCTAssertNil(eventTracker.findEvent(name: .profileDataChanged, parameters: nil))
    }

    private func triggerMigrationsFromUserDataService() {
        let fakeResponse: [AnyHashable: Any]! = [
            "id": "test-id",
            "action": "ok",
            "project_key": "project_12345678",
        ]
        let userDataService: BAQueryWebserviceClientDelegate = BAUserDataCheckServiceDelegate()
        let queryResponse: BAWSResponse = BAWSResponseAttributesCheck(response: fakeResponse)
        let datasource: BAQueryWebserviceClientDatasource = BAUserDataCheckServiceDatasource(version: 0, transactionID: "transac")
        let client = BAQueryWebserviceClient(datasource: datasource, delegate: nil)
        userDataService.webserviceClient(client, didSucceedWith: [queryResponse])
    }
}
