//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch
import Testing

/// Tests for the `BAPublicEventTrackedSignal` class, focusing on its interaction with `BAEventTrigger`.
struct BAPublicEventTrackedSignalTests {
    /// Tests that the signal correctly satisfies a trigger when their properties are identical.
    @Test func equal() async throws {
        // GIVEN: A signal and a trigger are created with the exact same name, label, and attributes.
        // This sets up a scenario where the signal is expected to match the trigger's conditions.
        let signal = BAPublicEventTrackedSignal(
            name: "name",
            label: "label",
            attributes: [
                "key": "value",
                "key2": "value2",
                "key3": 3,
                "arrayKey": ["item1", "item2", "item3"],
                "arrayKey2": [1, 2, 3],
                "objectKey": ["sub_string": "mysubstring", "sub_bool": true],
            ]
        )
        let trigger = BAEventTrigger(
            name: "name",
            label: "label",
            attributes: [
                "key": "value",
                "key3": 3,
                "arrayKey2": [2, 3, 1],
                "arrayKey": ["item1", "item2", "item3"],
                "objectKey": ["sub_string": "mysubstring", "sub_bool": true],
            ]
        )

        // WHEN: The signal's `doesSatisfyTrigger` method is called with the trigger.
        // This is the action being tested: checking if the signal fulfills the trigger's requirements.
        let satisfied = signal.doesSatisfyTrigger(trigger)

        // THEN: The result is expected to be `true`.
        // This confirms that the signal correctly identifies that it satisfies the trigger when all properties match.
        #expect(satisfied)
    }

    /// Tests that the signal does not satisfy a trigger when their attributes are different.
    @Test func notEqual() async throws {
        // GIVEN: A signal and a trigger are created with the same name and label, but different attributes.
        // The signal contains extra and different attribute values compared to the trigger.
        let signal = BAPublicEventTrackedSignal(name: "name", label: "label", attributes: ["key": "valueeeee", "array": ["key": "value"]])
        let trigger = BAEventTrigger(name: "name", label: "label", attributes: ["key": "value"])

        // WHEN: The signal's `doesSatisfyTrigger` method is called with the trigger.
        // This action tests the signal's ability to differentiate itself from a non-matching trigger.
        let satisfied = signal.doesSatisfyTrigger(trigger)

        // THEN: The result is expected to be `false`.
        // This verifies that the signal does not satisfy the trigger because their attributes do not match.
        #expect(satisfied == false)
    }

    /// Tests case sensitivity of signals
    @Test func sensitiveNotEqual() async throws {
        // GIVEN: A signal and a trigger are created with the exact same name, label, and attributes.
        // This sets up a scenario where the signal is expected to match the trigger's conditions.
        let signal = BAPublicEventTrackedSignal(
            name: "name",
            label: "label",
            attributes: [
                "key": "Value",
                "key2": "value2",
                "key3": 3,
                "arrayKey": ["Item1", "item2", "item3"],
                "arrayKey2": [1, 2, 3],
                "objectKey": ["sub_string": "mysubstring", "sub_bool": true],
            ]
        )
        let trigger = BAEventTrigger(
            name: "name",
            label: "label",
            attributes: [
                "key": "value",
                "key3": 3,
                "arrayKey2": [2, 3, 1],
                "arrayKey": ["item1", "item2", "item3"],
                "objectKey": ["sub_string": "mysubstring", "sub_bool": true],
            ]
        )

        // WHEN: The signal's `doesSatisfyTrigger` method is called with the trigger.
        // This is the action being tested: checking if the signal fulfills the trigger's requirements.
        let satisfied = signal.doesSatisfyTrigger(trigger)

        // THEN: The result is expected to be `false`.
        // Because of `"key": "Value" & arrayKey": ["Item1", "item2", "item3"]`
        #expect(satisfied == false)
    }
}
