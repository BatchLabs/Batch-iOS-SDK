//
//  BALocalCampaignsParserTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import Testing

/// Test suite for the `BALocalCampaignsParser`.
/// This suite validates the correct parsing of local campaign data from various JSON payloads.
struct BALocalCampaignsParserTests {
    // MARK: - Test Data

    /// A collection of static JSON-like dictionaries used as mock responses for testing the parser.
    fileprivate enum TestResponses {
        static let empty: [AnyHashable: Any] = [
            "campaigns": []
        ]

        static let cappingPayload: [AnyHashable: Any] = [
            "cappings": [
                "session": 2,
                "time": [
                    ["views": 1, "duration": 3600],
                    ["views": 0, "duration": 3600],
                    ["views": 1, "duration": 0],
                ],
            ]
        ]

        static let quietHoursPayload: NSDictionary = [
            "quietHours": [
                "startHour": 10,
                "startMin": 15,
                "endHour": 18,
                "endMin": 0,
                "quietDaysOfWeek": [0, 2, 3, 4, 5],
            ]
        ]

        static let versionPayload: [AnyHashable: Any] = [
            "campaigns_version": "CEP"
        ]

        static let sizeEventPayload: [AnyHashable: Any] = [
            "type": "EVENT",
            "event": "e.add_to_cart",
            "attributes": ["size.s": "M"],
        ]

        static let campaignPayload: [AnyHashable: Any] = [
            "campaignId": "orchestration_06b7scw87y3fk5js9g28m7xbe55kq5nf",
            "campaignToken": "orchestration_06b7scw87y3fk5js9g28m7xbe55kq5nf",
            "minimumApiLevel": 6,
            "minDisplayInterval": 3600,
            "triggers": [
                ["type": "NEXT_SESSION"]
            ],
            "quietHours": [
                "startHour": 10,
                "startMin": 15,
                "endHour": 18,
                "endMin": 0,
                "quietDaysOfWeek": [0, 1, 2, 3, 4, 5, 6],
            ],
            "displayDelaySec": 45,
            "eventData": [
                "t": "l",
                "v": "0",
                "lth": "IAM-2-BUTTON-NEUTRAL-20",
                "ct": "orchestration_06b7scw87y3fk5js9g28m7xbe55kq5nf",
                "labels": ["ABTESTING", "ONBOARDING"],
            ],
            "output": [
                "type": "LANDING_CEP",
                "payload": [:],
            ],
        ]

        static let campaignPayloadWithSizeEvent: [AnyHashable: Any] = [
            "campaignId": "orchestration_06b7scw87y3fk5js9g28m7xbe55kq5nf",
            "campaignToken": "orchestration_06b7scw87y3fk5js9g28m7xbe55kq5nf",
            "minimumApiLevel": 6,
            "minDisplayInterval": 3600,
            "triggers": [
                sizeEventPayload
            ],
            "quietHours": [
                "startHour": 10,
                "startMin": 15,
                "endHour": 18,
                "endMin": 0,
                "quietDaysOfWeek": [0, 1, 2, 3, 4, 5, 6],
            ],
            "displayDelaySec": 45,
            "eventData": [
                "t": "l",
                "v": "0",
                "lth": "IAM-2-BUTTON-NEUTRAL-20",
                "ct": "orchestration_06b7scw87y3fk5js9g28m7xbe55kq5nf",
                "labels": ["ABTESTING", "ONBOARDING"],
            ],
            "output": [
                "type": "LANDING_CEP",
                "payload": [:],
            ],
        ]
    }

    /// Tests focused on the top-level parsing logic of the `BALocalCampaignsParser`.
    @Suite
    struct Parser {
        @Test func persistence() throws {
            // GIVEN: An empty campaign response payload.
            let emptyResponse = TestResponses.empty
            var outPersistable: NSDictionary?

            // WHEN: The `parseCampaigns` method is invoked.
            let campaigns = try BALocalCampaignsParser.parseCampaigns(emptyResponse, outPersistable: &outPersistable, version: .MEP)

            // THEN: The method should return an empty array of campaigns and produce a non-nil `outPersistable`
            //       dictionary that contains an empty "campaigns" array, ensuring that the persistence
            //       object is correctly initialized even when there's no data.
            #expect(campaigns.count == 0, "Expected campaign count to be 0 for an empty response.")

            let unwrappedPersistable = try #require(outPersistable, "outPersistable should not be nil.")
            let persistedCampaigns = try #require(unwrappedPersistable["campaigns"] as? NSArray, "Persisted campaigns should be an NSArray.")

            #expect(persistedCampaigns.count == 0, "Persisted campaigns array should be empty.")
        }

        @Test func cappings() throws {
            // GIVEN: A payload containing various capping rules (session-based and time-based).
            let cappingResponse = TestResponses.cappingPayload
            var outPersistable: NSDictionary?

            // WHEN: The `parseCappings` method is invoked.
            let cappings = BALocalCampaignsParser.parseCappings(cappingResponse, outPersistable: &outPersistable)

            // THEN: The method should correctly parse the valid capping rules, filtering out any invalid entries.
            //       It should also populate the `outPersistable` dictionary with the parsed capping data.
            let unwrappedCappings = try #require(cappings, "Parsed cappings object should not be nil.")
            #expect(unwrappedCappings.session == 2, "Session capping should be parsed correctly.")
            #expect(unwrappedCappings.timeBasedCappings?.count == 1, "Should filter out invalid time-based cappings.")

            let unwrappedPersistable = try #require(outPersistable, "outPersistable should not be nil.")
            #expect(unwrappedPersistable["cappings"] != nil, "Cappings data should be present in the persistable dictionary.")
        }

        @Test func version() throws {
            // GIVEN: A payload specifying the campaign data version.
            let versionResponse = TestResponses.versionPayload
            var outPersistable: NSDictionary?
            var error: NSError?

            // WHEN: The `parseVersion` method is invoked.
            let version = BALocalCampaignsParser.parseVersion(versionResponse, outPersistable: &outPersistable, error: &error)

            // THEN: The method should return the correct version enum (`.CEP`) and populate the `outPersistable`
            //       dictionary with the version information for persistence.
            #expect(version == .CEP, "Parsed version should be '.CEP'.")
            #expect(error == nil, "Parsing a valid version should not produce an error.")

            let unwrappedPersistable = try #require(outPersistable, "outPersistable should not be nil.")
            #expect(unwrappedPersistable[kParametersLocalCampaignsVersionPayloadKey] != nil, "Version should be present in the persistable dictionary.")
        }
    }

    /// Tests focused on parsing individual campaign objects and their properties.
    @Suite
    struct Campaign {
        @Test func quietHours() throws {
            // GIVEN: A dictionary containing quiet hours configuration.
            let quietHoursDict = try #require(TestResponses.quietHoursPayload["quietHours"] as? [AnyHashable: Any])

            // WHEN: A `BALocalCampaignQuietHours` object is initialized with this dictionary.
            let quietHours = BALocalCampaignQuietHours(dictionary: quietHoursDict)

            // THEN: The object should be created successfully, and all its properties (start/end times, days of the week)
            //       should match the values from the input dictionary.
            let unwrappedQuietHours = try #require(quietHours, "Quiet hours object should not be nil.")
            #expect(unwrappedQuietHours.startHour == 10)
            #expect(unwrappedQuietHours.startMin == 15)
            #expect(unwrappedQuietHours.endHour == 18)
            #expect(unwrappedQuietHours.endMin == 0)
            #expect(unwrappedQuietHours.quietDaysOfWeek == [0, 2, 3, 4, 5])
        }
    }

    /// Tests focused on the logic for event trigger attributes.
    @Suite
    struct Attributes {
        @Test func equals() throws {
            // GIVEN: A campaign with an event trigger that requires a specific attribute (`size.s` = "M").
            let campaign = try BALocalCampaignsParser.parseCampaign(TestResponses.campaignPayloadWithSizeEvent, version: .MEP)
            let trigger = try #require(campaign.triggers.first as? BAEventTrigger, "Campaign should have an event trigger.")
            let eventAttributes = try #require(TestResponses.sizeEventPayload["attributes"] as? [AnyHashable: Any], "Event attributes should be a valid dictionary.")

            // WHEN: The campaign is parsed, and the trigger's `isSatisfied` method is called with a dictionary
            //       containing the required attribute.
            let isSatisfied = trigger.isSatisfied(forAttributes: eventAttributes)

            // THEN: The `isSatisfied` method should return `true`, confirming that the attribute matching
            //       logic is working as expected.
            #expect(isSatisfied, "Trigger should be satisfied when attributes match.")
        }
    }
}
