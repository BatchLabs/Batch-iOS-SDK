//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

/// Serialize a BatchEventAttributes instance
/// No validation checks are made: make sure you call BATEventAttributesValidator on the _same_ BatchEventAttributes
@objc
@objcMembers
public class BATEventAttributesSerializer: NSObject {
    /// Serialize an event
    /// Throws a BATSDKError if a typecasting error happened, but this should not be possible if BatchEventAttributes and BATEventAttributesValidator
    /// did their jobs properly
    public static func serialize(eventAttributes: BatchEventAttributes) throws -> [AnyHashable: Any] {
        var jsonParameters = [AnyHashable: Any]()

        if let label = eventAttributes._label {
            jsonParameters["label"] = label
        }
        if let tags = eventAttributes._tags {
            // Deduplicate and lowercase tags
            jsonParameters["tags"] = Array(Set(tags.map { $0.lowercased() }))
        }

        jsonParameters["attributes"] = try serializeAttributes(eventAttributes: eventAttributes)

        return jsonParameters
    }

    private static func serializeAttributes(eventAttributes: BatchEventAttributes) throws -> [AnyHashable: Any] {
        var jsonAttributes = [AnyHashable: Any]()

        for (attributeName, attributeValue) in eventAttributes._attributes {
            let jsonKey = "\(attributeName).\(attributeValue.typeSuffix)"
            switch attributeValue.type {
                case .date, .string, .double, .integer, .bool:
                    jsonAttributes[jsonKey] = attributeValue.value
                case .URL:
                    if let urlValue = attributeValue.value as? URL {
                        jsonAttributes[jsonKey] = urlValue.absoluteString
                    } else {
                        throw BATSDKError.sdkInternal(subcode: 1, reason: "attribute isn't an URL")
                    }
                case .stringArray:
                    if let arrayValue = attributeValue.value as? [String] {
                        jsonAttributes[jsonKey] = arrayValue
                    } else {
                        throw BATSDKError.sdkInternal(subcode: 2, reason: "attribute isn't a string array")
                    }

                case .objectArray:
                    if let arrayValue = attributeValue.value as? [BatchEventAttributes] {
                        do {
                            jsonAttributes[jsonKey] = try arrayValue.map { try BATEventAttributesSerializer.serializeAttributes(eventAttributes: $0) }
                        } catch {
                            throw error
                        }
                    } else {
                        throw BATSDKError.sdkInternal(subcode: 3, reason: "attribute isn't a BatchEventAttributes array")
                    }

                case .object:
                    if let objectValue = attributeValue.value as? BatchEventAttributes {
                        do {
                            try jsonAttributes[jsonKey] = BATEventAttributesSerializer.serializeAttributes(eventAttributes: objectValue)
                        } catch {
                            throw error
                        }
                    } else {
                        throw BATSDKError.sdkInternal(subcode: 4, reason: "attribute isn't a BatchEventAttributes instance")
                    }
            }
        }

        return jsonAttributes
    }
}
