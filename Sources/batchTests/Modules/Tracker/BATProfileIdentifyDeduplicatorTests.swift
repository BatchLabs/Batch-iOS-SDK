//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import Testing

@testable import Batch

struct BATProfileIdentifyDeduplicatorTests {

    // MARK: - Helpers

    static func identifyEvent(customId: String?) -> BAEvent {
        let params: String
        if let customId = customId {
            params = #"{"identifiers":{"custom_id":"\#(customId)"}}"#
        } else {
            params = #"{"identifiers":{"custom_id":null}}"#
        }
        return BAEvent(
            identifier: "id-\(customId ?? "null")",
            name: "_PROFILE_IDENTIFY",
            date: "12345",
            secureDate: "123456",
            parameters: params,
            state: BAEventStateNew,
            session: "session",
            andTick: Int64(0)
        )
    }

    static func otherEvent(_ name: String) -> BAEvent {
        return BAEvent(
            identifier: "id-\(name)",
            name: name,
            date: "12345",
            secureDate: "123456",
            parameters: nil,
            state: BAEventStateNew,
            session: "session",
            andTick: Int64(0)
        )
    }

    // MARK: - extractCustomId

    @Test func extractCustomId_nilParameters_returnsNil() {
        #expect(BATProfileIdentifyDeduplicator.extractCustomId(from: nil) == nil)
    }

    @Test func extractCustomId_invalidJson_returnsNil() {
        #expect(BATProfileIdentifyDeduplicator.extractCustomId(from: "not-json") == nil)
    }

    @Test func extractCustomId_noIdentifiersObject_returnsNil() {
        #expect(BATProfileIdentifyDeduplicator.extractCustomId(from: #"{"foo":"bar"}"#) == nil)
    }

    @Test func extractCustomId_identifiersWithoutCustomId_returnsNil() {
        #expect(
            BATProfileIdentifyDeduplicator.extractCustomId(
                from: #"{"identifiers":{"other":"value"}}"#
            ) == nil
        )
    }

    @Test func extractCustomId_identifiersWithNullCustomId_returnsNil() {
        #expect(
            BATProfileIdentifyDeduplicator.extractCustomId(
                from: #"{"identifiers":{"custom_id":null}}"#
            ) == nil
        )
    }

    @Test func extractCustomId_validCustomId_returnsValue() {
        #expect(
            BATProfileIdentifyDeduplicator.extractCustomId(
                from: #"{"identifiers":{"custom_id":"user123"}}"#
            ) == "user123"
        )
    }

    @Test func extractCustomId_emptyCustomId_returnsEmptyString() {
        #expect(
            BATProfileIdentifyDeduplicator.extractCustomId(
                from: #"{"identifiers":{"custom_id":""}}"#
            ) == ""
        )
    }

    // MARK: - deduplicate

    @Test func deduplicate_emptyList_returnsEmpty() {
        let result = BATProfileIdentifyDeduplicator.deduplicate([] as NSArray)
        #expect(result.count == 0)
    }

    @Test func deduplicate_noIdentifyEvents_returnsAllUnchanged() {
        let events: NSArray = [Self.otherEvent("_START"), Self.otherEvent("_STOP")]
        let result = BATProfileIdentifyDeduplicator.deduplicate(events)
        #expect(result.count == 2)
        #expect((result[0] as! BAEvent).name == "_START")
        #expect((result[1] as! BAEvent).name == "_STOP")
    }

    @Test func deduplicate_singleIdentifyEvent_returnsIt() {
        let result = BATProfileIdentifyDeduplicator.deduplicate([Self.identifyEvent(customId: "alice")] as NSArray)
        #expect(result.count == 1)
    }

    @Test func deduplicate_twoIdentifyWithSameCustomId_keepsOnlyFirst() {
        let first = Self.identifyEvent(customId: "alice")
        let second = Self.identifyEvent(customId: "alice")
        let result = BATProfileIdentifyDeduplicator.deduplicate([first, second] as NSArray)
        #expect(result.count == 1)
        #expect((result[0] as! BAEvent).identifier == first.identifier)
    }

    @Test func deduplicate_twoIdentifyWithDifferentCustomId_keepsBoth() {
        let events: NSArray = [Self.identifyEvent(customId: "alice"), Self.identifyEvent(customId: "bob")]
        let result = BATProfileIdentifyDeduplicator.deduplicate(events)
        #expect(result.count == 2)
    }

    @Test func deduplicate_threeIdentifyAllSameCustomId_keepsOnlyFirst() {
        let events: NSArray = [
            Self.identifyEvent(customId: "alice"),
            Self.identifyEvent(customId: "alice"),
            Self.identifyEvent(customId: "alice"),
        ]
        let result = BATProfileIdentifyDeduplicator.deduplicate(events)
        #expect(result.count == 1)
    }

    @Test func deduplicate_twoNullCustomIds_keepsOnlyFirst() {
        let first = Self.identifyEvent(customId: nil)
        let second = Self.identifyEvent(customId: nil)
        let result = BATProfileIdentifyDeduplicator.deduplicate([first, second] as NSArray)
        #expect(result.count == 1)
        #expect((result[0] as! BAEvent).identifier == first.identifier)
    }

    @Test func deduplicate_nullThenNonNullCustomId_keepsBoth() {
        let events: NSArray = [Self.identifyEvent(customId: nil), Self.identifyEvent(customId: "alice")]
        let result = BATProfileIdentifyDeduplicator.deduplicate(events)
        #expect(result.count == 2)
    }

    @Test func deduplicate_nonIdentifyBetweenSameCustomIds_secondIdentifyRemoved() {
        let first = Self.identifyEvent(customId: "alice")
        let middle = Self.otherEvent("_START")
        let second = Self.identifyEvent(customId: "alice")
        let result = BATProfileIdentifyDeduplicator.deduplicate([first, middle, second] as NSArray)
        #expect(result.count == 2)
        #expect((result[0] as! BAEvent).identifier == first.identifier)
        #expect((result[1] as! BAEvent).identifier == middle.identifier)
    }

    @Test func deduplicate_nonIdentifyBetweenDifferentCustomIds_allKept() {
        let events: NSArray = [
            Self.identifyEvent(customId: "alice"),
            Self.otherEvent("_START"),
            Self.identifyEvent(customId: "bob"),
        ]
        let result = BATProfileIdentifyDeduplicator.deduplicate(events)
        #expect(result.count == 3)
    }

    @Test func deduplicate_identifyCustomIdChangesAndThenRepeats_deduplicatesSecondRepeat() {
        // alice → bob → alice: all three are distinct transitions, all kept
        let events: NSArray = [
            Self.identifyEvent(customId: "alice"),
            Self.identifyEvent(customId: "bob"),
            Self.identifyEvent(customId: "alice"),
        ]
        let result = BATProfileIdentifyDeduplicator.deduplicate(events)
        #expect(result.count == 3)
    }

    @Test func deduplicate_originalListUnmodified() {
        let original: NSArray = [Self.identifyEvent(customId: "alice"), Self.identifyEvent(customId: "alice")]
        BATProfileIdentifyDeduplicator.deduplicate(original)
        #expect(original.count == 2)
    }
}
