//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import XCTest

final class dataCollectionCenterTests: XCTestCase {
    // Mock event tracker
    let eventTracker = MockEventTracker()

    // Data Collection Module
    let dataCollectionCenter = BATDataCollectionCenter.sharedInstance

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Remove local config
        BAParameter.removeObject(forKey: kParametersDataCollectionConfigKey)

        // Register event tracker overlay
        let _ = eventTracker.registerOverlay()
        eventTracker.reset()

        // Reset data collection config
        dataCollectionCenter.setDefaultDataCollectionConfig()
    }

    func testSystemParametersMayHaveChanged() throws {
        // Remove initial data if necessary
        BAParameter.removeObject(forKey: SystemParameterRegistry.deviceLanguage.userDefaultKey)
        BAParameter.removeObject(forKey: SystemParameterRegistry.deviceRegion.userDefaultKey)

        // Start module
        dataCollectionCenter.systemParametersMayHaveChanged()

        // Ensure removed parameters in setup has changed
        let event = eventTracker.findEvent(name: .nativeDataChanged, parameters: nil)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.parametersDictionary["device_language"] as? String, BAPropertiesCenter.value(forShortName: "dla"))
        XCTAssertEqual(event?.parametersDictionary["device_region"] as? String, BAPropertiesCenter.value(forShortName: "dre"))
    }

    public func testBuildIdsForQuery() {
        var ids = dataCollectionCenter.buildIdsForQuery()
        var dataCollectDict = ids["data_collection"] as! [String: Any]

        // Ensure device_model is not in ids since disabled by default
        XCTAssertFalse(ids.keys.contains("dty"))

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
        XCTAssertNotNil(eventTracker.findEvent(name: .nativeDataChanged, parameters: [
            "geoip_resolution": true,
            "device_model": "Simulator - arm64",
        ]))

        // Disable only geoip
        BatchSDK.updateAutomaticDataCollection { config in
            config.setGeoIPEnabled(false)
        }

        // Check geoip is sent
        XCTAssertNotNil(eventTracker.findEvent(name: .nativeDataChanged, parameters: [
            "geoip_resolution": false,
        ]))

        // Disable only device model
        BatchSDK.updateAutomaticDataCollection { config in
            config.setDeviceModelEnabled(false)
        }

        // Check device model is sent with null
        XCTAssertNotNil(eventTracker.findEvent(name: .nativeDataChanged, parameters: [
            "device_model": NSNull(),
        ]))

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
