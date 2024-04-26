//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

/// System Parameter shortname used in legacy webservices as query's ids
enum SystemParameterShortname: String {
    case installationID = "di"
    case customIdentifier = "cus"
    case deviceRegion = "dre"
    case deviceLanguage = "dla"
    case deviceTimezone = "dtz"
    case deviceDate = "da"
    case sdkInstallDate = "did"
    case deviceModel = "dty"
    case deviceOSVersion = "osv"
    case bundleID = "bid"
    case applicationID = "pid"
    case platform = "pl"
    case apiLevel = "lvl"
    case messagingAPILevel = "mlvl"
    case appVersion = "apv"
    case versionCode = "apc"
    case pluginVersion = "plv"
    case bridgeVersion = "brv"
    case sessionIdentifier = "s"

    /// Event serialized name computed property
    var serializedName: String? {
        switch self {
            case .installationID:
                return nil
            case .customIdentifier:
                return nil
            case .applicationID:
                return nil
            case .deviceDate:
                return nil
            case .platform:
                return nil
            case .sessionIdentifier:
                return nil
            case .deviceRegion:
                return "device_region"
            case .deviceLanguage:
                return "device_language"
            case .deviceTimezone:
                return "device_timezone"
            case .sdkInstallDate:
                return "device_installation_date"
            case .deviceModel:
                return "device_model"
            case .deviceOSVersion:
                return "os_version"
            case .bundleID:
                return "app_bundle_id"
            case .apiLevel:
                return "sdk_api_level"
            case .messagingAPILevel:
                return "sdk_m_api_level"
            case .appVersion:
                return "app_version"
            case .versionCode:
                return "app_build_number"
            case .pluginVersion:
                return "plugin_version"
            case .bridgeVersion:
                return "bridge_version"
        }
    }
}

/// System parameter registry
enum SystemParameterRegistry {
    // MARK: Unwatched Parameters

    /// Installation identifier
    public static let installationID = BATSystemParameter(shortname: .installationID, watched: false, allowed: true)

    /// Custom user identier
    public static let customUserID = BATSystemParameter(shortname: .customIdentifier, watched: false, allowed: true)

    /// User's session identier
    public static let sessionID = BATSystemParameter(shortname: .sessionIdentifier, watched: false, allowed: true)

    /// Current device date
    public static let deviceDate = BATSystemParameter(shortname: .deviceDate, watched: false, allowed: true)

    /// Application  id
    public static let applicationID = BATSystemParameter(shortname: .applicationID, watched: false, allowed: true)

    /// Platform
    public static let platform = BATSystemParameter(shortname: .platform, watched: false, allowed: true)

    // MARK: Watched Parameters

    /// Device region
    public static let deviceRegion = BATSystemParameter(shortname: .deviceRegion, watched: true, allowed: true)

    /// Device Language
    public static let deviceLanguage = BATSystemParameter(shortname: .deviceLanguage, watched: true, allowed: true)

    /// Device timezone
    public static let deviceTimezone = BATSystemParameter(shortname: .deviceTimezone, watched: true, allowed: true)

    /// SDK Install date
    public static let sdkInstallDate = BATSystemParameter(shortname: .sdkInstallDate, watched: true, allowed: true)

    /// Device model
    public static let deviceModel = BATSystemParameter(shortname: .deviceModel, watched: true, allowed: BATDataCollectionCenter.sharedInstance.dataCollectionConfig.deviceModelEnabled()?.boolValue ?? false)

    /// Device OS version
    public static let deviceOSVersion = BATSystemParameter(shortname: .deviceOSVersion, watched: true, allowed: true)

    /// Bundle id
    public static let bundleID = BATSystemParameter(shortname: .bundleID, watched: true, allowed: true)

    /// API level
    public static let apiLevel = BATSystemParameter(shortname: .apiLevel, watched: true, allowed: true)

    /// Messaging API level
    public static let messagingAPILevel = BATSystemParameter(shortname: .messagingAPILevel, watched: true, allowed: true)

    // App version
    public static let appVersion = BATSystemParameter(shortname: .appVersion, watched: true, allowed: true)

    // App version code
    public static let versionCode = BATSystemParameter(shortname: .versionCode, watched: true, allowed: true)

    // Plugin version
    public static let pluginVersion = BATSystemParameter(shortname: .pluginVersion, watched: true, allowed: true)

    // Bridge version
    public static let bridgeVersion = BATSystemParameter(shortname: .bridgeVersion, watched: true, allowed: true)

    /// All registred system parameters
    public static let all = [installationID, customUserID, sessionID, deviceDate, deviceRegion, deviceLanguage, deviceTimezone, sdkInstallDate, deviceModel, deviceOSVersion, bundleID, applicationID, platform, apiLevel, messagingAPILevel, appVersion, versionCode, pluginVersion, bridgeVersion]
}

/// System Parameter
class BATSystemParameter {
    /// Shortname of the parameter
    let shortname: SystemParameterShortname

    /// Whether this parameter is watched
    let watched: Bool

    /// Whether this pameter is allowed to be sent
    var allowed: Bool

    /// Init method
    init(shortname: SystemParameterShortname, watched: Bool, allowed: Bool) {
        self.shortname = shortname
        self.watched = watched
        self.allowed = allowed
    }

    /// Get the current value
    var value: String? {
        return BAPropertiesCenter.value(forShortName: self.shortname.rawValue)
    }

    /// Get last value read from NSUserDefault
    var lastValue: String? {
        return BAParameter.object(forKey: self.userDefaultKey, fallback: nil) as! String?
    }

    /// Compute key for user default storage
    var userDefaultKey: String {
        return kParametersSystemParameterPrefix + self.shortname.rawValue
    }

    /// Detect if the values has changed since the last time we get it.
    /// This will save the new value if it changed
    var hasChanged: Bool {
        // Ensure the parameter is watched
        guard watched else {
            return false
        }
        // Getting current value of the parameter
        let currentValue = self.value

        // Check if value has changed since the last time
        let hasChanged = self.lastValue != currentValue

        if hasChanged {
            // Saving new value (remove if null)
            if currentValue == nil {
                BAParameter.removeObject(forKey: self.userDefaultKey)
            } else {
                BAParameter.setValue(currentValue!, forKey: self.userDefaultKey, saved: true)
            }
        }
        return hasChanged
    }
}
