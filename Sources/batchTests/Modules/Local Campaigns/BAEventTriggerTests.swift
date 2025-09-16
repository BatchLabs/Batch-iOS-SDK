//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch
import Testing

/// A test suite for `BAEventTrigger`.
///
/// This suite verifies that `BAEventTrigger` instances correctly determine if they are satisfied
/// by a given event name, label, and attributes.
struct BAEventTriggerTests {
    /// A default event name for testing.
    static let name = "name"

    /// A default event label for testing.
    static let label = "label"

    /// A default set of event attributes for testing.
    static let eventAttributes = BatchEventAttributes { a in
        a.put("test_label", forKey: "$label")
        a.put("a_test_string", forKey: "string_attr")
        a.put(13, forKey: "int_attr")
        a.put(13.4567, forKey: "double_attr")
        a.put(Date(timeIntervalSince1970: 1_596_975_143), forKey: "date_attr")
        a.put(URL(string: "https://batch.com/")!, forKey: "url_attr")
        a.put(["A", "B", "C"], forKey: "string_list")
    }

    static let otherEventAttributes = BatchEventAttributes { b in
        b.put(13.4567, forKey: "double_attr")
        b.put(Date(timeIntervalSince1970: 1_596_975_143), forKey: "date_attr")
    }

    /// Tests focusing on the label-matching logic of `BAEventTrigger`.
    @Suite
    struct Label {
        /// Tests that the trigger is satisfied when both the event name and label match.
        @Test func equal() {
            // GIVEN: A `BAEventTrigger` initialized with a specific name and label.
            let trigger = BAEventTrigger(name: name, label: label, attributes: nil)

            // WHEN: The `isSatisfied` method is called with that same name and label.
            let isSatisfied = trigger.isSatisfied(forName: name, label: label)

            // THEN: The result is `true`.
            #expect(isSatisfied)
        }

        /// Tests that a trigger with a `nil` label is satisfied by an event with any label.
        @Test func equalNilLabel() {
            // GIVEN: A `BAEventTrigger` with a specific name and a `nil` label.
            let trigger = BAEventTrigger(name: name, label: nil, attributes: nil)

            // WHEN: The `isSatisfied` method is called with the correct name and either a non-nil or a `nil` label.
            let isSatisfied = trigger.isSatisfied(forName: name, label: label)
            let isSatisfied2 = trigger.isSatisfied(forName: name, label: nil)

            // THEN: The result is `true` in both cases.
            #expect(isSatisfied)
            #expect(isSatisfied2)
        }

        /// Tests that the trigger is not satisfied if the event name does not match.
        @Test func notEqualBecauseOfName() {
            // GIVEN: Two `BAEventTrigger` instances with different names.
            let other = "nameeeee"
            let trigger = BAEventTrigger(name: name, label: label, attributes: nil)
            let trigger2 = BAEventTrigger(name: other, label: label, attributes: nil)

            // WHEN: The `isSatisfied` method is called on each trigger with the other's name.
            let isSatisfied = trigger.isSatisfied(forName: other, label: label)
            let isSatisfied2 = trigger2.isSatisfied(forName: name, label: label)

            // THEN: The result is `false` in both cases.
            #expect(isSatisfied == false)
            #expect(isSatisfied2 == false)
        }

        /// Tests that the trigger is not satisfied if the event label does not match.
        @Test func notEqualBecauseOfLabel() {
            // GIVEN: Two `BAEventTrigger` instances with the same name but different labels.
            let other = "labellll"
            let trigger = BAEventTrigger(name: name, label: other, attributes: nil)
            let trigger2 = BAEventTrigger(name: name, label: label, attributes: nil)

            // WHEN: The `isSatisfied` method is called on each trigger with the other's label.
            let isSatisfied = trigger.isSatisfied(forName: name, label: label)
            let isSatisfied2 = trigger2.isSatisfied(forName: name, label: other)

            // THEN: The result is `false` in both cases.
            #expect(isSatisfied == false)
            #expect(isSatisfied2 == false)
        }

        /// Tests that a trigger requiring a specific label is not satisfied by an event with a `nil` label.
        @Test func notEqualNilLabel() {
            // GIVEN: A `BAEventTrigger` with a specific name and label.
            let trigger = BAEventTrigger(name: name, label: "zeerg", attributes: nil)

            // WHEN: The `isSatisfied` method is called with the correct name but a `nil` label.
            let isSatisfied = trigger.isSatisfied(forName: name, label: nil)

            // THEN: The result is `false`.
            #expect(isSatisfied == false)
        }
    }

    /// Tests focusing on the attribute-matching logic of `BAEventTrigger`.
    @Suite
    struct Attributes {
        /// Tests that the trigger is satisfied when the event attributes are an exact match.
        @Test func equal() throws {
            // GIVEN: A `BAEventTrigger` initialized with specific attributes.
            let eventAttributes = try BATEventAttributesSerializer.serialize(eventAttributes: eventAttributes)
            let trigger = BAEventTrigger(name: name, label: label, attributes: eventAttributes)

            // WHEN: The `isSatisfied` method is called with the same attributes.
            let isSatisfied = trigger.isSatisfied(forAttributes: eventAttributes)

            // THEN: The result is `true`.
            #expect(isSatisfied)
        }

        /// Tests that the trigger is satisfied when the event attributes are an exact match.
        @Test func equalWithImbriquedObject() throws {
            // GIVEN: A `BAEventTrigger` initialized with specific attributes.
            eventAttributes.put(otherEventAttributes, forKey: "other")
            let eventAttributes = try BATEventAttributesSerializer.serialize(eventAttributes: eventAttributes)
            let trigger = BAEventTrigger(name: name, label: label, attributes: eventAttributes)

            // WHEN: The `isSatisfied` method is called with the same attributes.
            let isSatisfied = trigger.isSatisfied(forAttributes: eventAttributes)

            // THEN: The result is `true`.
            #expect(isSatisfied)
        }

        /// Tests that the trigger is satisfied when the event attributes are an exact match.
        @Test func equalWithImbriquedObjects() throws {
            // GIVEN: A `BAEventTrigger` initialized with specific attributes.
            eventAttributes.put([otherEventAttributes, otherEventAttributes], forKey: "other")
            let eventAttributes = try BATEventAttributesSerializer.serialize(eventAttributes: eventAttributes)
            let trigger = BAEventTrigger(name: name, label: label, attributes: eventAttributes)

            // WHEN: The `isSatisfied` method is called with the same attributes.
            let isSatisfied = trigger.isSatisfied(forAttributes: eventAttributes)

            // THEN: The result is `true`.
            #expect(isSatisfied)
        }

        /// Tests that a trigger with `nil` attributes is satisfied by an event with any attributes.
        @Test func equalNil() throws {
            // GIVEN: A `BAEventTrigger` with `nil` attributes.
            let eventAttributes = try BATEventAttributesSerializer.serialize(eventAttributes: eventAttributes)
            let trigger = BAEventTrigger(name: name, label: label, attributes: nil)

            // WHEN: The `isSatisfied` method is called with both `nil` and non-nil attributes.
            let isSatisfied = trigger.isSatisfied(forAttributes: nil)
            let isSatisfied2 = trigger.isSatisfied(forAttributes: eventAttributes)

            // THEN: The result is `true` in both cases.
            #expect(isSatisfied)
            #expect(isSatisfied2)
        }

        /// Tests that the trigger is not satisfied when the event attributes do not match.
        @Test func notEqual() throws {
            // GIVEN: A `BAEventTrigger` with a complete set of attributes.
            let eventAttributes = try BATEventAttributesSerializer.serialize(eventAttributes: eventAttributes)
            let trigger = BAEventTrigger(name: "nameeeee", label: "label", attributes: eventAttributes)

            // WHEN: The `isSatisfied` method is called with a different, incomplete set of attributes.
            let eventAttributes2 = try BATEventAttributesSerializer.serialize(eventAttributes: BatchEventAttributes { a in
                a.put("test_label", forKey: "$label")
            })
            let isSatisfied = trigger.isSatisfied(forAttributes: eventAttributes2)

            // THEN: The result is `false`.
            #expect(isSatisfied == false)
        }

        /// Tests that the trigger is not satisfied when the event attributes do not match.
        @Test func notEqualBecauseOfImbriquedObject() throws {
            // GIVEN: A `BAEventTrigger` with a complete set of attributes.
            let copy = eventAttributes
            copy.put(otherEventAttributes, forKey: "other")
            let serializedEventAttributes = try BATEventAttributesSerializer.serialize(eventAttributes: copy)
            let trigger = BAEventTrigger(name: "nameeeee", label: "label", attributes: serializedEventAttributes)

            // WHEN: The `isSatisfied` method is called with a different, incomplete set of attributes.
            let copy2 = eventAttributes
            copy2.put(BatchEventAttributes { a in
                a.put(13.4567, forKey: "double_attr")
                a.put(Date(timeIntervalSince1970: 1_596_975_144), forKey: "date_attr")
            }, forKey: "other")

            let serializedEventAttributes2 = try BATEventAttributesSerializer.serialize(eventAttributes: copy2)
            let isSatisfied = trigger.isSatisfied(forAttributes: serializedEventAttributes2)

            // THEN: The result is `false`.
            #expect(isSatisfied == false)
        }

        /// Tests that the trigger is not satisfied when the event attributes do not match.
        @Test func notEqualBecauseOfImbriquedObjects() throws {
            // GIVEN: A `BAEventTrigger` with a complete set of attributes.
            let copy = eventAttributes
            copy.put([otherEventAttributes, otherEventAttributes], forKey: "other")
            let serializedEventAttributes = try BATEventAttributesSerializer.serialize(eventAttributes: copy)
            let trigger = BAEventTrigger(name: "nameeeee", label: "label", attributes: serializedEventAttributes)

            // WHEN: The `isSatisfied` method is called with a different, incomplete set of attributes.
            let copy2 = eventAttributes
            copy2.put([otherEventAttributes, BatchEventAttributes { a in
                a.put(13.4567, forKey: "double_attr")
                a.put(Date(timeIntervalSince1970: 1_596_975_144), forKey: "date_attr")
            }], forKey: "other")

            let serializedEventAttributes2 = try BATEventAttributesSerializer.serialize(eventAttributes: copy2)
            let isSatisfied = trigger.isSatisfied(forAttributes: serializedEventAttributes2)

            // THEN: The result is `false`.
            #expect(isSatisfied == false)
        }

        /// Tests that the trigger is not satisfied if the inner content of the attributes differs.
        @Test func notEqualBecauseOfInnerContent() throws {
            // GIVEN: A `BAEventTrigger` with attributes containing an array.
            let eventAttributes = try BATEventAttributesSerializer.serialize(eventAttributes: eventAttributes)
            let trigger = BAEventTrigger(name: "nameeeee", label: "label", attributes: eventAttributes)

            // WHEN: The `isSatisfied` method is called with attributes where that same array has an extra element.
            let eventAttributes2 = try BATEventAttributesSerializer.serialize(eventAttributes: BatchEventAttributes { a in
                a.put("test_label", forKey: "$label")
                a.put("a_test_string", forKey: "string_attr")
                a.put(13, forKey: "int_attr")
                a.put(13.4567, forKey: "double_attr")
                a.put(Date(timeIntervalSince1970: 1_596_975_143), forKey: "date_attr")
                a.put(URL(string: "https://batch.com/")!, forKey: "url_attr")
                a.put(["A", "B", "C", "D"], forKey: "string_list")
            })

            let isSatisfied = trigger.isSatisfied(forAttributes: eventAttributes2)

            // THEN: The result is `false`.
            #expect(isSatisfied == false)
        }

        /// Tests that a trigger requiring specific attributes is not satisfied by an event with `nil` attributes.
        @Test func notEqualNil() throws {
            // GIVEN: A `BAEventTrigger` with a specific set of attributes.
            let eventAttributes = try BATEventAttributesSerializer.serialize(eventAttributes: eventAttributes)
            let trigger = BAEventTrigger(name: name, label: label, attributes: eventAttributes)

            // WHEN: The `isSatisfied` method is called with `nil` attributes.
            let isSatisfied = trigger.isSatisfied(forAttributes: nil)

            // THEN: The result is `false`.
            #expect(isSatisfied == false)
        }
    }
}
