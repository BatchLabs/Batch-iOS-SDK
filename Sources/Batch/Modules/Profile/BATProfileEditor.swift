//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

fileprivate enum Maximums {
    static let stringArrayItems = 25
    static let stringLength = 64
    static let urlLength = 2048
}

fileprivate enum Consts {
    static let attributeNamePattern = "^[a-zA-Z0-9_]{1,30}$"
}

/// Protocol that exposes BATProfileEditor's state, so that it can be serialized
protocol BATSerializableProfileEditorProtocol {
    var email: (any BATProfileAttributeOperation)? { get }

    var emailMarketingSubscription: BATProfileEditorEmailSubscriptionState? { get }

    var phoneNumber: (any BATProfileAttributeOperation)? { get }

    var smsMarketingSubscription: BATProfileEditorSMSSubscriptionState? { get }

    var language: (any BATProfileAttributeOperation)? { get }

    var region: (any BATProfileAttributeOperation)? { get }

    var customAttributes: [String: any BATProfileAttributeOperation] { get }
}

/// Protocol that exposes BATProfileEditor's setters that are available in the legacy install data world
@objc
public protocol BATInstallDataEditorCompatibilityProtocol {
    @objc
    func setLanguage(_ value: String?) throws

    @objc
    func setRegion(_ value: String?) throws

    @objc
    func add(value: String, toArray attributeKey: String) throws

    @objc
    func remove(value: String, fromArray attributeKey: String) throws

    @objc(setCustomStringArrayAttribute:forKey:error:)
    func setCustom(stringArrayAttribute: [String], forKey attributeKey: String) throws

    @objc(setCustomBoolAttribute:forKey:error:)
    func setCustom(boolAttribute: Bool, forKey attributeKey: String) throws

    @objc(setCustomInt64Attribute:forKey:error:)
    func setCustom(int64Attribute: Int64, forKey attributeKey: String) throws

    @objc(setCustomDoubleAttribute:forKey:error:)
    func setCustom(doubleAttribute: Double, forKey attributeKey: String) throws

    @objc(setCustomStringAttribute:forKey:error:)
    func setCustom(stringAttribute: String, forKey attributeKey: String) throws

    @objc(setCustomDateAttribute:forKey:error:)
    func setCustom(dateAttribute: NSDate, forKey attributeKey: String) throws

    @objc(setCustomURLAttribute:forKey:error:)
    func setCustom(urlAttribute: URL, forKey attributeKey: String) throws

    @objc
    func deleteCustomAttribute(forKey attributeKey: String) throws

    @objc
    func consume()
}

/// BATProfileEditor holds multiple profile update operation
/// Serialization occurs in another class
@objc
public class BATProfileEditor: NSObject, BATSerializableProfileEditorProtocol, NSCopying {
    private let attributeNameRegexp: BATRegularExpression = .init(pattern: Consts.attributeNamePattern)

    private(set) var email: (any BATProfileAttributeOperation)?

    private(set) var emailMarketingSubscription: BATProfileEditorEmailSubscriptionState?

    private(set) var phoneNumber: (any BATProfileAttributeOperation)?

    private(set) var smsMarketingSubscription: BATProfileEditorSMSSubscriptionState?

    private(set) var language: (any BATProfileAttributeOperation)?

    private(set) var region: (any BATProfileAttributeOperation)?

    private(set) var customAttributes: [String: any BATProfileAttributeOperation] = [:]

    // Delegate that will be informed of all operations so that it can perform them
    // on the install data.
    // Its methods are only called if validation passed.
    private var compatibilityDelegate: BATInstallDataEditorCompatibilityProtocol?

    @objc
    public func enableInstallCompatibility() {
        if let compatibility = BATProfileInstallDataCompatibility() {
            compatibilityDelegate = compatibility
        } else {
            BALogger.error(domain: "ProfileEditor", message: "Could not instanciate compatibility delegate. Install data will NOT be modified.")
        }
    }

    // Has this editor been consumed?
    // If yes, it cannot be used to edit further attributes
    @objc
    public var consumed: Bool = false

    @objc
    public func setEmail(_ value: String?) throws {
        try checkIfConsumed()

        if !isProfileIdentified() {
            throw BatchProfileError(code: .editorInvalidValue, reason: "Emails cannot be set on a profile if it has not been identified first. Please call 'BatchProfile.idenfity()' with a non nil value beforehand.")
        }

        if let value {
            let baseError = "Cannot set email address:"

            if BATProfileDataValidators.isEmailTooLong(value) {
                throw BatchProfileError(code: .editorInvalidValue, reason: "\(baseError) address cannot be longer than \(BATProfileDataValidators.emailMaxLength) characters")
            }

            if !BATProfileDataValidators.isValidEmail(value) {
                throw BatchProfileError(code: .editorInvalidValue, reason: "\(baseError) invalid address")
            }

            email = BATProfileAttributeSetOperation(type: .string, value: value)
        } else {
            email = BATProfileAttributeDeleteOperation()
        }
    }

    @objc
    public func setEmailMarketingSubscriptionState(_ value: BATProfileEditorEmailSubscriptionState) {
        do {
            try checkIfConsumed()
            emailMarketingSubscription = value
        } catch {
            // Do nothing
        }
    }

    @objc
    public func setPhoneNumber(_ value: String?) throws {
        try checkIfConsumed()

        if !isProfileIdentified() {
            throw BatchProfileError(code: .editorInvalidValue, reason: "Phone number cannot be set on a profile if it has not been identified first. Please call 'BatchProfile.idenfity()' with a non nil value beforehand.")
        }

        if let value {
            if !BATProfileDataValidators.isValidPhoneNumber(value) {
                throw BatchProfileError(code: .editorInvalidValue, reason: "Invalid phone number. Please make sure that the string starts with a `+` and is no longer than 15 digits.")
            }
            phoneNumber = BATProfileAttributeSetOperation(type: .string, value: value)
        } else {
            phoneNumber = BATProfileAttributeDeleteOperation()
        }
    }

    @objc
    public func setSMSMarketingSubscriptionState(_ value: BATProfileEditorSMSSubscriptionState) {
        do {
            try checkIfConsumed()
            smsMarketingSubscription = value
        } catch {
            // Do nothing
        }
    }

    @objc
    public func setLanguage(_ value: String?) throws {
        try checkIfConsumed()

        if let value = value?.trimmingCharacters(in: .whitespacesAndNewlines) {
            let size = value.count
            if size < 2 || size > 15 {
                throw BatchProfileError(code: .editorInvalidValue, reason: "Cannot set language: language code must be at least two chars and less than 15")
            }

            language = BATProfileAttributeSetOperation(type: .string, value: value)
        } else {
            language = BATProfileAttributeDeleteOperation()
        }

        try? compatibilityDelegate?.setLanguage(value)
    }

    @objc
    public func setRegion(_ value: String?) throws {
        try checkIfConsumed()

        if let value = value?.trimmingCharacters(in: .whitespacesAndNewlines) {
            let size = value.count
            if size < 2 || size > 15 {
                throw BatchProfileError(code: .editorInvalidValue, reason: "Cannot set region: region code must be at least two chars and less than 15")
            }

            region = BATProfileAttributeSetOperation(type: .string, value: value)
        } else {
            region = BATProfileAttributeDeleteOperation()
        }

        try? compatibilityDelegate?.setRegion(value)
    }

    @objc
    public func add(value: String, toArray attributeKey: String) throws {
        try checkIfConsumed()

        let targetAttributeKey = try validateAndNormalizeName(attributeKey)
        try validateStringValue(value)

        // Check if we have an existing attribute for that key.
        // If so:
        //  - It is an array: add to it after checking that it does not go over the limit
        //  - It is a partial array operation: append
        //  - It is missing or something else than an array: overwrite it
        let existingOperation = customAttributes[targetAttributeKey]

        if let existingOperation = existingOperation as? BATProfileAttributeSetOperation<[String]>, existingOperation.type == .array {
            var updatedArray = existingOperation.value
            updatedArray.append(value)
            try validateStringArray(updatedArray)
            customAttributes[targetAttributeKey] = BATProfileAttributeSetOperation<[String]>(type: .array, value: updatedArray)
        } else if let existingOperation = existingOperation as? BATProfileAttributePartialArrayUpdateOperation {
            var updatedPartialUpdate = existingOperation
            updatedPartialUpdate.itemsToAdd.append(value)
            try validateParialUpdate(updatedPartialUpdate)
            customAttributes[targetAttributeKey] = updatedPartialUpdate
        } else {
            customAttributes[targetAttributeKey] = BATProfileAttributePartialArrayUpdateOperation(itemsToAdd: [value], itemsToRemove: [])
        }

        try? compatibilityDelegate?.add(value: value, toArray: attributeKey)
    }

    @objc
    public func remove(value: String, fromArray attributeKey: String) throws {
        try checkIfConsumed()

        let targetAttributeKey = try validateAndNormalizeName(attributeKey)
        try validateStringValue(value)

        // Check if we have an existing attribute for that key.
        // If so:
        //  - It is an array: remove from it. If the array is empty, remove the operation.
        //  - It is a partial array operation: add the removal to it
        //  - It is missing or something else than an array: overwrite it
        let existingOperation = customAttributes[targetAttributeKey]

        if let existingOperation = existingOperation as? BATProfileAttributeSetOperation<[String]>, existingOperation.type == .array {
            var updatedArray = existingOperation.value
            updatedArray.removeAll { $0 == value }

            if updatedArray.count == 0 {
                customAttributes.removeValue(forKey: targetAttributeKey)
            } else {
                try validateStringArray(updatedArray)
                customAttributes[targetAttributeKey] = BATProfileAttributeSetOperation<[String]>(type: .array, value: updatedArray)
            }
        } else if let existingOperation = existingOperation as? BATProfileAttributePartialArrayUpdateOperation {
            var updatedPartialUpdate = existingOperation
            updatedPartialUpdate.itemsToRemove.append(value)
            try validateParialUpdate(updatedPartialUpdate)
            customAttributes[targetAttributeKey] = updatedPartialUpdate
        } else {
            customAttributes[targetAttributeKey] = BATProfileAttributePartialArrayUpdateOperation(itemsToAdd: [], itemsToRemove: [value])
        }

        try? compatibilityDelegate?.remove(value: value, fromArray: attributeKey)
    }

    @objc(setCustomStringArrayAttribute:forKey:error:)
    public func setCustom(stringArrayAttribute: [String], forKey attributeKey: String) throws {
        try checkIfConsumed()

        let targetAttributeKey = try validateAndNormalizeName(attributeKey)
        try validateStringArray(stringArrayAttribute)
        customAttributes[targetAttributeKey] = BATProfileAttributeSetOperation<[String]>(type: .array, value: stringArrayAttribute)

        try? compatibilityDelegate?.setCustom(stringArrayAttribute: stringArrayAttribute, forKey: attributeKey)
    }

    @objc(setCustomBoolAttribute:forKey:error:)
    public func setCustom(boolAttribute: Bool, forKey attributeKey: String) throws {
        try checkIfConsumed()

        let targetAttributeKey = try validateAndNormalizeName(attributeKey)
        // Bools/Numbers need to be wrapped in a NSNumber as when serializing this will be bridged
        // to an Obj-C NSDictionary
        customAttributes[targetAttributeKey] = BATProfileAttributeSetOperation(type: .bool, value: NSNumber(value: boolAttribute))

        try? compatibilityDelegate?.setCustom(boolAttribute: boolAttribute, forKey: attributeKey)
    }

    @objc(setCustomInt64Attribute:forKey:error:)
    public func setCustom(int64Attribute: Int64, forKey attributeKey: String) throws {
        try checkIfConsumed()

        let targetAttributeKey = try validateAndNormalizeName(attributeKey)
        customAttributes[targetAttributeKey] = BATProfileAttributeSetOperation(type: .longLong, value: NSNumber(value: int64Attribute))

        try? compatibilityDelegate?.setCustom(int64Attribute: int64Attribute, forKey: attributeKey)
    }

    @objc(setCustomDoubleAttribute:forKey:error:)
    public func setCustom(doubleAttribute: Double, forKey attributeKey: String) throws {
        try checkIfConsumed()

        let targetAttributeKey = try validateAndNormalizeName(attributeKey)
        customAttributes[targetAttributeKey] = BATProfileAttributeSetOperation(type: .double, value: NSNumber(value: doubleAttribute))

        try? compatibilityDelegate?.setCustom(doubleAttribute: doubleAttribute, forKey: attributeKey)
    }

    @objc(setCustomStringAttribute:forKey:error:)
    public func setCustom(stringAttribute: String, forKey attributeKey: String) throws {
        try checkIfConsumed()

        let targetAttributeKey = try validateAndNormalizeName(attributeKey)
        try validateStringValue(stringAttribute)
        customAttributes[targetAttributeKey] = BATProfileAttributeSetOperation(type: .string, value: stringAttribute as AnyObject)

        try? compatibilityDelegate?.setCustom(stringAttribute: stringAttribute, forKey: attributeKey)
    }

    @objc(setCustomDateAttribute:forKey:error:)
    public func setCustom(dateAttribute: NSDate, forKey attributeKey: String) throws {
        try checkIfConsumed()

        let targetAttributeKey = try validateAndNormalizeName(attributeKey)
        customAttributes[targetAttributeKey] = BATProfileAttributeSetOperation(type: .date, value: NSNumber(value: floor(dateAttribute.timeIntervalSince1970 * 1000)))

        try? compatibilityDelegate?.setCustom(dateAttribute: dateAttribute, forKey: attributeKey)
    }

    @objc(setCustomURLAttribute:forKey:error:)
    public func setCustom(urlAttribute: URL, forKey attributeKey: String) throws {
        try checkIfConsumed()

        let targetAttributeKey = try validateAndNormalizeName(attributeKey)

        guard urlAttribute.absoluteString.count <= Maximums.urlLength else {
            throw BatchProfileError(code: .editorInvalidValue, reason: "URL attributes can't be longer than \(Maximums.urlLength) characters")
        }

        guard urlAttribute.scheme != nil, urlAttribute.host != nil else {
            throw BatchProfileError(code: .editorInvalidValue, reason: "URL attributes must be of format 'scheme://[authority][path][?query][#fragment]'")
        }

        customAttributes[targetAttributeKey] = BATProfileAttributeSetOperation(type: .url, value: urlAttribute.absoluteString as NSString)

        try? compatibilityDelegate?.setCustom(urlAttribute: urlAttribute, forKey: attributeKey)
    }

    @objc
    public func deleteCustomAttribute(forKey attributeKey: String) throws {
        try checkIfConsumed()

        let targetAttributeKey = try validateAndNormalizeName(attributeKey)
        customAttributes[targetAttributeKey] = BATProfileAttributeDeleteOperation()

        try? compatibilityDelegate?.deleteCustomAttribute(forKey: attributeKey)
    }

    @objc
    public func consume() {
        if consumed {
            return
        }
        consumed = true
        compatibilityDelegate?.consume()
    }

    func validateAndNormalizeName(_ name: String) throws -> String {
        let normalizedName = name.lowercased()
        let baseError = "invalid attribute name '\(name)':"

        if !attributeNameRegexp.matches(name) {
            throw BatchProfileError(code: .editorInvalidKey, reason: "\(baseError) please make sure that the key is made of letters, underscores and numbers only (a-zA-Z0-9_). It also can't be longer than 30 characters")
        }

        return normalizedName
    }

    func validateStringValue(_ value: String) throws {
        if value.count > Maximums.stringLength {
            throw BatchProfileError(code: .editorInvalidValue, reason: "invalid attribute value: strings cannot be longer than \(Maximums.stringLength) characters")
        }
    }

    func validateStringArray(_ values: [String]) throws {
        if values.count > Maximums.stringArrayItems {
            throw BatchProfileError(code: .editorInvalidValue, reason: "invalid attribute value: string arrays cannot contain more than \(Maximums.stringArrayItems) elements")
        }

        for value in values {
            try validateStringValue(value)
        }
    }

    func validateParialUpdate(_ partialUpdate: BATProfileAttributePartialArrayUpdateOperation) throws {
        if partialUpdate.itemsToAdd.count > Maximums.stringArrayItems || partialUpdate.itemsToRemove.count > Maximums.stringArrayItems {
            throw BatchProfileError(code: .editorInvalidValue, reason: "a partial array operation cannot add or remove more than \(Maximums.stringArrayItems) at once")
        }
    }

    func checkIfConsumed() throws {
        if consumed {
            throw BatchProfileError(code: .editorConsumed, reason: "a BatchProfileEditor instance cannot be saved more than once. Please acquire a new instance")
        }
    }

    public func copy(with _: NSZone? = nil) -> Any {
        let copy = BATProfileEditor()
        copy.email = self.email
        copy.emailMarketingSubscription = self.emailMarketingSubscription
        copy.phoneNumber = self.phoneNumber
        copy.smsMarketingSubscription = self.smsMarketingSubscription
        copy.language = self.language
        copy.region = self.region
        copy.customAttributes = self.customAttributes
        return copy
    }

    func isProfileIdentified() -> Bool {
        // We can only set an email or a phone number if the user is logged in
        // This method is exposed for testing purposes
        return BAUserProfile.default().customIdentifier != nil
    }
}

/// Represents an operation on a profile attribute.
/// If you do not want to do anything on an attribute, store nil rather than an instance of this protocol
protocol BATProfileAttributeOperation {
    associatedtype ValueType

    var type: BATProfileAttributeOperationType { get }
    // All values should be ready to be serialized as is in json
    // for the server event.
    // If they are not, please document it in your implementation

    var value: ValueType { get }

    // Suffix to add to typed keys
    var keySuffix: String { get }
}

enum BATProfileAttributeOperationType: String {
    case bool = "b"
    case longLong = "i"
    case double = "f"
    case string = "s"
    case date = "t"
    case url = "u"
    case array = "a"
    case delete = "x"
}

public struct BATProfileAttributeSetOperation<T>: BATProfileAttributeOperation {
    typealias ValueType = T

    let type: BATProfileAttributeOperationType
    let value: ValueType

    // Prefix to add to typed keys
    var keySuffix: String {
        if self.type == .delete {
            return ""
        }
        return "." + self.type.rawValue
    }
}

public struct BATProfileAttributeDeleteOperation: BATProfileAttributeOperation {
    typealias ValueType = NSNull

    let type = BATProfileAttributeOperationType.delete
    // Using NSNull is important as this is what we'll use for serialization
    // in the NSDictionary
    let value: ValueType = NSNull()

    let keySuffix: String = ""
}

public struct BATProfileAttributePartialArrayUpdateOperation: BATProfileAttributeOperation {
    typealias ValueType = NSNull

    let type = BATProfileAttributeOperationType.array
    /// Do not read value on this type, it is not representative of its real serialization
    let value: ValueType = NSNull()
    let keySuffix: String = "." + BATProfileAttributeOperationType.array.rawValue

    var itemsToAdd: [String] = []
    var itemsToRemove: [String] = []
}

/// Email subscription state. This is already defined in BatchProfile.h, but we cannot reexpose
/// an @objc method with a parameter from a public header, as this creates an import loop.
@objc
public enum BATProfileEditorEmailSubscriptionState: UInt {
    case subscribed = 0
    case unsubscribed = 1
}

/// SMS subscription state. This is already defined in BatchProfile.h, but we cannot reexpose
/// an @objc method with a parameter from a public header, as this creates an import loop.
@objc
public enum BATProfileEditorSMSSubscriptionState: UInt {
    case subscribed = 0
    case unsubscribed = 1
}
