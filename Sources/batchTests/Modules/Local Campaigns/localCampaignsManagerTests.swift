//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Testing

@testable import Batch

/// Test suite for the `BALocalCampaignsManager` class, covering campaign eligibility, sorting, JIT sync logic, and quiet hours.
@Suite(.serialized)
struct BALocalCampaignsManagerTests {
    /// Tests if the manager correctly sorts eligible campaigns in descending order of priority.
    @Test func eligibleCampaignsSortedByPriority() {
        // GIVEN a list of campaigns with different priorities.
        let dateProvider = BASecureDateProvider()
        let manager = BALocalCampaignsManager(
            dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker()
        )

        let campaigns: [BALocalCampaign] = [
            Self.createFakeCampaignWith(priority: 0, jit: false), // Low priority
            Self.createFakeCampaignWith(priority: 50, jit: false), // High priority
            Self.createFakeCampaignWith(priority: 10, jit: false), // Medium priority
        ]
        manager.load(campaigns, fromCache: false)

        // WHEN we get the eligible campaigns sorted by priority.
        let sortedCampaigns: [BALocalCampaign] = manager.eligibleCampaignsSorted(byPriority: BANewSessionSignal())

        // THEN the campaigns should be ordered from highest priority to lowest.
        #expect(sortedCampaigns[0] == campaigns[1]) // Priority 50
        #expect(sortedCampaigns[1] == campaigns[2]) // Priority 10
        #expect(sortedCampaigns[2] == campaigns[0]) // Priority 0
    }

    /// Tests that the manager can correctly filter and return only the campaigns that require a Just-In-Time (JIT) sync.
    @Test func firstEligibleCampaignsRequiringSync() {
        // GIVEN a list of campaigns where some require JIT sync and others don't.
        let dateProvider = BASecureDateProvider()
        let manager = BALocalCampaignsManager(
            dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker()
        )

        let campaigns: [BALocalCampaign] = [
            Self.createFakeCampaignWith(priority: 0, jit: true),
            Self.createFakeCampaignWith(priority: 0, jit: true),
            Self.createFakeCampaignWith(priority: 0, jit: false),
        ]

        // WHEN we get the campaigns that require sync.
        let eligibleCampaignRequiringSync = manager.firstEligibleCampaignsRequiringSync(campaigns)

        // THEN the result should only contain the two campaigns that require JIT sync.
        #expect(eligibleCampaignRequiringSync.count == 2)
        #expect(campaigns[0] == eligibleCampaignRequiringSync[0])
        #expect(campaigns[1] == eligibleCampaignRequiringSync[1])
    }

    /// Tests that the manager can correctly find the first eligible campaign that does NOT require a JIT sync.
    @Test func firstCampaignNotRequiringJITSync() {
        // GIVEN a list of campaigns where some require JIT sync and one doesn't.
        let dateProvider = BASecureDateProvider()
        let manager = BALocalCampaignsManager(
            dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker()
        )

        let campaigns: [BALocalCampaign] = [
            Self.createFakeCampaignWith(priority: 0, jit: true),
            Self.createFakeCampaignWith(priority: 0, jit: true),
            Self.createFakeCampaignWith(priority: 0, jit: false),
        ]

        // WHEN we ask for the first campaign not requiring sync.
        let eligibleCampaign = manager.firstCampaignNotRequiringJITSync(campaigns)

        // THEN the result should be the campaign that has `requiresJustInTimeSync` set to false.
        #expect(campaigns[2] == eligibleCampaign)
    }

    /// Tests the availability status of the JIT service based on the cooldown timestamp.
    @Test func isJITServiceAvailable() {
        // GIVEN a default manager state.
        let dateProvider = BASecureDateProvider()
        let manager = BALocalCampaignsManager(
            dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker()
        )

        // THEN the JIT service should be available.
        #expect(manager.isJITServiceAvailable())

        // WHEN the next available JIT timestamp is set to 30 seconds in the future.
        manager.setValue(dateProvider.currentDate().timeIntervalSince1970 + 30, forKey: "_nextAvailableJITTimestamp")

        // THEN the JIT service should be unavailable.
        #expect(manager.isJITServiceAvailable() == false)
    }

    /// Tests the logic for determining a synced JIT campaign's state (Eligible, Not Eligible, Requires Sync).
    @Test func syncedJITCampaignState() {
        let dateProvider = BAMutableDateProvider(timestamp: 0)
        let manager = BALocalCampaignsManager(dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker())

        // 1. A non-JIT campaign should always be considered eligible.
        let campaign = Self.createFakeCampaignWith(priority: 0, jit: false)
        #expect(BATSyncedJITCampaignState.eligible == manager.syncedJITCampaignState(campaign))

        // 2. A JIT campaign that has not been synced yet should require a sync.
        campaign.requiresJustInTimeSync = true
        #expect(BATSyncedJITCampaignState.requiresSync == manager.syncedJITCampaignState(campaign))

        // 3. Simulate a cached JIT result where the campaign was deemed ineligible.
        let syncedJITResult = BATSyncedJITResult(timestamp: 0)
        syncedJITResult.eligible = false
        let syncedCampaigns: NSMutableDictionary? = [campaign.campaignID: syncedJITResult]
        manager.setValue(syncedCampaigns, forKey: "_syncedJITCampaigns")
        #expect(BATSyncedJITCampaignState.notEligible == manager.syncedJITCampaignState(campaign))

        // 4. Simulate a cached JIT result where the campaign was deemed eligible.
        syncedJITResult.eligible = true
        #expect(BATSyncedJITCampaignState.eligible == manager.syncedJITCampaignState(campaign))

        // 5. Advance time past the cache TTL. The campaign should now require a new sync.
        dateProvider.setTime(30)
        #expect(BATSyncedJITCampaignState.requiresSync == manager.syncedJITCampaignState(campaign))
    }

    @Suite("Quiet Hours")
    struct QuietHours {
        static let friday = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2025, month: 6, day: 27, hour: 15, minute: 2, second: 0))!

        static let dateProvider = BAMutableDateProvider(timestamp: friday.timeIntervalSince1970)

        static let manager = BALocalCampaignsManager(
            dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker()
        )

        struct Outside {
            /// Tests that a campaign is correctly identified as being outside quiet hours when the current day is not a designated quiet day.
            @Test func becauseOfDay() {
                // GIVEN the current date is a Friday.
                // WHEN the quiet hours are set for Sunday only.
                let quietHours = BALocalCampaignQuietHours()
                quietHours.quietDaysOfWeek = [NSNumber(value: BALocalCampaignDayOfWeek.sunday.rawValue)]

                let campaign1 = createFakeCampaignWith(priority: 0, jit: false, quietHours: quietHours)

                // THEN the campaign should NOT be in quiet hours.
                #expect(manager.isCampaignDate(inQuietHours: campaign1) == false)
            }

            /// Tests that a campaign is correctly identified as being outside quiet hours when the current time is outside the designated hour range on a quiet day.
            @Test func becauseOfHour() {
                // GIVEN the current date is Friday at 15:02.
                // WHEN the quiet hours are set for Sunday, and only between 8 AM and 9 AM.
                let quietHours = BALocalCampaignQuietHours()
                quietHours.startHour = 8
                quietHours.startMin = 0
                quietHours.endHour = 9
                quietHours.endMin = 0

                let campaign1 = createFakeCampaignWith(priority: 0, jit: false, quietHours: quietHours)

                // THEN the campaign should NOT be in quiet hours.
                #expect(manager.isCampaignDate(inQuietHours: campaign1) == false)
            }

            /// Tests that a campaign is correctly identified as being outside quiet hours when the current time is outside the designated minute range.
            @Test func becauseOfMinutes() {
                // GIVEN the current date is Friday at 15:02.
                // WHEN the quiet hours are only between 15:15 PM and 9 AM.
                let quietHours = BALocalCampaignQuietHours()
                quietHours.startHour = 15
                quietHours.startMin = 15
                quietHours.endHour = 9
                quietHours.endMin = 0

                let campaign1 = createFakeCampaignWith(priority: 0, jit: false, quietHours: quietHours)

                // THEN the campaign should NOT be in quiet hours.
                #expect(manager.isCampaignDate(inQuietHours: campaign1) == false)
            }

            /// Tests that a campaign is correctly identified as being outside quiet hours when the current time is outside the designated range.
            @Test func range() {
                // GIVEN the current date is Friday at 15:02
                // WHEN the quiet hours are only between 10 AM and 15:02 PM.
                let quietHours = BALocalCampaignQuietHours()
                quietHours.startHour = 10
                quietHours.startMin = 0
                quietHours.endHour = 15
                quietHours.endMin = 2

                let campaign1 = createFakeCampaignWith(priority: 0, jit: false, quietHours: quietHours)

                // THEN the campaign should NOT be in quiet hours.
                #expect(manager.isCampaignDate(inQuietHours: campaign1) == false)
            }

            @Test func overnight() {
                // GIVEN the current date is Friday at 15:02.

                // Test Case 2: Overnight quiet hours.
                // WHEN quiet hours are from 18:00 to 13:00. The current time (Friday 15:02) is NOT in this range.
                // With a start of 18:00 and an end of 13:00, the current time of 15:02 on Friday should be FALSE.
                let quietHoursOvernight = BALocalCampaignQuietHours()
                quietHoursOvernight.startHour = 18
                quietHoursOvernight.startMin = 0
                quietHoursOvernight.endHour = 13 // Ends next day
                quietHoursOvernight.endMin = 0
                let campaign2 = createFakeCampaignWith(priority: 0, jit: false, quietHours: quietHoursOvernight)
                #expect(manager.isCampaignDate(inQuietHours: campaign2) == false)
            }
        }

        struct Inside {
            /// Tests that a campaign is correctly identified as being inside quiet hours for both same-day and overnight intervals.
            @Test func becauseOfHours() {
                // GIVEN the current date is Friday at 15:02.

                // Test Case 1: Same-day quiet hours.
                // WHEN quiet hours are from 12:00 to 16:00.
                let quietHours = BALocalCampaignQuietHours()
                quietHours.startHour = 12
                quietHours.startMin = 0
                quietHours.endHour = 16
                quietHours.endMin = 0
                let campaign1 = createFakeCampaignWith(priority: 0, jit: false, quietHours: quietHours)
                // THEN the campaign should be in quiet hours.
                #expect(manager.isCampaignDate(inQuietHours: campaign1) == true)
            }

            @Test func notBecauseOfDayButBecauseOfHours() {
                // GIVEN the current date is Friday at 15:02.

                // Test Case 1: Same-day quiet hours.
                // WHEN quiet hours are from 12:00 to 16:00.
                let quietHours = BALocalCampaignQuietHours()
                quietHours.startHour = 12
                quietHours.startMin = 0
                quietHours.endHour = 16
                quietHours.endMin = 0
                quietHours.quietDaysOfWeek = [NSNumber(value: BALocalCampaignDayOfWeek.sunday.rawValue)]

                let campaign1 = createFakeCampaignWith(priority: 0, jit: false, quietHours: quietHours)
                // THEN the campaign should be in quiet hours.
                #expect(manager.isCampaignDate(inQuietHours: campaign1) == true)
            }

            @Test func becauseOfDay() {
                // GIVEN the current date is Friday at 15:02.

                // Test Case 1: Same-day quiet hours.
                // WHEN quiet hours are on Friday.
                let quietHours = BALocalCampaignQuietHours()
                quietHours.quietDaysOfWeek = [NSNumber(value: BALocalCampaignDayOfWeek.friday.rawValue)]
                let campaign1 = createFakeCampaignWith(priority: 0, jit: false, quietHours: quietHours)
                // THEN the campaign should be in quiet hours.
                #expect(manager.isCampaignDate(inQuietHours: campaign1) == true)
            }

            /// Tests that a campaign is correctly identified as being inside range.
            @Test func range() {
                // GIVEN the current date is Friday at 15:02

                // Test Case 1: Same-day quiet hours.
                // WHEN quiet hours are from 15:02 to 16:00.
                let quietHours = BALocalCampaignQuietHours()
                quietHours.startHour = 15
                quietHours.startMin = 2
                quietHours.endHour = 16
                quietHours.endMin = 0
                let campaign1 = createFakeCampaignWith(priority: 0, jit: false, quietHours: quietHours)
                // THEN the campaign should be in quiet hours.
                #expect(manager.isCampaignDate(inQuietHours: campaign1) == true)
            }

            /// Tests that a campaign is correctly identified as being inside quiet hours for overnight intervals.
            @Test func overnight() {
                // GIVEN the current date is Friday at 07:15.
                let friday = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2025, month: 6, day: 27, hour: 7, minute: 15, second: 0))!
                let dateProvider = BAMutableDateProvider(timestamp: friday.timeIntervalSince1970)

                let manager = BALocalCampaignsManager(
                    dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker()
                )

                // Test Case 1: Same-day quiet hours.
                // WHEN quiet hours are from 23:00 to 8:00.
                let quietHours = BALocalCampaignQuietHours()
                quietHours.startHour = 23
                quietHours.startMin = 0
                quietHours.endHour = 8
                quietHours.endMin = 0
                let campaign1 = createFakeCampaignWith(priority: 0, jit: false, quietHours: quietHours)
                // THEN the campaign should be in quiet hours.
                #expect(manager.isCampaignDate(inQuietHours: campaign1) == true)
            }
        }

        struct Without {
            @Test func without() {
                // GIVEN the campaign without quiet hours
                // WHEN quiet hours are nil.
                let campaign1 = createFakeCampaignWith(priority: 0, jit: false, quietHours: nil)
                // THEN the campaign should NOT be in quiet hours.
                #expect(manager.isCampaignDate(inQuietHours: campaign1) == false)
            }
        }
    }

    /// Tests that loadCampaigns properly calls updateSyncedJITCampaigns for campaign eligibility tracking.
    @Test func loadCampaignsUpdatesSyncedJITCampaigns() {
        let dateProvider = BAMutableDateProvider(timestamp: 0)
        let manager = BALocalCampaignsManager(dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker())

        // GIVEN campaigns with JIT sync requirements
        let jitCampaign1 = Self.createFakeCampaignWith(campaignID: "jit_campaign_1", priority: 10, jit: true)
        let jitCampaign2 = Self.createFakeCampaignWith(campaignID: "jit_campaign_2", priority: 20, jit: true)
        let nonJitCampaign = Self.createFakeCampaignWith(campaignID: "non_jit_campaign", priority: 5, jit: false)

        let campaigns = [jitCampaign1, jitCampaign2, nonJitCampaign]

        // WHEN we load the campaigns
        manager.load(campaigns, fromCache: false)

        // THEN the synced JIT campaigns should be updated with eligible campaign IDs
        let syncedJITCampaigns = manager.value(forKey: "_syncedJITCampaigns") as? NSMutableDictionary

        #expect(syncedJITCampaigns != nil)
        #expect(syncedJITCampaigns?.count == 2) // All campaigns should have entries

        // Verify JIT campaigns have appropriate sync results
        let syncResult1 = syncedJITCampaigns?["jit_campaign_1"] as? BATSyncedJITResult
        let syncResult2 = syncedJITCampaigns?["jit_campaign_2"] as? BATSyncedJITResult
        let syncResult3 = syncedJITCampaigns?["non_jit_campaign"] as? BATSyncedJITResult

        #expect(syncResult1?.eligible == true)
        #expect(syncResult2?.eligible == true)
        #expect(syncResult3 == nil)
        #expect(syncResult1?.timestamp == 0)
        #expect(syncResult2?.timestamp == 0)
    }

    /// Tests that loadCampaigns handles empty campaign lists gracefully.
    @Test func loadCampaignsHandlesEmptyInput() {
        let dateProvider = BAMutableDateProvider(timestamp: 400)
        let manager = BALocalCampaignsManager(dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker())

        // WHEN we load empty campaigns array
        manager.load([], fromCache: false)

        // THEN campaign list should be empty
        #expect(manager.campaignList.count == 0)

        // AND no synced JIT campaigns should be set or it should be empty
        let syncedJITCampaigns = manager.value(forKey: "_syncedJITCampaigns") as? NSMutableDictionary
        #expect(syncedJITCampaigns?.count == 0 || syncedJITCampaigns == nil)
    }

    /// Tests that campaigns are properly tracked when loaded multiple times.
    @Test func loadCampaignsHandlesMultipleLoads() {
        let dateProvider = BAMutableDateProvider(timestamp: 100)
        let manager = BALocalCampaignsManager(dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker())

        // GIVEN initial campaigns
        let campaign1 = Self.createFakeCampaignWith(campaignID: "campaign_1", priority: 10, jit: true)
        let campaign2 = Self.createFakeCampaignWith(campaignID: "campaign_2", priority: 20, jit: true)
        manager.load([campaign1, campaign2], fromCache: false)

        // Verify initial state
        var syncedJITCampaigns = manager.value(forKey: "_syncedJITCampaigns") as? NSMutableDictionary
        #expect(syncedJITCampaigns?.count == 2)

        // WHEN we load different campaigns
        let campaign3 = Self.createFakeCampaignWith(campaignID: "campaign_3", priority: 30, jit: true)
        dateProvider.setTime(200)
        manager.load([campaign3], fromCache: false)

        // THEN the new campaign should be tracked with updated timestamp
        // Note: The synced JIT campaigns dictionary may accumulate entries across loads
        syncedJITCampaigns = manager.value(forKey: "_syncedJITCampaigns") as? NSMutableDictionary
        #expect(syncedJITCampaigns != nil)

        let syncResult3 = syncedJITCampaigns?["campaign_3"] as? BATSyncedJITResult
        #expect(syncResult3?.eligible == true)
        #expect(syncResult3?.timestamp == 200)

        // THEN the campaign list should only contain the new campaign
        #expect(manager.campaignList.count == 1)
        #expect(manager.campaignList[0].campaignID == "campaign_3")
    }

    /// Tests that mixed JIT and non-JIT campaigns are handled correctly during loading.
    @Test func loadCampaignsHandlesMixedJITTypes() {
        let dateProvider = BAMutableDateProvider(timestamp: 300)
        let manager = BALocalCampaignsManager(dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker())

        // GIVEN mixed campaign types
        let jitCampaign = Self.createFakeCampaignWith(campaignID: "jit_campaign", priority: 10, jit: true)
        let nonJitCampaign1 = Self.createFakeCampaignWith(campaignID: "non_jit_1", priority: 20, jit: false)
        let nonJitCampaign2 = Self.createFakeCampaignWith(campaignID: "non_jit_2", priority: 30, jit: false)

        let campaigns = [jitCampaign, nonJitCampaign1, nonJitCampaign2]

        // WHEN we load the campaigns
        manager.load(campaigns, fromCache: false)

        // THEN all campaigns should be tracked in synced JIT campaigns
        let syncedJITCampaigns = manager.value(forKey: "_syncedJITCampaigns") as? NSMutableDictionary
        #expect(syncedJITCampaigns?.count == 1)

        // Verify each campaign has correct sync result
        let jitResult = syncedJITCampaigns?["jit_campaign"] as? BATSyncedJITResult
        let nonJitResult1 = syncedJITCampaigns?["non_jit_1"] as? BATSyncedJITResult
        let nonJitResult2 = syncedJITCampaigns?["non_jit_2"] as? BATSyncedJITResult

        #expect(jitResult?.eligible == true)
        #expect(nonJitResult1 == nil)
        #expect(nonJitResult2 == nil)
        #expect(jitResult?.timestamp == 300)
    }

    /// Tests that campaign eligibility state is properly maintained across loads.
    @Test func loadCampaignsMaintainsEligibilityState() {
        let dateProvider = BAMutableDateProvider(timestamp: 500)
        let manager = BALocalCampaignsManager(dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker())

        // GIVEN campaigns loaded initially
        let campaign1 = Self.createFakeCampaignWith(campaignID: "persistent_campaign", priority: 10, jit: true)
        let campaign2 = Self.createFakeCampaignWith(campaignID: "temporary_campaign", priority: 20, jit: true)
        manager.load([campaign1, campaign2], fromCache: false)

        // Verify initial state
        var syncedJITCampaigns = manager.value(forKey: "_syncedJITCampaigns") as? NSMutableDictionary
        #expect(syncedJITCampaigns?.count == 2)

        // WHEN we reload with only one campaign
        dateProvider.setTime(600)
        manager.load([campaign1], fromCache: false) // Only campaign1 persists

        // THEN the persistent campaign should remain with updated timestamp
        syncedJITCampaigns = manager.value(forKey: "_syncedJITCampaigns") as? NSMutableDictionary
        #expect(syncedJITCampaigns != nil)

        let persistentResult = syncedJITCampaigns?["persistent_campaign"] as? BATSyncedJITResult
        #expect(persistentResult?.eligible == true)
        #expect(persistentResult?.timestamp == 600)

        // THEN the campaign list should only contain the persistent campaign
        #expect(manager.campaignList.count == 1)
        #expect(manager.campaignList[0].campaignID == "persistent_campaign")

        // Note: The synced JIT campaigns dictionary may retain entries from previous loads
        // This is expected behavior as it tracks sync history
    }

    /// Helper method to create a `BALocalCampaign` instance for tests.
    /// - Parameters:
    ///   - campaignID: The campaign's unique identifier.
    ///   - priority: The campaign's priority level.
    ///   - jit: A boolean indicating if the campaign requires Just-In-Time sync.
    ///   - quietHours: An optional `BALocalCampaignQuietHours` object.
    ///   - delay: The display delay in seconds.
    /// - Returns: A configured `BALocalCampaign` object.
    private static func createFakeCampaignWith(campaignID: String = "campaign_id", priority: Int, jit: Bool, quietHours: BALocalCampaignQuietHours? = nil, delay: Int = 0) -> BALocalCampaign {
        let campaign = BALocalCampaign()
        campaign.campaignID = campaignID
        campaign.priority = priority
        campaign.requiresJustInTimeSync = jit
        campaign.triggers = [BANextSessionTrigger()]
        campaign.quietHours = quietHours
        campaign.displayDelaySec = delay
        return campaign
    }
}
