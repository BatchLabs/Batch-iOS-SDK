//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

class BATProfileInstallDataCompatibility: BATInstallDataEditorCompatibilityProtocol {
    let installDataEditor: BAInstallDataEditor!

    init?() {
        guard let injectedEditor = BAInjection.inject(BAInstallDataEditor.self) else {
            return nil
        }
        self.installDataEditor = injectedEditor
    }

    func setLanguage(_ value: String?) throws {
        installDataEditor.setLanguage(value)
    }

    func setRegion(_ value: String?) throws {
        installDataEditor.setRegion(value)
    }

    func add(value: String, toArray attributeKey: String) throws {
        installDataEditor.addTag(value, inCollection: attributeKey)
    }

    func remove(value: String, fromArray attributeKey: String) throws {
        installDataEditor.removeTag(value, fromCollection: attributeKey)
    }

    func setCustom(stringArrayAttribute: [String], forKey attributeKey: String) throws {
        installDataEditor.clearTagCollection(attributeKey)
        for tag in stringArrayAttribute {
            installDataEditor.addTag(tag, inCollection: attributeKey)
        }
    }

    func setCustom(boolAttribute: Bool, forKey attributeKey: String) throws {
        try? installDataEditor.setAttribute(boolAttribute, forKey: attributeKey)
    }

    func setCustom(int64Attribute: Int64, forKey attributeKey: String) throws {
        try? installDataEditor.setAttribute(int64Attribute, forKey: attributeKey)
    }

    func setCustom(doubleAttribute: Double, forKey attributeKey: String) throws {
        try? installDataEditor.setAttribute(doubleAttribute, forKey: attributeKey)
    }

    func setCustom(stringAttribute: String, forKey attributeKey: String) throws {
        try? installDataEditor.setAttribute(stringAttribute, forKey: attributeKey)
    }

    func setCustom(dateAttribute: NSDate, forKey attributeKey: String) throws {
        try? installDataEditor.setAttribute(dateAttribute as Date, forKey: attributeKey)
    }

    func setCustom(urlAttribute: URL, forKey attributeKey: String) throws {
        try? installDataEditor.setAttribute(urlAttribute, forKey: attributeKey)
    }

    func deleteCustomAttribute(forKey attributeKey: String) throws {
        // We do both: removeAttribute and clearTagCollection since we don't know
        // the type for the install-based compat, so we don't know if we should remove
        // a tag collection or an attribute.
        // This will not do anything if the attribute or collection doesn't exist.
        installDataEditor.removeAttribute(forKey: attributeKey)
        installDataEditor.clearTagCollection(attributeKey)
    }

    func consume() {
        installDataEditor.save()
    }
}
