//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

fileprivate let loggerDomain = "Profile"

@objc
public protocol BAProfileCenterProtocol {
    func identify(_ customID: String?)

    /// Track a public event. Do not add E. to the event name.
    /// This method does the validation for you and is meant to be called directly from the public API.
    /// - Throws: BATValidationError
    func trackPublicEvent(name: String, attributes: BatchEventAttributes?) throws

    /// Track a location
    func trackLocation(_ location: CLLocation)

    /// Validate event attributes
    /// Returns an array of human readable errors. If empty, the event validated successfully.
    func validateEventAttributes(_ attributes: BatchEventAttributes) -> [String]

    /// Send a profile edition operation
    func applyEditor(_ profileEditor: BATProfileEditor)

    /// Callback when a project has changed
    @objc(onProjectChanged:withNewKey:)
    func onProjectChanged(oldProjectKey: String?, newProjectKey: String?)
}

// Profile module.
// Note: This should conform to BACenterProtocol but we can't do that in swift
// as it results in a cyclic dependency. But who cares this isn't mandatory anyway
// as we can still get callbacks thanks to Obj-C being weakly typed.
@objc
@objcMembers
public class BAProfileCenter: NSObject, BAProfileCenterProtocol {
    public static let sharedInstance = BAProfileCenter()

    private static let eventNameValidationRegexpPattern = "^[a-zA-Z0-9_]{1,30}$"

    private let eventNameValidationRegexp = BATRegularExpression(pattern: BAProfileCenter.eventNameValidationRegexpPattern)

    override public init() {
        super.init()
        if eventNameValidationRegexp.regexpFailedToInitialize {
            BALogger.public(domain: loggerDomain, message: "Error while creating event name regexp. Event tracking will not be possible.")
        }
    }

    public func identify(_ customID: String?) {
        if let customID {
            guard BATProfileDataValidators.isCustomIDTooLong(customID) == false else {
                BALogger.public(domain: loggerDomain, message: "Cannot identify, Custom ID is invalid: it must not be longer than \(BATProfileDataValidators.customIDMaxLength) characters.")
                return
            }

            guard BATProfileDataValidators.isCustomIDAllowed(customID) else {
                BALogger.public(domain: loggerDomain, message: "Cannot identify, Custom ID is invalid: it cannot be only made of whitespace or contain a newline.")
                return
            }

            guard BATProfileDataValidators.isCustomIDBlocklisted(customID) == false else {
                BALogger.public(domain: loggerDomain, message: "Cannot identify, Custom ID is blocklisted: `\(customID)`. Please ensure you have correctly implemented the API.")
                return
            }
        }

        // Compatibility
        if let compatEditor = BAInjection.inject(BAInstallDataEditor.self) {
            // Reset JIT campaign caches when user identity changes to ensure campaigns are re-evaluated for the new user
            if let manager = BAInjection.inject(BALocalCampaignsManager.self), customID != BatchUser.identifier() {
                manager.resetJITCampaignsCaches()
            }

            compatEditor.setIdentifier(customID)
            compatEditor.save()
        } else {
            BALogger.error(domain: loggerDomain, message: "Failed to inject InstallDataEditor, cannot set compatibility user identifier")
        }

        sendIdentifyEvent(customID: customID)
    }

    public func trackPublicEvent(name: String, attributes: BatchEventAttributes?) throws {
        guard eventNameValidationRegexp.matches(name) else {
            throw BATSDKError.userInputValidation("Invalid event name ('\(name)'). Not tracking event.")
        }

        var attributesCopy: BatchEventAttributes? = nil

        if let attributes {
            // Copy the data so we're sure the dev does not change it between validation and tracking
            attributesCopy = (attributes.copy() as! BatchEventAttributes)
            let errors = validateEventAttributes(attributesCopy!)
            guard errors.isEmpty else {
                throw BATSDKError.userInputValidation("Failed to validate event attributes:\n\n\(errors.joined(separator: "\n"))\n\nNot tracking event.")
            }
        }

        BAInjection.inject(BATEventTracker.self)?.trackPublicEvent(name: name, attributes: attributesCopy)
    }

    public func trackLocation(_ location: CLLocation) {
        BAInjection.inject(BATEventTracker.self)?.trackLocation(location)
    }

    public func validateEventAttributes(_ attributes: BatchEventAttributes) -> [String] {
        return BATEventAttributesValidator(eventAttributes: attributes).computeValidationErrors()
    }

    public func applyEditor(_ profileEditor: BATProfileEditor) {
        let serializedEditOperations = BATProfileOperationsSerializer.serialize(profileEditor: profileEditor)

        guard !serializedEditOperations.isEmpty else {
            BALogger.debug(domain: loggerDomain, message: "Trying to send an empty profile data changed event, aborting.")
            return
        }

        BAInjection.inject(BATEventTracker.self)?.trackPrivateEvent(event: .profileDataChanged, parameters: serializedEditOperations, collapsable: false)
    }

    /// Callback method when the project key has changed.
    /// - Parameters:
    ///   - oldProjectKey: The old project key attached to this app
    ///   - newProjectKey: The new project key attached to this app
    @objc(onProjectChanged:withNewKey:)
    public func onProjectChanged(oldProjectKey: String?, newProjectKey _: String?) {
        // Trigger migrations only the first time
        if oldProjectKey == nil {
            // Custom User ID migration (aka auto login)
            if let customUserId = BAUserProfile.default().customIdentifier {
                if BACoreCenter.instance().configuration.isMigrationDisabled(for: .customID) {
                    BALogger.debug(domain: loggerDomain, message: "Automatic custom id migration has been explicitly disabled.")
                } else {
                    BALogger.public(domain: loggerDomain, message: "Automatic custom id migration.")
                    sendIdentifyEvent(customID: customUserId)
                }
            }
            // Custom data migration
            guard !BACoreCenter.instance().configuration.isMigrationDisabled(for: .customData) else {
                BALogger.debug(domain: loggerDomain, message: "Automatic custom data migration has been explicitly disabled.")
                return
            }
            BALogger.public(domain: loggerDomain, message: "Automatic custom data migration.")
            migrateCustomData()
        }
    }

    /// Migrate installation's custom data to Profile.
    private func migrateCustomData() {
        // Instantiate profile editor
        let profileEditor = BATProfileEditor()

        // Add custom language
        if let customLanguage = BAUserProfile.default().language {
            try? profileEditor.setLanguage(customLanguage)
        }

        // Add custom region
        if let customRegion = BAUserProfile.default().region {
            try? profileEditor.setRegion(customRegion)
        }
        BAUserDataManager.sharedQueue().async {
            let datasource = BAInjection.inject(BAUserDatasourceProtocol.self)

            // Add custom attributes
            if let attributes = datasource?.attributes() {
                attributes.forEach { (key: String, attribute: BAUserAttribute) in
                    let untypedKey = String(key.dropFirst(2))
                    switch attribute.type {
                        case BAUserAttributeType.string:
                            if let stringValue = attribute.value as? String {
                                try? profileEditor.setCustom(stringAttribute: stringValue, forKey: untypedKey)
                            }
                        case BAUserAttributeType.longLong:
                            if let longLongValue = attribute.value as? Int64 {
                                try? profileEditor.setCustom(int64Attribute: longLongValue, forKey: untypedKey)
                            }
                        case BAUserAttributeType.double:
                            if let doubleValue = attribute.value as? Double {
                                try? profileEditor.setCustom(doubleAttribute: doubleValue, forKey: untypedKey)
                            }
                        case BAUserAttributeType.date:
                            if let dateValue = attribute.value as? NSDate {
                                try? profileEditor.setCustom(dateAttribute: dateValue, forKey: untypedKey)
                            }
                        case BAUserAttributeType.bool:
                            if let boolValue = attribute.value as? Bool {
                                try? profileEditor.setCustom(boolAttribute: boolValue, forKey: untypedKey)
                            }
                        case BAUserAttributeType.URL:
                            if let urlValue = attribute.value as? URL {
                                try? profileEditor.setCustom(urlAttribute: urlValue, forKey: untypedKey)
                            }
                        case .deleted:
                            break
                        @unknown default: break
                    }
                }
            }
            // Add custom tags
            if let tags = datasource?.tagCollections() {
                tags.forEach { (key: String, value: Set<String>) in
                    try? profileEditor.setCustom(stringArrayAttribute: Array(value), forKey: key)
                }
            }
            // Serialize and send event
            self.applyEditor(profileEditor)
        }
    }

    func sendIdentifyEvent(customID: String?) {
        guard let installID = BatchUser.installationID, !installID.isEmpty else {
            BALogger.error(domain: loggerDomain, message: "Could not track identify event: nil Installation ID")
            return
        }

        // Identifiers is split and not embedded as type inference for dictionaries
        // compiles very slowly in Swift
        let identifiers: [AnyHashable: Any] = [
            "custom_id": customID ?? NSNull(),
            "install_id": installID,
        ]
        let eventParameters: [AnyHashable: Any] = [
            "identifiers": identifiers,
        ]
        BAInjection.inject(BATEventTracker.self)?.trackPrivateEvent(event: .profileIdentify, parameters: eventParameters, collapsable: false)
    }
}
