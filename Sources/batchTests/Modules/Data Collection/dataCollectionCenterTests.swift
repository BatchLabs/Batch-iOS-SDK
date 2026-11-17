//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import XCTest

@testable import Batch

final class dataCollectionCenterTests: XCTestCase {
    // Mock event tracker
    let eventTracker = MockEventTracker()
    var eventTrackerOverlay: BAOverlayedInjectable?

    // Data Collection Module
    let dataCollectionCenter = BATDataCollectionCenter.sharedInstance

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Remove local config
        BAParameter.removeObject(forKey: kParametersDataCollectionConfigKey)

        // Register event tracker overlay
        eventTrackerOverlay = eventTracker.registerOverlay()
        eventTracker.reset()

        // Reset data collection config
        dataCollectionCenter.setDefaultDataCollectionConfig()

        // Reset the static device model parameter, which the config reset above doesn't touch
        SystemParameterRegistry.deviceModel.allowed = false
    }

    override func tearDown() {
        if let eventTrackerOverlay {
            BAInjection.unregisterOverlay(eventTrackerOverlay)
        }
        eventTrackerOverlay = nil
        super.tearDown()
    }

    func testSystemParametersMayHaveChanged() throws {
        // Remove initial data if necessary
        BAParameter.removeObject(forKey: SystemParameterRegistry.deviceLanguage.userDefaultKey)
        BAParameter.removeObject(forKey: SystemParameterRegistry.deviceRegion.userDefaultKey)
        BAParameter.removeObject(forKey: SystemParameterRegistry.sdkVersion.userDefaultKey)

        // Start module
        dataCollectionCenter.systemParametersMayHaveChanged()

        // Ensure removed parameters in setup has changed
        let event = eventTracker.findEvent(name: .nativeDataChanged, parameters: nil)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.parametersDictionary["device_language"] as? String, BAPropertiesCenter.value(forShortName: "dla"))
        XCTAssertEqual(event?.parametersDictionary["device_region"] as? String, BAPropertiesCenter.value(forShortName: "dre"))
        XCTAssertEqual(event?.parametersDictionary["sdk_version"] as? String, BACoreCenter.sdkVersion)
        // Unchanged params must also be present in the full snapshot
        XCTAssertEqual(event?.parametersDictionary["app_bundle_id"] as? String, BAPropertiesCenter.value(forShortName: "bid"))
    }

    func testForceSendingNativeDataChanged() throws {
        // Ensure all params are up-to-date (no pending changes)
        dataCollectionCenter.systemParametersMayHaveChanged()
        eventTracker.reset()

        // Force send even though nothing changed
        dataCollectionCenter.forceSendingNativeDataChanged()

        let event = eventTracker.findEvent(name: .nativeDataChanged, parameters: nil)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.parametersDictionary["app_bundle_id"] as? String, BAPropertiesCenter.value(forShortName: "bid"))
        XCTAssertEqual(event?.parametersDictionary["os_version"] as? String, BAPropertiesCenter.value(forShortName: "osv"))
        XCTAssertEqual(event?.parametersDictionary["sdk_version"] as? String, BACoreCenter.sdkVersion)
    }

    public func testBuildIdsForQuery() {
        var ids = dataCollectionCenter.buildIdsForQuery()
        var dataCollectDict = ids["data_collection"] as! [String: Any]

        // Ensure device_model is not in ids since disabled by default
        XCTAssertFalse(ids.keys.contains("dty"))

        // Ensure sdk version is never in ids since it is already in the URL
        XCTAssertFalse(ids.keys.contains("sdv"))

        // Ensure geoip is false by default
        XCTAssertTrue(dataCollectDict.keys.contains("geoip"))
        XCTAssertEqual(dataCollectDict["geoip"] as? Bool, false)

        // Enable all
        BatchSDK.updateAutomaticDataCollection { config in
            config.setGeoIPEnabled(true)
            config.setDeviceModelEnabled(true)
        }
        ids = dataCollectionCenter.buildIdsForQuery()
        dataCollectDict = ids["data_collection"] as! [String: Any]

        // Ensure device_model is in ids since we enabled it
        XCTAssertTrue(ids.keys.contains("dty"))

        // Ensure geoip is now true
        XCTAssertTrue(dataCollectDict.keys.contains("geoip"))
        XCTAssertEqual(dataCollectDict["geoip"] as? Bool, true)
    }

    func testUpdateAutomaticDataCollection() throws {
        // Enable all
        BatchSDK.updateAutomaticDataCollection { config in
            config.setGeoIPEnabled(true)
            config.setDeviceModelEnabled(true)
        }

        // Verify all data are sent
        XCTAssertNotNil(
            eventTracker.findEvent(
                name: .nativeDataChanged,
                parameters: [
                    "geoip_resolution": true,
                    "device_model": "Simulator - arm64",
                ]
            )
        )

        // Disable only geoip
        BatchSDK.updateAutomaticDataCollection { config in
            config.setGeoIPEnabled(false)
        }

        // Check geoip is sent
        XCTAssertNotNil(
            eventTracker.findEvent(
                name: .nativeDataChanged,
                parameters: [
                    "geoip_resolution": false
                ]
            )
        )

        // Disable only device model
        BatchSDK.updateAutomaticDataCollection { config in
            config.setDeviceModelEnabled(false)
        }

        // Check device model is sent with null
        XCTAssertNotNil(
            eventTracker.findEvent(
                name: .nativeDataChanged,
                parameters: [
                    "device_model": NSNull()
                ]
            )
        )

        eventTracker.reset()

        // Disable all
        BatchSDK.updateAutomaticDataCollection { config in
            config.setGeoIPEnabled(false)
            config.setDeviceModelEnabled(false)
        }

        // Ensure no event is sent since we already disabled it before
        XCTAssertNil(eventTracker.findEvent(name: .nativeDataChanged, parameters: nil))
    }
}
