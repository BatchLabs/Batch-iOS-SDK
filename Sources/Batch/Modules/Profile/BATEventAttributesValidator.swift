//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

private enum Maximums {
    static let labelLength = 200
    static let tagLength = 64
    static let tagsCount = 10
    static let attributesCount = 20
    static let urlLength = 2048
    static let stringLength = 300
    static let arrayItemsCount = 25
}

private enum Consts {
    static let attributeNamePattern = "^[a-zA-Z0-9_]{1,30}$"
}

private typealias ValidationErrorMessage = String

private struct ValidationError {
    let message: ValidationErrorMessage
    var breadcrumbs: Breadcrumbs

    func render() -> String {
        var attributePath = breadcrumbs.items.joined(separator: ".")
        if attributePath.isEmpty {
            attributePath = "<attributes root>"
        }
        return attributePath + ": " + message
    }
}

/// Breadcrumbs is similar to an ariane thread, keeping track of where we are in an object
/// For example, ["purchased_item", "name"] is the breadcrumb for a "name" attribute in a subobject
/// attribute named "purchased_item".
private struct Breadcrumbs {
    var items: [String]

    func appending(_ item: String) -> Breadcrumbs {
        return Breadcrumbs(items: items + [item])
    }

    func appending(index: Int) -> Breadcrumbs {
        var mutatedItems = items
        if let lastItem = mutatedItems.last {
            mutatedItems[mutatedItems.endIndex - 1] = "\(lastItem)[\(index)]"
        }
        return Breadcrumbs(items: mutatedItems)
    }

    var depth: Int {
        items.count
    }
}

/// Class that validates that a BatchEventAttributes object is valid
struct BATEventAttributesValidator {
    private let attributeNameRegexp: BATRegularExpression = .init(pattern: Consts.attributeNamePattern)

    let eventAttributes: BatchEventAttributes

    /// Validate the BatchEventAttributes instance and returns an array of errors
    /// If there are none, the event data is valid
    func computeValidationErrors() -> [String] {
        return visitObject(eventAttributes: eventAttributes, breadcrumbs: Breadcrumbs(items: [])).map { $0.render() }
    }

    // MARK: Visitors

    /// Check for errors in a BatchEventAttributes object.
    /// The breadcrumb helps to build error messages for complex objects, it also acts as a depth counter
    /// The errors are not returned using a throwing pattern as we want to accumulate them
    private func visitObject(eventAttributes: BatchEventAttributes, breadcrumbs: Breadcrumbs) -> [ValidationError] {
        // Quick bail on objects that are too deep
        let depth = breadcrumbs.depth
        guard depth <= 3 else {
            return [ValidationError(message: "Object attributes cannot be nested in more than three levels", breadcrumbs: breadcrumbs)]
        }

        // No attributes, no labels, no tags? Useless object, but quickly bail
        if eventAttributes._attributes.isEmpty, eventAttributes._label == nil, eventAttributes._tags == nil {
            return []
        }

        var errors: [ValidationError] = []

        // Tags/Label validation
        if depth > 0 {
            // tags/label not allowed in subobjects
            if eventAttributes._label != nil {
                errors.append(ValidationError(message: "Labels are not allowed in sub-objects", breadcrumbs: breadcrumbs.appending("$label")))
            }

            if eventAttributes._tags != nil {
                errors.append(ValidationError(message: "Tags are not allowed in sub-objects", breadcrumbs: breadcrumbs.appending("$tags")))
            }
        } else {
            // Root object, tags/label are allowed, check them
            if let label = eventAttributes._label {
                wrapAndMergeErrorMessages(visitLabel(label), breadcrumbs: breadcrumbs.appending("$label"), into: &errors)
            }

            if let tags = eventAttributes._tags {
                mergeErrors(visitTags(tags, breadcrumbs: breadcrumbs.appending("$tags")), into: &errors)
            }
        }

        let attributes = eventAttributes._attributes

        // Check for attributes count
        if attributes.count > Maximums.attributesCount {
            errors.append(ValidationError(message: "objects cannot hold more than \(Maximums.attributesCount) attributes", breadcrumbs: breadcrumbs))
        }

        for (attributeName, attributeValue) in attributes {
            // Check for invalid attributes names
            if let attributeNameError = visitAttributeName(attributeName, breadcrumbs) {
                // If we encounter an error on the attribute name, do not try to parse it
                errors.append(attributeNameError)
                continue
            }

            // Attribute name is now safe to print
            let attributeBreadcrumbs = breadcrumbs.appending(attributeName)
            mergeErrors(visitAttributeValue(attributeValue, attributeBreadcrumbs), into: &errors)
        }

        return errors
    }

    private func visitAttributeName(_ name: String, _ breadcrumbs: Breadcrumbs) -> ValidationError? {
        let baseError = "invalid attribute name '\(name)':"
        if name != name.lowercased() {
            // We should have lowercased this, someone is doing something nasty~
            return ValidationError(message: "\(baseError) object has been tampered with", breadcrumbs: breadcrumbs)
        }

        if attributeNameRegexp.regexpFailedToInitialize {
            return ValidationError(message: "\(baseError) internal error", breadcrumbs: breadcrumbs)
        }

        if !attributeNameRegexp.matches(name) {
            return ValidationError(
                message: "\(baseError) please make sure that the key is made of letters, underscores and numbers only (a-zA-Z0-9_). It also can't be longer than 30 characters",
                breadcrumbs: breadcrumbs
            )
        }

        return nil
    }

    private func visitAttributeValue(_ attribute: BATTypedEventAttribute, _ breadcrumbs: Breadcrumbs) -> [ValidationError] {
        var errors: [ValidationError] = []

        let genericTypecastError = ValidationError(message: "attribute is not of the right underlying type. this is an internal error and should be reported", breadcrumbs: breadcrumbs)

        switch attribute.type {
        case .URL:
            if let url = attribute.value as? URL {
                mergeError(visitAttributeURLValue(url, breadcrumbs), into: &errors)
            } else {
                errors.append(genericTypecastError)
            }
        case .string:
            if let stringValue = attribute.value as? String {
                mergeError(visitAttributeStringValue(stringValue, breadcrumbs), into: &errors)
            } else {
                errors.append(genericTypecastError)
            }
        case .double, .integer, .bool, .date:
            if !(attribute.value is NSNumber) {
                errors.append(genericTypecastError)
            }
        case .objectArray, .stringArray:
            if let anyArrayValue = attribute.value as? [Any] {
                if let baseArrayError = visitAttributeArrayValueBase(anyArrayValue, breadcrumbs) {
                    errors.append(baseArrayError)
                } else {
                    // Only continue if the array passed base validation
                    if attribute.type == .objectArray {
                        if let objectArrayValue = attribute.value as? [BatchEventAttributes] {
                            mergeErrors(visitAttributeObjectArrayValue(objectArrayValue, breadcrumbs), into: &errors)
                        } else {
                            errors.append(genericTypecastError)
                        }
                    } else if attribute.type == .stringArray {
                        if let stringArrayValue = attribute.value as? [String] {
                            mergeErrors(visitAttributeStringArrayValue(stringArrayValue, breadcrumbs), into: &errors)
                        } else {
                            errors.append(genericTypecastError)
                        }
                    }
                }
            } else {
                errors.append(genericTypecastError)
            }
        case .object:
            if let objectValue = attribute.value as? BatchEventAttributes {
                mergeErrors(visitObject(eventAttributes: objectValue, breadcrumbs: breadcrumbs), into: &errors)
            } else {
                errors.append(genericTypecastError)
            }
        }

        return errors
    }

    private func visitAttributeArrayValueBase(_ value: [Any], _ breadcrumbs: Breadcrumbs) -> ValidationError? {
        let depth = breadcrumbs.depth
        guard depth <= 3 else {
            return ValidationError(message: "array attributes cannot be nested in more than three levels", breadcrumbs: breadcrumbs)
        }

        if value.count > Maximums.arrayItemsCount {
            return ValidationError(message: "array attributes cannot have more than \(Maximums.arrayItemsCount) elements", breadcrumbs: breadcrumbs)
        }

        return nil
    }

    private func visitAttributeStringArrayValue(_ array: [String], _ breadcrumbs: Breadcrumbs) -> [ValidationError] {
        var errors: [ValidationError] = []

        for i in array.indices {
            let value = array[i]
            let itemBreadcrumbs = breadcrumbs.appending(index: i)

            mergeError(visitAttributeStringValue(value, itemBreadcrumbs), into: &errors)
        }

        return errors
    }

    private func visitAttributeObjectArrayValue(_ array: [BatchEventAttributes], _ breadcrumbs: Breadcrumbs) -> [ValidationError] {
        var errors: [ValidationError] = []

        for i in array.indices {
            let value = array[i]
            let itemBreadcrumbs = breadcrumbs.appending(index: i)

            mergeErrors(visitObject(eventAttributes: value, breadcrumbs: itemBreadcrumbs), into: &errors)
        }

        return errors
    }

    private func visitAttributeStringValue(_ value: String, _ breadcrumbs: Breadcrumbs) -> ValidationError? {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            return ValidationError(message: "string attribute cannot be empty or made of whitespace", breadcrumbs: breadcrumbs)
        }

        if value.count > Maximums.stringLength {
            return ValidationError(message: "string attribute cannot be longer than \(Maximums.stringLength) characters", breadcrumbs: breadcrumbs)
        }

        if value.contains("\n") {
            return ValidationError(message: "string attribute cannot be multiline", breadcrumbs: breadcrumbs)
        }

        return nil
    }

    private func visitAttributeURLValue(_ value: URL, _ breadcrumbs: Breadcrumbs) -> ValidationError? {
        if value.absoluteString.count > Maximums.urlLength {
            return ValidationError(message: "URL attributes cannot be longer than \(Maximums.urlLength) characters", breadcrumbs: breadcrumbs)
        }

        if value.scheme == nil || value.host == nil {
            return ValidationError(message: "URL attributes must follow the format 'scheme://[authority][path][?query][#fragment]'", breadcrumbs: breadcrumbs)
        }

        return nil
    }

    private func visitLabel(_ label: String) -> [ValidationErrorMessage] {
        var errors: [String] = []

        if label.count > Maximums.labelLength {
            errors.append("cannot be longer than 200 characters")
        }
        if label.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            errors.append("cannot be empty or only made of whitespace")
        }
        if label.contains("\n") {
            errors.append("cannot be multiline")
        }

        return errors
    }

    private func visitTags(_ tags: [String], breadcrumbs: Breadcrumbs) -> [ValidationError] {
        var errors: [ValidationError] = []

        if tags.count > Maximums.tagsCount {
            errors.append(ValidationError(message: "must not contain more than \(Maximums.tagsCount) values", breadcrumbs: breadcrumbs))
        }

        for index in tags.indices {
            if let error = visitTag(tags[index]) {
                errors.append(ValidationError(message: error, breadcrumbs: breadcrumbs.appending(index: index)))
            }
        }

        return errors
    }

    private func visitTag(_ tag: String) -> ValidationErrorMessage? {
        if tag.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            return "tag cannot be empty or made of whitespace"
        }

        if tag.count > Maximums.tagLength {
            return "tag cannot be longer than \(Maximums.tagLength) characters"
        }

        if tag.contains("\n") {
            return "tag cannot be multiline"
        }

        return nil
    }

    // MARK: Error helpers

    private func wrapErrorMessages(_ messages: [ValidationErrorMessage], breadcrumbs: Breadcrumbs) -> [ValidationError] {
        return messages.map { message in
            return ValidationError(message: message, breadcrumbs: breadcrumbs)
        }
    }

    private func wrapAndMergeErrorMessages(_ messages: [ValidationErrorMessage], breadcrumbs: Breadcrumbs, into accumulator: inout [ValidationError]) {
        accumulator.append(
            contentsOf: messages.map { message in
                return ValidationError(message: message, breadcrumbs: breadcrumbs)
            }
        )
    }

    private func mergeError(_ error: ValidationError?, into accumulator: inout [ValidationError]) {
        if let error {
            accumulator.append(error)
        }
    }

    private func mergeErrors(_ errors: [ValidationError], into accumulator: inout [ValidationError]) {
        accumulator.append(contentsOf: errors)
    }
}
