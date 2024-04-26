//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

struct BATDataCollectionUtils {
    /// Method to compare two batch data collection config.
    ///
    /// Globally used to check if a new config is different from the old one
    /// So if one of the configs field is null, we consider it as equal because we consider a null field as an unchanged value from the previous configuration.
    /// - Parameters:
    ///   - config:  The new config
    ///   - config2: The old config
    /// - Returns: True if config are unchanged. Example:  null, true, false, et false, true, false will return true..
    public static func areConfigsEquals(_ config: BatchDataCollectionConfig, _ config2: BatchDataCollectionConfig) -> Bool {
        var sameGeoip = true
        var sameDeviceModel = true

        if let config1GeoIpEnabled = config.geoIPEnabled(), let config2GeoIpEnabled = config2.geoIPEnabled() {
            sameGeoip = config1GeoIpEnabled == config2GeoIpEnabled
        }

        if let config1DeviceModelEnabled = config.deviceModelEnabled(), let config2DeviceModelEnabled = config2.deviceModelEnabled() {
            sameDeviceModel = config1DeviceModelEnabled == config2DeviceModelEnabled
        }
        return sameGeoip && sameDeviceModel
    }
}
