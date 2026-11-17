//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import XCTest

@testable import Batch

class profileMigrationTests: XCTestCase {
    // Mock event tracker
    let eventTracker = MockEventTracker()
    var eventTrackerOverlay: BAOverlayedInjectable?

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Remove project key
        BAParameter.removeObject(forKey: kParametersProjectKey)

        // Register event tracker overlay
        eventTrackerOverlay = eventTracker.registerOverlay()
    }

    override func tearDown() {
        // The custom data migration tracks its event from the user data queue: let it land on our
        // tracker before unregistering it
        waitForQueueLoop(queue: BAUserDataManager.sharedQueue())
        // reset event tracker
        eventTracker.reset()
        if let eventTrackerOverlay {
            BAInjection.unregisterOverlay(eventTrackerOverlay)
        }
        eventTrackerOverlay = nil
        BAParameter.removeObject(forKey: kParametersProjectKey)
        // Migrations settings and the compat custom ID are process-wide, don't leak them into other tests
        BatchSDK.setDisabledMigrations([])
        BAUserProfile.default().customIdentifier = nil
        super.tearDown()
    }

    func testOnProjectChanged() throws {
        let profileCenterMock = TestProfileCenter()
        let profileCenterOverlay = BAInjection.overlayProtocol(BAProfileCenterProtocol.self, returnedInstance: profileCenterMock)
        defer { BAInjection.unregisterOverlay(profileCenterOverlay) }
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
        XCTAssertNotNil(
            eventTracker.findEvent(
                name: .profileIdentify,
                parameters: [
                    "identifiers": [
                        "custom_id": expectedCustomID,
                        "install_id": BatchUser.installationID!,
                    ]
                ]
            )
        )
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
        let datasourceOverlay = BAInjection.overlayProtocol(BAUserDatasourceProtocol.self, returnedInstance: datasource)
        defer { BAInjection.unregisterOverlay(datasourceOverlay) }

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
        let eventTrackerOverlay = eventTracker.registerOverlay()
        defer { BAInjection.unregisterOverlay(eventTrackerOverlay) }

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
