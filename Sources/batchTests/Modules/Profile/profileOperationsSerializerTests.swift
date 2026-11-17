//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import XCTest

@testable import Batch

final class profileOperationsSerializerTests: XCTestCase {
    func testEmptySerialization() throws {
        XCTAssertTrue(serializeEditor { _ in }.isEmpty)
    }

    func testLocaleSubscriptionStateSerialization() throws {
        let serialized = serializeEditor { editor in
            editor.setEmailMarketingSubscriptionState(.subscribed)
            editor.setSMSMarketingSubscriptionState(.subscribed)
        }

        XCTAssertEqual(serialized["email_marketing"] as? String, "subscribed")
        XCTAssertEqual(serialized["sms_marketing"] as? String, "subscribed")

        let unsubscribedSerialized = serializeEditor { editor in
            editor.setEmailMarketingSubscriptionState(.unsubscribed)
            editor.setSMSMarketingSubscriptionState(.unsubscribed)
        }

        XCTAssertEqual(unsubscribedSerialized["email_marketing"] as? String, "unsubscribed")
        XCTAssertEqual(unsubscribedSerialized["sms_marketing"] as? String, "unsubscribed")
    }

    func testEmailOpenTrackingConsentSerialization() throws {
        let grantedSerialized = serializeEditor { editor in
            editor.setEmailOpenTrackingConsent(.granted)
        }
        XCTAssertEqual(grantedSerialized["email_open_tracking_consent"] as? String, "granted")

        let deniedSerialized = serializeEditor { editor in
            editor.setEmailOpenTrackingConsent(.denied)
        }
        XCTAssertEqual(deniedSerialized["email_open_tracking_consent"] as? String, "denied")

        // Last call wins
        let overriddenSerialized = serializeEditor { editor in
            editor.setEmailOpenTrackingConsent(.granted)
            editor.setEmailOpenTrackingConsent(.denied)
        }
        XCTAssertEqual(overriddenSerialized["email_open_tracking_consent"] as? String, "denied")

        // Key is absent when the consent has not been set
        let notSetSerialized = serializeEditor { editor in
            editor.setEmailMarketingSubscriptionState(.subscribed)
        }
        XCTAssertFalse(notSetSerialized.keys.contains("email_open_tracking_consent"))
    }

    /// Test that the email open tracking consent can be set on a profile that has not been identified
    func testCanSetEmailOpenTrackingConsentWithoutIdentification() throws {
        let editor = TestProfileEditor()
        editor.test_isProfileIdentified = false

        editor.setEmailOpenTrackingConsent(.granted)

        let serialized = BATProfileOperationsSerializer.serialize(profileEditor: editor)
        XCTAssertEqual(serialized["email_open_tracking_consent"] as? String, "granted")
    }

    /// Test that the email open tracking consent is ignored once the editor has been consumed, and kept by copies
    func testEmailOpenTrackingConsentConsumedAndCopy() throws {
        let editor = TestProfileEditor()
        editor.setEmailOpenTrackingConsent(.granted)

        let copy = try XCTUnwrap(editor.copy() as? BATProfileEditor)
        XCTAssertEqual(BATProfileOperationsSerializer.serialize(profileEditor: copy)["email_open_tracking_consent"] as? String, "granted")

        editor.consume()
        editor.setEmailOpenTrackingConsent(.denied)
        XCTAssertEqual(BATProfileOperationsSerializer.serialize(profileEditor: editor)["email_open_tracking_consent"] as? String, "granted")
    }

    func testComplexSerialization() throws {
        let dateTimestamp = 1_596_975_143

        let serialized = try serializeEditor { editor in
            try editor.setEmail("test@batch.com")
            editor.setEmailMarketingSubscriptionState(.subscribed)
            editor.setEmailOpenTrackingConsent(.granted)
            try editor.setPhoneNumber("+33123456789")
            editor.setSMSMarketingSubscriptionState(.subscribed)
            try editor.setLanguage("fr_ch")
            try editor.setRegion("FR")
            try editor.setTopicPreferences(["news", "offers"])
            try editor.removeFromTopicPreferences(["news"])
            try editor.addToTopicPreferences(["new_topic"])
            try editor.setCustom(stringAttribute: "hello", forKey: "string_att")
            try editor.setCustom(int64Attribute: 3, forKey: "int_att")
            try editor.setCustom(doubleAttribute: 3.68, forKey: "double_att")
            try editor.setCustom(boolAttribute: true, forKey: "bool_att")
            try editor.setCustom(urlAttribute: URL(string: "https://batch.com/")!, forKey: "url_att")
            try editor.setCustom(dateAttribute: Date(timeIntervalSince1970: TimeInterval(dateTimestamp)) as NSDate, forKey: "date_att")
            try editor.setCustom(stringArrayAttribute: ["foo", "bar", "foo"], forKey: "string_array_att")

            try editor.deleteCustomAttribute(forKey: "delete_att")

            try editor.setCustom(stringAttribute: "foo", forKey: "overwrite")
            try editor.setCustom(stringAttribute: String(repeating: "not_too_long", count: 25), forKey: "string_not_too_long")
            try? editor.setCustom(stringAttribute: String(repeating: "too_long", count: 40), forKey: "string_too_long")
            try editor.setCustom(int64Attribute: 5, forKey: "overwrite")

            try editor.setCustom(stringAttribute: "foo", forKey: "overwrite_array")
            try editor.add(value: "foo", toArray: "overwrite_array")

            try editor.add(value: "foo", toArray: "append_array_att")
            try editor.add(value: "bar", toArray: "append_array_att")
            try? editor.add(value: String(repeating: "too_long", count: 40), toArray: "append_array_att")

            try editor.remove(value: "baz", fromArray: "remove_array_att")
            try? editor.add(value: String(repeating: "too_long", count: 40), toArray: "remove_array_att")

            try editor.setCustom(stringArrayAttribute: ["foo", "bar"], forKey: "complex_string_array_att")
            try editor.remove(value: "bar", fromArray: "complex_string_array_att")
            try editor.remove(value: "bar2", fromArray: "complex_string_array_att")
            try editor.add(value: "foo", toArray: "complex_string_array_att")
            try editor.add(value: "baz", toArray: "complex_string_array_att")
            try editor.add(value: "baz2", toArray: "complex_string_array_att")
            try? editor.add(value: String(repeating: "too_long", count: 40), toArray: "complex_string_array_att")
            try editor.remove(value: "baz", fromArray: "complex_string_array_att")

            // Making an array and removing all its values should make it deleted
            try editor.setCustom(stringArrayAttribute: ["foo", "bar"], forKey: "absent_array_att")
            try editor.remove(value: "foo", fromArray: "absent_array_att")
            try editor.remove(value: "bar", fromArray: "absent_array_att")
        }

        XCTAssertEqual(serialized["email"] as? String, "test@batch.com")
        XCTAssertEqual(serialized["email_marketing"] as? String, "subscribed")
        XCTAssertEqual(serialized["email_open_tracking_consent"] as? String, "granted")
        XCTAssertEqual(serialized["phone_number"] as? String, "+33123456789")
        XCTAssertEqual(serialized["sms_marketing"] as? String, "subscribed")
        XCTAssertEqual(serialized["language"] as? String, "fr_ch")
        XCTAssertEqual(serialized["region"] as? String, "FR")
        XCTAssertEqual(serialized["topic_preferences"] as? [String], ["offers", "new_topic"])

        guard let serializedAttributes = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing 'custom_attributes'")
            return
        }

        XCTAssertEqual(serializedAttributes["string_att.s"] as? String, "hello")
        XCTAssertEqual(serializedAttributes["int_att.i"] as? Int, 3)
        XCTAssertEqual(serializedAttributes["double_att.f"] as? Double, 3.68)
        XCTAssertEqual(serializedAttributes["url_att.u"] as? String, "https://batch.com/")
        XCTAssertEqual(serializedAttributes["date_att.t"] as? Int, dateTimestamp * 1000)
        XCTAssertEqual(serializedAttributes["string_array_att.a"] as? [String], ["bar", "foo"])
        XCTAssertEqual(serializedAttributes["delete_att"] as? NSObject, NSNull())

        XCTAssertEqual(serializedAttributes["append_array_att.a"] as? NSDictionary, ["$add": ["foo", "bar"]] as NSDictionary)
        XCTAssertEqual(serializedAttributes["remove_array_att.a"] as? NSDictionary, ["$remove": ["baz"]] as NSDictionary)

        XCTAssertEqual(serializedAttributes["complex_string_array_att.a"] as? [String], ["foo", "baz2"])

        XCTAssertNil(serializedAttributes["absent_array_att.a"])
        XCTAssertEqual(serializedAttributes["absent_array_att"] as? NSObject, NSNull())

        XCTAssertNotNil(serializedAttributes["string_not_too_long.s"])
        XCTAssertNil(serializedAttributes["string_too_long.s"])

    }

    /// Test that overriding previously set attributes properly works
    func testAttributeOverride() throws {
        let serialized = try serializeEditor { editor in
            try editor.setCustom(stringAttribute: "hello", forKey: "att1")
            try editor.setCustom(int64Attribute: 4, forKey: "att1")

            try editor.setCustom(stringAttribute: "foo", forKey: "att2")
            try editor.setCustom(stringArrayAttribute: ["bar"], forKey: "att2")

            try editor.setCustom(stringAttribute: "bar", forKey: "att3")
            try editor.add(value: "baz", toArray: "att3")

            try editor.setCustom(stringAttribute: "bar", forKey: "att4")
            try editor.remove(value: "baz", fromArray: "att4")

            try editor.add(value: "baz", toArray: "att5")
            try editor.setCustom(int64Attribute: 5, forKey: "att5")
        }

        XCTAssertNil(serialized["email"])
        XCTAssertNil(serialized["email_marketing"])
        XCTAssertNil(serialized["email_open_tracking_consent"])
        XCTAssertNil(serialized["language"])
        XCTAssertNil(serialized["region"])
        guard let serializedAttributes = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing 'custom_attributes'")
            return
        }

        XCTAssertEqual(serializedAttributes["att1.i"] as? Int, 4)
        XCTAssertEqual(serializedAttributes["att2.a"] as? [String], ["bar"])
        XCTAssertEqual(serializedAttributes["att3.a"] as? NSDictionary, ["$add": ["baz"]] as NSDictionary)
        XCTAssertEqual(serializedAttributes["att4.a"] as? NSDictionary, ["$remove": ["baz"]] as NSDictionary)
        XCTAssertEqual(serializedAttributes["att5.i"] as? Int, 5)
    }

    func testSubscriptionTest() throws {

        // Test simple Set use case
        var serialized = try serializeEditor { editor in
            try editor.setTopicPreferences(["news", "offers"])

        }
        XCTAssertEqual(serialized["topic_preferences"] as? [String], ["news", "offers"])

        // Test Set + Update use case
        serialized = try serializeEditor { editor in
            try editor.setTopicPreferences(["news", "offers"])
            try editor.removeFromTopicPreferences(["news"])
            try editor.addToTopicPreferences(["shopping"])
        }
        XCTAssertEqual(serialized["topic_preferences"] as? [String], ["offers", "shopping"])

        // Test simple partial update use case
        serialized = try serializeEditor { editor in
            try editor.removeFromTopicPreferences(["news"])
            try editor.addToTopicPreferences(["shopping"])

        }
        XCTAssertEqual(serialized["topic_preferences"] as? NSDictionary, ["$remove": ["news"], "$add": ["shopping"]] as NSDictionary)

        // Test Partial Update + Set use case (should override)
        serialized = try serializeEditor { editor in
            try editor.removeFromTopicPreferences(["news"])
            try editor.addToTopicPreferences(["shopping"])
            try editor.setTopicPreferences(["news", "offers"])
        }
        XCTAssertEqual(serialized["topic_preferences"] as? [String], ["news", "offers"])

        // Test Remove use case (should override)
        serialized = try serializeEditor { editor in
            try editor.setTopicPreferences(nil)
        }
        XCTAssertEqual(serialized["topic_preferences"] as? NSObject, NSNull())

        // Test Set + Update use case
        serialized = try serializeEditor { editor in
            try editor.setTopicPreferences(["news", "Offers"])
            try editor.removeFromTopicPreferences(["News"])  // should be normlaized and removed
            try? editor.addToTopicPreferences(["shopping with friend"])  // should throw
        }
        XCTAssertEqual(serialized["topic_preferences"] as? [String], ["offers"])
    }

    func testStringArrayAttributeDeduplication() throws {
        // setCustom(stringArrayAttribute:) deduplicates, last occurrence wins
        let serialized = try serializeEditor { editor in
            try editor.setCustom(stringArrayAttribute: ["d", "e", "d", "a", "f", "a"], forKey: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr.a"] as? [String], ["e", "d", "f", "a"])
    }

    func testAddToStringArrayOnExistingSetDeduplicates() throws {
        // Adding a value already in the set array moves it to the end (last-wins)
        let serialized = try serializeEditor { editor in
            try editor.setCustom(stringArrayAttribute: ["a", "b"], forKey: "arr")
            try editor.add(value: "a", toArray: "arr")
            try editor.add(value: "c", toArray: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr.a"] as? [String], ["b", "a", "c"])
    }

    func testPartialArrayAddDeduplicatesAcrossMultipleCalls() throws {
        // Adding the same value twice across calls deduplicates in $add (last-wins)
        let serialized = try serializeEditor { editor in
            try editor.add(value: "a", toArray: "arr")
            try editor.add(value: "b", toArray: "arr")
            try editor.add(value: "a", toArray: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr.a"] as? NSDictionary, ["$add": ["b", "a"]] as NSDictionary)
    }

    func testPartialArrayRemoveDeduplicatesAcrossMultipleCalls() throws {
        // Removing the same value twice across calls deduplicates in $remove (last-wins)
        let serialized = try serializeEditor { editor in
            try editor.remove(value: "a", fromArray: "arr")
            try editor.remove(value: "b", fromArray: "arr")
            try editor.remove(value: "a", fromArray: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr.a"] as? NSDictionary, ["$remove": ["b", "a"]] as NSDictionary)
    }

    func testSetStringArrayWith26ItemsOneDuplicateIsAccepted() throws {
        // 26 inputs but the first is repeated at the end — dedup yields 25 unique items
        let items = (1...25).map { "\($0)" } + ["1"]
        XCTAssertNoThrow(
            try serializeEditor { editor in
                try editor.setCustom(stringArrayAttribute: items, forKey: "arr")
            }
        )
        let serialized = try serializeEditor { editor in
            try editor.setCustom(stringArrayAttribute: items, forKey: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        let expected = (2...25).map { "\($0)" } + ["1"]
        XCTAssertEqual(customAttrs["arr.a"] as? [String], expected)
    }

    func testAddToArrayAfterRemoveAttributeSendsFullArray() throws {
        // Deleting the attribute then adding to it must replace the server-side array, not
        // send a partial $add that would keep the old items. Mirrors Android and Web.
        let serialized = try serializeEditor { editor in
            try editor.deleteCustomAttribute(forKey: "arr")
            try editor.add(value: "a", toArray: "arr")
            try editor.add(value: "b", toArray: "arr")
            try editor.add(value: "a", toArray: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr.a"] as? [String], ["b", "a"])
        XCTAssertNil(customAttrs["arr"])
    }

    func testRemoveFromArrayAfterRemoveAttributeKeepsDelete() throws {
        // Removing from a deleted array changes nothing: the delete must survive
        let serialized = try serializeEditor { editor in
            try editor.deleteCustomAttribute(forKey: "arr")
            try editor.remove(value: "a", fromArray: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr"] as? NSObject, NSNull())
        XCTAssertNil(customAttrs["arr.a"])
    }

    func testRemoveAttributeAfterAddToArrayKeepsDelete() throws {
        // The reverse order: the delete is the last word
        let serialized = try serializeEditor { editor in
            try editor.add(value: "a", toArray: "arr")
            try editor.deleteCustomAttribute(forKey: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr"] as? NSObject, NSNull())
        XCTAssertNil(customAttrs["arr.a"])
    }

    func testAddToArrayAfterRemoveAttributeWith26ItemsOneDuplicateIsAccepted() throws {
        // 26 adds but "1" is repeated at the end — dedup yields 25 unique items, which is valid
        let items = (1...25).map { "\($0)" } + ["1"]
        let serialized = try serializeEditor { editor in
            try editor.deleteCustomAttribute(forKey: "arr")
            for item in items {
                try editor.add(value: item, toArray: "arr")
            }
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        let expected = (2...25).map { "\($0)" } + ["1"]
        XCTAssertEqual(customAttrs["arr.a"] as? [String], expected)
    }

    func testTopicPreferencesUpdateAfterReset() throws {
        // Resetting the topic preferences then adding to them must send the full list
        var serialized = try serializeEditor { editor in
            try editor.setTopicPreferences(nil)
            try editor.addToTopicPreferences(["sport"])
        }
        XCTAssertEqual(serialized["topic_preferences"] as? [String], ["sport"])

        // Resetting then removing keeps the reset
        serialized = try serializeEditor { editor in
            try editor.setTopicPreferences(nil)
            try editor.removeFromTopicPreferences(["sport"])
        }
        XCTAssertEqual(serialized["topic_preferences"] as? NSObject, NSNull())
    }

    func testRemovingLastItemOfArraySetDeletesAttribute() throws {
        // Emptying an array set in the editor must delete the attribute, otherwise the server keeps its previous value
        let serialized = try serializeEditor { editor in
            try editor.setCustom(stringArrayAttribute: ["a"], forKey: "arr")
            try editor.remove(value: "a", fromArray: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr"] as? NSObject, NSNull())
        XCTAssertNil(customAttrs["arr.a"])
    }

    func testDeleteThenAddThenRemoveKeepsDelete() throws {
        // The add turns the delete into an array set, emptying it must bring the delete back
        let serialized = try serializeEditor { editor in
            try editor.deleteCustomAttribute(forKey: "arr")
            try editor.add(value: "a", toArray: "arr")
            try editor.remove(value: "a", fromArray: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr"] as? NSObject, NSNull())
        XCTAssertNil(customAttrs["arr.a"])
    }

    func testAddThenRemoveSameItemKeepsOnlyRemove() throws {
        // Opposite partial updates on the same item: the last call wins
        let serialized = try serializeEditor { editor in
            try editor.add(value: "a", toArray: "arr")
            try editor.remove(value: "a", fromArray: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr.a"] as? NSDictionary, ["$remove": ["a"]] as NSDictionary)
    }

    func testRemoveThenAddSameItemKeepsOnlyAdd() throws {
        let serialized = try serializeEditor { editor in
            try editor.remove(value: "a", fromArray: "arr")
            try editor.add(value: "a", toArray: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr.a"] as? NSDictionary, ["$add": ["a"]] as NSDictionary)
    }

    func testRemoveCancelsOnlyTheMatchingPendingAdd() throws {
        let serialized = try serializeEditor { editor in
            try editor.add(value: "a", toArray: "arr")
            try editor.add(value: "b", toArray: "arr")
            try editor.remove(value: "a", fromArray: "arr")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertEqual(customAttrs["arr.a"] as? NSDictionary, ["$add": ["b"], "$remove": ["a"]] as NSDictionary)
    }

    func testTopicPreferencesOppositePartialUpdatesCancel() throws {
        let serialized = try serializeEditor { editor in
            try editor.addToTopicPreferences(["sport", "news"])
            try editor.removeFromTopicPreferences(["sport"])
        }
        XCTAssertEqual(serialized["topic_preferences"] as? NSDictionary, ["$add": ["news"], "$remove": ["sport"]] as NSDictionary)
    }

    func testTopicPreferencesEmptiedSetResetsThem() throws {
        // The server ignores an empty topic list, so emptying the set must send a reset
        var serialized = try serializeEditor { editor in
            try editor.setTopicPreferences(["sport"])
            try editor.removeFromTopicPreferences(["sport"])
        }
        XCTAssertEqual(serialized["topic_preferences"] as? NSObject, NSNull())

        // Same when the set comes from an add after a reset
        serialized = try serializeEditor { editor in
            try editor.setTopicPreferences(nil)
            try editor.addToTopicPreferences(["sport"])
            try editor.removeFromTopicPreferences(["sport"])
        }
        XCTAssertEqual(serialized["topic_preferences"] as? NSObject, NSNull())
    }

    func testDoubleAttributeRejectsNaNAndInfinity() throws {
        // NaN and infinity can't be written as JSON, so they must be rejected when set
        let serialized = try serializeEditor { editor in
            for value in [Double.nan, .infinity, -.infinity] {
                XCTAssertThrowsError(try editor.setCustom(doubleAttribute: value, forKey: "rejected")) { error in
                    XCTAssertEqual((error as NSError).code, BatchProfileError.Code.editorInvalidValue.rawValue)
                }
            }
            try editor.setCustom(doubleAttribute: 3.5, forKey: "accepted")
        }
        guard let customAttrs = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing custom_attributes")
            return
        }
        XCTAssertNil(customAttrs["rejected.f"])
        XCTAssertEqual(customAttrs["accepted.f"] as? Double, 3.5)
    }

    func testTopicPreferencesDeduplication() throws {
        // Case-folding creates duplicates that dedup (last-wins)
        var serialized = try serializeEditor { editor in
            try editor.setTopicPreferences(["Sport", "news", "sport"])
        }
        XCTAssertEqual(serialized["topic_preferences"] as? [String], ["news", "sport"])

        // Partial add: duplicates within a single call are deduped in $add
        serialized = try serializeEditor { editor in
            try editor.addToTopicPreferences(["sport", "news", "sport"])
        }
        XCTAssertEqual(serialized["topic_preferences"] as? NSDictionary, ["$add": ["news", "sport"]] as NSDictionary)

        // Partial add: second call with "News" normalizes to "news", already in $add — moves to end
        serialized = try serializeEditor { editor in
            try editor.addToTopicPreferences(["sport", "news", "sport"])
            try editor.addToTopicPreferences(["News"])
        }
        XCTAssertEqual(serialized["topic_preferences"] as? NSDictionary, ["$add": ["sport", "news"]] as NSDictionary)
    }

    func testSetTopicPreferencesWith26ItemsOneDuplicateIsAccepted() throws {
        // 26 topics but topic_0 is repeated — dedup brings to 25, which is valid
        var topics = (0..<25).map { "topic_\($0)" }
        topics.append("topic_0")
        XCTAssertEqual(topics.count, 26)

        let serialized = try serializeEditor { editor in
            try editor.setTopicPreferences(topics)
        }
        guard let prefs = serialized["topic_preferences"] as? [String] else {
            XCTFail("missing topic_preferences")
            return
        }
        XCTAssertEqual(prefs.count, 25)
        XCTAssertEqual(prefs.last, "topic_0")
    }

    /// Test that an email cannot be set and is not serialized if not allowed
    func testCantSetEmail() throws {
        let editor = TestProfileEditor()
        editor.test_isProfileIdentified = false

        XCTAssertThrowsError(try editor.setEmail("test@batch.com"))

        let serialized = BATProfileOperationsSerializer.serialize(profileEditor: editor)
        XCTAssertNil(serialized["email"])
    }

    /// Test that a phone number cannot be set and is not serialized if not allowed
    func testCantSetPhoneNumber() throws {
        let editor = TestProfileEditor()
        editor.test_isProfileIdentified = false

        XCTAssertThrowsError(try editor.setPhoneNumber("+33123456789"))

        let serialized = BATProfileOperationsSerializer.serialize(profileEditor: editor)
        XCTAssertNil(serialized["phone_number"])
    }

    func serializeEditor(_ editClosure: (BATProfileEditor) throws -> Void) rethrows -> [AnyHashable: Any] {
        let editor = TestProfileEditor()
        editor.test_isProfileIdentified = true
        try editClosure(editor)
        return BATProfileOperationsSerializer.serialize(profileEditor: editor)
    }
}
