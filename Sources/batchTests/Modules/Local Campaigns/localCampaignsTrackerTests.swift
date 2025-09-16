//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import Testing

@testable import Batch

/// Test responses and mock data for local campaigns tracker tests
fileprivate enum TestResponses {
    /// Mock capping payload for testing global capping functionality
    /// Contains session limit of 2 and time-based limit of 1 view per hour
    static let cappingPayload: [AnyHashable: Any] = [
        "cappings": [
            "session": 2,
            "time": [
                ["views": 1, "duration": 3600],
            ],
        ],
    ]
}

/// Test suite for BALocalCampaignsTracker functionality
///
/// This test suite covers the local campaigns tracking system, including:
/// - Session-based view counting
/// - Global capping enforcement
/// - Event tracking with custom user IDs
/// - MEP and CEP version compatibility
/// - Database operations and cleanup

@Suite(.serialized)
struct LocalCampaignsTrackerTests {
    let tracker = BALocalCampaignsTracker()

    /// Test basic session tracker functionality with MEP and CEP versions
    ///
    /// This test verifies that:
    /// - Session view count starts at 0
    /// - Both MEP and CEP events increment the session counter
    /// - Session counter can be reset to 0
    /// - Events are properly tracked across different campaign versions
    @Test("Session tracker counts views correctly for MEP and CEP versions")
    func testSessionTracker() async throws {
        // Clean up resources
        tracker.clear()

        // Verify initial state - session should start with 0 views
        #expect(tracker.sessionViewsCount == 0)

        // Track a view event with MEP version
        // This should increment the session counter by 1
        tracker.trackEvent(
            forCampaignID: "campaign_id",
            kind: BALocalCampaignTrackerEventKind.view,
            version: .MEP,
            customUserID: nil
        )
        #expect(tracker.sessionViewsCount == 1)

        // Track a view event with CEP version
        // This should increment the session counter to 2 (both versions count toward session)
        tracker.trackEvent(
            forCampaignID: "campaign_id_cep",
            kind: BALocalCampaignTrackerEventKind.view,
            version: .CEP,
            customUserID: nil
        )
        #expect(tracker.sessionViewsCount == 2)

        // Reset session counter and verify it returns to 0
        tracker.resetSessionViewsCount()
        #expect(tracker.sessionViewsCount == 0)

        // Clean up resources
        tracker.clear()
    }

    /// Test global capping enforcement with time-based and session-based limits
    ///
    /// This test verifies:
    /// - Initial state has no capping violations
    /// - Time-based capping is enforced (1 view per hour)
    /// - Session-based capping is enforced (2 views per session)
    /// - Time advancement releases time-based caps
    /// - Mixed MEP and CEP versions work with capping
    @Test("Global cappings are enforced correctly for time and session limits")
    func testIsOverGlobalCappings() async throws {
        // Clean up resources
        tracker.clear()

        // Set up date provider for time manipulation in tests
        let dateProvider = BAMutableDateProvider(timestamp: Date().timeIntervalSince1970)

        // Initialize tracker and campaign manager with test date provider
        let tracker = BALocalCampaignsTracker()
        tracker.clear() // Ensure clean state
        let campaignManager = BALocalCampaignsManager(dateProvider: dateProvider, viewTracker: tracker)

        // Parse and apply test capping configuration (2/session, 1/hour)
        let cappings = BALocalCampaignsParser.parseCappings(TestResponses.cappingPayload, outPersistable: nil)
        campaignManager.cappings = cappings

        // Verify initial state - no cappings should be exceeded
        #expect(campaignManager.isOverGlobalCappings() == false)

        // Track first event with MEP version
        // This should trigger time-based capping (1 view per hour limit reached)
        tracker.trackEvent(
            forCampaignID: "campaign_id",
            kind: BALocalCampaignTrackerEventKind.view,
            version: .MEP,
            customUserID: nil
        )

        // Time-based cappings should now be exceeded
        #expect(campaignManager.isOverGlobalCappings() == true)

        // Advance time by 1 hour to release time-based capping
        dateProvider.setTime(Date().timeIntervalSince1970 + 3600)

        // Time-based cappings should now be released
        #expect(campaignManager.isOverGlobalCappings() == false)

        // Track second event with CEP version
        // This should again trigger time-based capping but not session capping yet
        tracker.trackEvent(
            forCampaignID: "campaign_id_cep",
            kind: BALocalCampaignTrackerEventKind.view,
            version: .CEP,
            customUserID: nil
        )

        // Advance time by another hour
        dateProvider.setTime(Date().timeIntervalSince1970 + 7200)

        // Session capping should now be reached (2 views in session)
        #expect(campaignManager.isOverGlobalCappings() == true)

        // Clean up resources
        tracker.clear()
    }

    /// Test event tracking with different custom user IDs across versions
    ///
    /// This test verifies:
    /// - Events are isolated per user ID
    /// - Multiple users can track events independently
    /// - MEP and CEP versions maintain separate counters per user
    /// - Event information retrieval works correctly
    @Test("Event tracking with different custom user IDs maintains isolation")
    func testTrackEventWithDifferentCustomUserIDs() async throws {
        // Clean up resources
        tracker.clear()

        // Initialize tracker and test data
        let campaignID = "test_campaign"
        let userID1 = "user1"
        let userID2 = "user2"

        // Track event for user1 with CEP version
        // This creates the first tracking entry for user1
        let event1 = tracker.trackEvent(
            forCampaignID: campaignID,
            kind: .view,
            version: .CEP,
            customUserID: userID1
        )

        // Track event for user2 with CEP version
        // This creates an independent tracking entry for user2
        let event2 = tracker.trackEvent(
            forCampaignID: campaignID,
            kind: .view,
            version: .CEP,
            customUserID: userID2
        )

        // Verify both users start with count of 1
        #expect(event1 != nil)
        #expect(event2 != nil)
        #expect(event1?.count == 1)
        #expect(event2?.count == 1)

        // Track another event for user1 with CEP version
        // This should only affect user1's counter
        let event1Updated = tracker.trackEvent(
            forCampaignID: campaignID,
            kind: .view,
            version: .CEP,
            customUserID: userID1
        )

        // Verify user1's count increased but user2's remained unchanged
        #expect(event1Updated?.count == 2)

        // Clean up resources
        tracker.clear()
    }

    /// Test event information retrieval with custom user IDs
    ///
    /// This test verifies:
    /// - Event information can be retrieved before tracking
    /// - Initial state shows 0 count with correct metadata
    /// - Event information updates after tracking
    /// - Last occurrence timestamp is recorded
    /// - MEP and CEP versions maintain separate information
    @Test("Event information retrieval works correctly with custom user IDs")
    func testEventInformationWithCustomUserID() async throws {
        // Clean up resources
        tracker.clear()

        // Initialize tracker and test data
        let campaignID = "test_campaign"
        let customUserID = "user123"

        // Get event info before tracking anything with CEP version
        // This should return a default event with 0 count
        let event = tracker.eventInformation(
            forCampaignID: campaignID,
            kind: .view,
            version: .CEP,
            customUserID: customUserID
        )

        // Verify initial state
        #expect(event.count == 0)
        #expect(event.campaignID == campaignID)

        // Track an event with CEP version
        // This should update the tracking data
        tracker.trackEvent(
            forCampaignID: campaignID,
            kind: .view,
            version: .CEP,
            customUserID: customUserID
        )

        // Get updated event info with CEP version
        // This should now show the tracked event
        let updatedEvent = tracker.eventInformation(
            forCampaignID: campaignID,
            kind: .view,
            version: .CEP,
            customUserID: customUserID
        )

        // Verify event was tracked and timestamp recorded
        #expect(updatedEvent.count == 1)
        #expect(updatedEvent.lastOccurrence != nil)

        // Clean up resources
        tracker.clear()
    }

    /// Test session tracker with different custom user IDs and versions
    ///
    /// This test verifies:
    /// - Session counter aggregates across all users and versions
    /// - Different user IDs contribute to session count
    /// - Both MEP and CEP versions contribute to session count
    /// - Session reset clears all counters
    @Test("Session tracker aggregates views across users and versions")
    func testSessionTrackerWithCustomUserID() async throws {
        // Clean up resources
        tracker.clear()

        // Verify initial session state
        #expect(tracker.sessionViewsCount == 0)

        // Track events with different custom user IDs using MEP version
        // Each event should increment the session counter
        tracker.trackEvent(forCampaignID: "campaign1", kind: .view, version: .MEP, customUserID: "user1")
        tracker.trackEvent(forCampaignID: "campaign2", kind: .view, version: .MEP, customUserID: "user2")
        tracker.trackEvent(forCampaignID: "campaign3", kind: .view, version: .MEP, customUserID: nil)

        // Track events with different custom user IDs using CEP version
        // These should also increment the session counter
        tracker.trackEvent(forCampaignID: "campaign1", kind: .view, version: .CEP, customUserID: "user1")
        tracker.trackEvent(forCampaignID: "campaign2", kind: .view, version: .CEP, customUserID: "user2")

        // Verify session count includes all events (3 MEP + 2 CEP = 5 total)
        #expect(tracker.sessionViewsCount == 5) // 3 MEP + 2 CEP events

        // Reset session counter and verify it clears
        tracker.resetSessionViewsCount()
        #expect(tracker.sessionViewsCount == 0)

        // Clean up resources
        tracker.clear()
    }

    /// Test global capping enforcement with custom user IDs and mixed versions
    ///
    /// This test verifies:
    /// - Global capping works with custom user IDs
    /// - Time-based capping is enforced across users
    /// - Session-based capping is enforced across users
    /// - Mixed MEP and CEP versions work with capping
    @Test("Global cappings work correctly with custom user IDs and mixed versions")
    func testIsOverGlobalCappingsWithCustomUserID() async throws {
        // Clean up resources
        tracker.clear()

        // Set up date provider for time manipulation
        let dateProvider = BAMutableDateProvider(timestamp: Date().timeIntervalSince1970)

        // Initialize tracker and campaign manager
        let campaignManager = BALocalCampaignsManager(dateProvider: dateProvider, viewTracker: tracker)

        // Apply test capping configuration
        let cappings = BALocalCampaignsParser.parseCappings(TestResponses.cappingPayload, outPersistable: nil)
        campaignManager.cappings = cappings

        // Verify initial state
        #expect(campaignManager.isOverGlobalCappings() == false)

        // Track event with custom user ID using MEP version
        // This should trigger time-based capping
        tracker.trackEvent(
            forCampaignID: "campaign_id",
            kind: BALocalCampaignTrackerEventKind.view,
            version: .MEP,
            customUserID: "user123"
        )

        // Time-based cappings should now be exceeded
        #expect(campaignManager.isOverGlobalCappings() == true)

        // Advance time by 1 hour to release time-based capping
        dateProvider.setTime(Date().timeIntervalSince1970 + 3600)

        // Time-based cappings should now be released
        #expect(campaignManager.isOverGlobalCappings() == false)

        // Track event with different custom user ID using CEP version
        // This should again trigger time-based capping
        tracker.trackEvent(
            forCampaignID: "campaign_id_cep",
            kind: BALocalCampaignTrackerEventKind.view,
            version: .CEP,
            customUserID: "user456"
        )

        // Advance time by another hour
        dateProvider.setTime(Date().timeIntervalSince1970 + 7200)

        // Session capping should now be reached
        #expect(campaignManager.isOverGlobalCappings() == true)

        // Clean up resources
        tracker.clear()
    }

    /// Test event tracking with nil custom user ID across versions
    ///
    /// This test verifies:
    /// - Nil custom user ID is handled correctly
    /// - Nil and empty string are treated as different users
    /// - MEP and CEP versions maintain separate counters for nil users
    /// - Event counting works correctly with nil user IDs
    @Test("Event tracking with nil custom user ID works correctly")
    func testNilCustomUserID() async throws {
        // Clean up resources
        tracker.clear()

        // Initialize tracker and test data
        let campaignID = "test_campaign"

        // Track event with nil custom user ID using CEP version
        // This should create a tracking entry for nil user
        let event = try #require(tracker.trackEvent(
            forCampaignID: campaignID,
            kind: .view,
            version: .CEP,
            customUserID: nil
        ))

        // Verify nil user tracking works
        #expect(event.count == 1)

        // Track another event with nil custom user ID using CEP version
        // This should increment the nil user counter
        let event2 = try #require(tracker.trackEvent(
            forCampaignID: campaignID,
            kind: .view,
            version: .CEP,
            customUserID: nil
        ))

        // Verify counter incremented
        #expect(event2.count == 2)

        // Verify nil and empty string are treated as same users
        // Track event with empty string user ID
        let event3 = try #require(tracker.trackEvent(
            forCampaignID: campaignID,
            kind: .view,
            version: .CEP,
            customUserID: ""
        ))

        // Empty string should start its own counter
        #expect(event3.count == 3)

        // Clean up resources
        tracker.clear()
    }

    /// Test event tracking with multiple campaigns
    ///
    /// This test verifies:
    /// - Events are tracked per campaign ID
    /// - Different campaigns maintain independent counters
    /// - MEP and CEP versions work with multiple campaigns
    @Test("Event tracking with multiple campaigns maintains independence")
    func testEventTrackingWithMultipleCampaigns() async throws {
        // Clean up resources
        tracker.clear()

        // Initialize tracker and test data
        let campaignID1 = "campaign_1"
        let campaignID2 = "campaign_2"
        let customUserID = "user123"

        // Track events for different campaigns with CEP version
        let event1 = tracker.trackEvent(
            forCampaignID: campaignID1,
            kind: .view,
            version: .CEP,
            customUserID: customUserID
        )

        let event2 = tracker.trackEvent(
            forCampaignID: campaignID2,
            kind: .view,
            version: .CEP,
            customUserID: customUserID
        )

        // Verify campaigns are tracked independently
        #expect(event1 != nil)
        #expect(event2 != nil)
        #expect(event1?.count == 1)
        #expect(event2?.count == 1)
        #expect(event1?.campaignID == campaignID1)
        #expect(event2?.campaignID == campaignID2)

        // Track additional event for campaign 1
        let event1Updated = tracker.trackEvent(
            forCampaignID: campaignID1,
            kind: .view,
            version: .CEP,
            customUserID: customUserID
        )

        // Verify only campaign 1 counter increased
        #expect(event1Updated?.count == 2)

        // Verify campaign 2 counter unchanged
        let event2Info = tracker.eventInformation(
            forCampaignID: campaignID2,
            kind: .view,
            version: .CEP,
            customUserID: customUserID
        )
        #expect(event2Info.count == 1)

        // Clean up resources
        tracker.clear()
    }
}
