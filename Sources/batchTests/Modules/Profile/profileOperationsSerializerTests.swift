//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import XCTest

final class profileOperationsSerializerTests: XCTestCase {
    func testEmptySerialization() throws {
        XCTAssertTrue(serializeEditor { _ in }.isEmpty)
    }

    func testLocaleSubscriptionStateSeriailization() throws {
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

    func testComplexSerialization() throws {
        let dateTimestamp = 1_596_975_143

        let serialized = try serializeEditor { editor in
            try editor.setEmail("test@batch.com")
            editor.setEmailMarketingSubscriptionState(.subscribed)
            try editor.setPhoneNumber("+33123456789")
            editor.setSMSMarketingSubscriptionState(.subscribed)
            try editor.setLanguage("fr_ch")
            try editor.setRegion("FR")
            try editor.setCustom(stringAttribute: "hello", forKey: "string_att")
            try editor.setCustom(int64Attribute: 3, forKey: "int_att")
            try editor.setCustom(doubleAttribute: 3.68, forKey: "double_att")
            try editor.setCustom(boolAttribute: true, forKey: "bool_att")
            try editor.setCustom(urlAttribute: URL(string: "https://batch.com/")!, forKey: "url_att")
            try editor.setCustom(dateAttribute: Date(timeIntervalSince1970: TimeInterval(dateTimestamp)) as NSDate, forKey: "date_att")
            try editor.setCustom(stringArrayAttribute: ["foo", "bar", "foo"], forKey: "string_array_att")

            try editor.deleteCustomAttribute(forKey: "delete_att")

            try editor.setCustom(stringAttribute: "foo", forKey: "overwrite")
            try editor.setCustom(int64Attribute: 5, forKey: "overwrite")

            try editor.setCustom(stringAttribute: "foo", forKey: "overwrite_array")
            try editor.add(value: "foo", toArray: "overwrite_array")

            try editor.add(value: "foo", toArray: "append_array_att")
            try editor.add(value: "bar", toArray: "append_array_att")
            try editor.remove(value: "baz", fromArray: "remove_array_att")

            try editor.setCustom(stringArrayAttribute: ["foo", "bar"], forKey: "complex_string_array_att")
            try editor.remove(value: "bar", fromArray: "complex_string_array_att")
            try editor.remove(value: "bar2", fromArray: "complex_string_array_att")
            try editor.add(value: "foo", toArray: "complex_string_array_att")
            try editor.add(value: "baz", toArray: "complex_string_array_att")
            try editor.add(value: "baz2", toArray: "complex_string_array_att")
            try editor.remove(value: "baz", fromArray: "complex_string_array_att")

            // Making an array and removing all its values should make it deleted
            try editor.setCustom(stringArrayAttribute: ["foo", "bar"], forKey: "absent_array_att")
            try editor.remove(value: "foo", fromArray: "absent_array_att")
            try editor.remove(value: "bar", fromArray: "absent_array_att")
        }

        XCTAssertEqual(serialized["email"] as? String, "test@batch.com")
        XCTAssertEqual(serialized["email_marketing"] as? String, "subscribed")
        XCTAssertEqual(serialized["phone_number"] as? String, "+33123456789")
        XCTAssertEqual(serialized["sms_marketing"] as? String, "subscribed")
        XCTAssertEqual(serialized["language"] as? String, "fr_ch")
        XCTAssertEqual(serialized["region"] as? String, "FR")

        guard let serializedAttributes = serialized["custom_attributes"] as? [AnyHashable: Any] else {
            XCTFail("missing 'custom_attributes'")
            return
        }

        XCTAssertEqual(serializedAttributes["string_att.s"] as? String, "hello")
        XCTAssertEqual(serializedAttributes["int_att.i"] as? Int, 3)
        XCTAssertEqual(serializedAttributes["double_att.f"] as? Double, 3.68)
        XCTAssertEqual(serializedAttributes["url_att.u"] as? String, "https://batch.com/")
        XCTAssertEqual(serializedAttributes["date_att.t"] as? Int, dateTimestamp * 1000)
        XCTAssertEqual(serializedAttributes["string_array_att.a"] as? [String], ["foo", "bar", "foo"])
        XCTAssertEqual(serializedAttributes["delete_att"] as? NSObject, NSNull())

        XCTAssertEqual(serializedAttributes["append_array_att.a"] as? NSDictionary, ["$add": ["foo", "bar"]] as NSDictionary)
        XCTAssertEqual(serializedAttributes["remove_array_att.a"] as? NSDictionary, ["$remove": ["baz"]] as NSDictionary)

        XCTAssertEqual(serializedAttributes["complex_string_array_att.a"] as? [String], ["foo", "foo", "baz2"])

        XCTAssertNil(serializedAttributes["absent_array_att.a"])
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
