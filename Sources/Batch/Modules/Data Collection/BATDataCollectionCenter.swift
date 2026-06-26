//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

fileprivate let loggerDomain = "DataCollection"

fileprivate let geoipUserDefaultKey = "geoip"
fileprivate let deviceModelUserDefaultKey = "deviceModel"

/// Data Collection module.
@objcMembers
public class BATDataCollectionCenter: NSObject {
    /// Singleton instance
    public static let sharedInstance = BATDataCollectionCenter()

    /// The current data collection cofiguration
    public let dataCollectionConfig = BatchDataCollectionConfig()

    // Constructor
    override private init() {
        super.init()
        // Load data collection config from user defaults
        loadDataCollectionConfig()
    }

    /// Batch did started
    public static func batchDidStart() {
        // Check if some parameters have changed
        BATDataCollectionCenter.sharedInstance.systemParametersMayHaveChanged()
    }

    /// Check if some system parameters has changed
    /// Method visible for testing
    public func systemParametersMayHaveChanged() {
        var anyChanged = false
        for param in SystemParameterRegistry.all where param.watched {
            if param.hasChanged {
                anyChanged = true
            }
        }
        guard anyChanged else {
            BALogger.debug(domain: loggerDomain, message: "Native data has not changed.")
            return
        }
        BALogger.debug(domain: loggerDomain, message: "Some native data has changed, sending all native data.")
        sendNativeDataChangedEvent(buildAllNativeData())
    }

    /// Force sending a _NATIVE_DATA_CHANGED event with all parameters, regardless of changes.
    /// Used during profile migration to ensure native data is up-to-date on the backend.
    public func forceSendingNativeDataChanged() {
        for param in SystemParameterRegistry.all where param.watched {
            _ = param.hasChanged
        }
        BALogger.debug(domain: loggerDomain, message: "Forcing native data send.")
        sendNativeDataChangedEvent(buildAllNativeData())
    }

    /// Build the full native data payload with all watched parameters.
    /// Sends the current value for allowed parameters, or NSNull for not-allowed ones.
    private func buildAllNativeData() -> [AnyHashable: Any] {
        var data: [AnyHashable: Any] = [:]
        for param in SystemParameterRegistry.all where param.watched {
            guard let key = param.shortname.serializedName else {
                continue
            }
            if param.allowed, let value = param.lastValue {
                data[key] = value
            } else {
                data[key] = NSNull()
            }
        }
        return data
    }

    /// Build identifiers for query webservices
    public func buildIdsForQuery() -> [AnyHashable: Any] {
        var ids: [AnyHashable: Any] = [:]

        // Adding system parameters
        for param in SystemParameterRegistry.all where param.allowed {
            guard let value = param.value, !value.isEmpty else {
                continue
            }
            ids[param.shortname.rawValue] = value
        }
        // Adding data collection
        ids["data_collection"] = ["geoip": dataCollectionConfig.geoIPEnabled()?.boolValue ?? false]

        return ids
    }

    /// Update the current data collection configuration
    public func updateDataCollectionConfig(editor: BatchDataCollectionConfigEditor) {
        let config = BatchDataCollectionConfig()
        editor(config)
        self.onDataCollectionConfigChanged(config)
    }

    /// Handle modification of the data collection config
    private func onDataCollectionConfigChanged(_ config: BatchDataCollectionConfig) {
        // Ensure the config has changed
        guard !BATDataCollectionUtils.areConfigsEquals(config, dataCollectionConfig) else {
            BALogger.debug(domain: loggerDomain, message: "Automatic data collection config hasn't changed.")
            return
        }

        var data: [AnyHashable: Any] = [:]

        if let geoIPEnabled = config.geoIPEnabled(), geoIPEnabled != self.dataCollectionConfig.geoIPEnabled() {
            data["geoip_resolution"] = geoIPEnabled.boolValue
            self.dataCollectionConfig.setGeoIPEnabled(geoIPEnabled.boolValue)
        }

        if let deviceModelEnabled = config.deviceModelEnabled(), deviceModelEnabled != self.dataCollectionConfig.deviceModelEnabled() {
            SystemParameterRegistry.deviceModel.allowed = deviceModelEnabled.boolValue
            if let key = SystemParameterRegistry.deviceModel.shortname.serializedName {
                data[key] = deviceModelEnabled.boolValue ? SystemParameterRegistry.deviceModel.value : NSNull()
            }
            self.dataCollectionConfig.setDeviceModelEnabled(deviceModelEnabled.boolValue)
        }
        // Sending native data changed event
        sendNativeDataChangedEvent(data)

        // Persist new config
        self.persistDataCollectionConfig()
    }

    /// Send a native data changed event with given data as paremeters
    private func sendNativeDataChangedEvent(_ data: [AnyHashable: Any]) {
        let eventTracker: BATEventTracker? = BAInjection.inject(BATEventTracker.self)
        eventTracker?.trackPrivateEvent(event: .nativeDataChanged, parameters: data, collapsable: false)
    }

    /// Persist the current data collection config as NSDictionnary into UserDefault
    private func persistDataCollectionConfig() {
        let dictionnaryConfig = [
            geoipUserDefaultKey: dataCollectionConfig.geoIPEnabled(),
            deviceModelUserDefaultKey: dataCollectionConfig.deviceModelEnabled(),
        ]
        BAParameter.setValue(dictionnaryConfig, forKey: kParametersDataCollectionConfigKey, saved: true)
    }

    /// Load data collection config from UserDefault
    private func loadDataCollectionConfig() {
        if let dictionnaryConfig = BAParameter.object(forKey: kParametersDataCollectionConfigKey, fallback: nil) as? [String: Any] {
            self.dataCollectionConfig.setGeoIPEnabled((dictionnaryConfig[geoipUserDefaultKey] as? NSNumber)?.boolValue ?? false)
            self.dataCollectionConfig.setDeviceModelEnabled((dictionnaryConfig[deviceModelUserDefaultKey] as? NSNumber)?.boolValue ?? false)
        } else {
            self.setDefaultDataCollectionConfig()
        }
    }

    /// Set default value for the current data collection configuration
    /// Method visible for testing
    public func setDefaultDataCollectionConfig() {
        self.dataCollectionConfig.setGeoIPEnabled(false)
        self.dataCollectionConfig.setDeviceModelEnabled(false)
    }
}
