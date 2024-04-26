//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

/// Serialize operations described in a BATProfileEditor
/// No validation checks are made: BATProfileEditor does them
class BATProfileOperationsSerializer: NSObject {
    /// Serialize a Profile Editor
    static func serialize(profileEditor: BATSerializableProfileEditorProtocol) -> [AnyHashable: Any] {
        var jsonParameters = [AnyHashable: Any]()

        if let email = profileEditor.email {
            jsonParameters["email"] = email.value
        }

        if let emailMarketingSubscription = profileEditor.emailMarketingSubscription {
            let serializedValue: String
            switch emailMarketingSubscription {
                case .subscribed:
                    serializedValue = "subscribed"
                case .unsubscribed:
                    serializedValue = "unsubscribed"
            }
            jsonParameters["email_marketing"] = serializedValue
        }

        if let language = profileEditor.language {
            jsonParameters["language"] = language.value
        }

        if let region = profileEditor.region {
            jsonParameters["region"] = region.value
        }

        if !profileEditor.customAttributes.isEmpty {
            jsonParameters["custom_attributes"] = serializeAttributes(profileEditor: profileEditor)
        }

        return jsonParameters
    }

    private static func serializeAttributes(profileEditor: BATSerializableProfileEditorProtocol) -> [AnyHashable: Any] {
        var jsonAttributes = [AnyHashable: Any]()

        for (attributeName, attributeOperation) in profileEditor.customAttributes {
            let jsonKey = "\(attributeName)\(attributeOperation.keySuffix)"

            // Partial updates need to be serialized differently
            if let partialArrayOperation = attributeOperation as? BATProfileAttributePartialArrayUpdateOperation {
                // If the func returns nil, it should not be serialized
                jsonAttributes[jsonKey] = serializePartialArrayUpdate(partialArrayOperation)
            } else {
                // All values should be serializable directly
                jsonAttributes[jsonKey] = attributeOperation.value
            }
        }

        return jsonAttributes
    }

    private static func serializePartialArrayUpdate(_ operation: BATProfileAttributePartialArrayUpdateOperation) -> [AnyHashable: Any]? {
        var json = [AnyHashable: Any]()

        if operation.itemsToAdd.count > 0 {
            json["$add"] = operation.itemsToAdd
        }

        if operation.itemsToRemove.count > 0 {
            json["$remove"] = operation.itemsToRemove
        }

        // Turns out we had nothing to do.
        // ProfileEditor could handle that but we don't care
        if json.isEmpty {
            return nil
        }

        return json
    }
}
