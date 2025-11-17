//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import Testing

@testable import Batch

@Suite(.serialized)
struct LocalCampaignsSQLTrackerTests {
    let datasource = BALocalCampaignsSQLTracker()

    func testnumberOfViewEventsSince() async throws {
        datasource.clear()

        let count = datasource.numberOfViewEvents(since: Date().timeIntervalSince1970 - 60)
        #expect(count?.intValue == 0)

        datasource.trackEvent(
            forCampaignID: "campaign_id",
            kind: .view,
            version: .MEP,
            customUserID: nil
        )

        let timestamp = Date().timeIntervalSince1970
        let countAfterTrack = datasource.numberOfViewEvents(since: timestamp - 1)

        #expect(countAfterTrack?.intValue == 1)

        datasource.trackEvent(
            forCampaignID: "campaign_id_cep",
            kind: .view,
            version: .CEP,
            customUserID: nil
        )

        let countAfterSecondTrack = try #require(datasource.numberOfViewEvents(since: timestamp - 1))
        #expect(countAfterSecondTrack.intValue == 2)

        let countAfterDelay = try #require(datasource.numberOfViewEvents(since: timestamp + 10))
        #expect(countAfterDelay.intValue == 0)

        datasource.clear()
    }

    func testTrackEventWithCustomUserID() async throws {
        datasource.clear()

        let campaignID = "test_campaign"
        let customUserID = "user123"

        let event = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .MEP,
                customUserID: customUserID
            )
        )

        #expect(event.count == 1)
        #expect(event.campaignID == campaignID)
        #expect(event.kind == .view)

        let secondEvent = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .MEP,
                customUserID: customUserID
            )
        )

        #expect(secondEvent.count == 2)

        let cepEvent = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .CEP,
                customUserID: customUserID
            )
        )

        #expect(cepEvent.count == 1)

        datasource.clear()
    }

    func testTrackEventWithDifferentCustomUserIDs() async throws {
        datasource.clear()

        let campaignID = "test_campaign"
        let userID1 = "user1"
        let userID2 = "user2"

        let event1 = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .MEP,
                customUserID: userID1
            )
        )

        let event2 = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .MEP,
                customUserID: userID2
            )
        )

        let event1Updated = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .MEP,
                customUserID: userID1
            )
        )

        #expect(event1.count == 1)
        #expect(event2.count == 2)
        #expect(event1Updated.count == 3)

        let event1CEP = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .CEP,
                customUserID: userID1
            )
        )

        #expect(event1CEP.count == 1)

        let event2CEP = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .CEP,
                customUserID: userID2
            )
        )

        #expect(event2CEP.count == 1)

        let event3CEP = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .CEP,
                customUserID: userID2
            )
        )

        #expect(event3CEP.count == 2)

        datasource.clear()
    }

    func testEventInformationWithCustomUserID() async throws {
        datasource.clear()

        let campaignID = "test_campaign"
        let customUserID = "user123"

        let event = datasource.eventInformation(
            forCampaignID: campaignID,
            kind: .view,
            version: .MEP,
            customUserID: customUserID
        )

        #expect(event.count == 0)
        #expect(event.campaignID == campaignID)

        let updatedEvent = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .MEP,
                customUserID: customUserID
            )
        )

        #expect(updatedEvent.count == 1)
        #expect(updatedEvent.lastOccurrence != nil)

        let eventCEP = datasource.eventInformation(
            forCampaignID: campaignID,
            kind: .view,
            version: .CEP,
            customUserID: customUserID
        )

        #expect(eventCEP.count == 0)

        let updatedEventCEP = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .CEP,
                customUserID: customUserID
            )
        )

        #expect(updatedEventCEP.count == 1)
        #expect(updatedEventCEP.lastOccurrence != nil)

        datasource.clear()
    }

    func testViewEventsWithCustomUserID() async throws {
        datasource.clear()

        let campaignID1 = "campaign1"
        let campaignID2 = "campaign2"
        let userID1 = "user1"
        let userID2 = "user2"

        let timestamp = Date().timeIntervalSince1970

        datasource.trackEvent(
            forCampaignID: campaignID1,
            kind: .view,
            version: .MEP,
            customUserID: userID1
        )

        datasource.trackEvent(
            forCampaignID: campaignID2,
            kind: .view,
            version: .MEP,
            customUserID: userID2
        )

        datasource.trackEvent(
            forCampaignID: campaignID1,
            kind: .view,
            version: .MEP,
            customUserID: userID2
        )

        datasource.trackEvent(
            forCampaignID: campaignID1,
            kind: .view,
            version: .CEP,
            customUserID: userID1
        )

        datasource.trackEvent(
            forCampaignID: campaignID2,
            kind: .view,
            version: .CEP,
            customUserID: userID2
        )

        let count = try #require(datasource.numberOfViewEvents(since: timestamp - 1))
        #expect(count.intValue == 5)

        let events = datasource.events(since: timestamp - 1)
        #expect(events.count == 5)

        datasource.clear()
    }

    func testNilCustomUserID() async throws {
        datasource.clear()

        let campaignID = "test_campaign"

        let base = datasource.eventInformation(
            forCampaignID: campaignID,
            kind: .view,
            version: .MEP,
            customUserID: nil
        )

        #expect(base.count == 0)

        let event = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .MEP,
                customUserID: nil
            )
        )

        #expect(event.count == 1)

        let secondEvent = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .MEP,
                customUserID: nil
            )
        )

        #expect(secondEvent.count == 2)

        let emptyStringEvent = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .MEP,
                customUserID: ""
            )
        )

        #expect(emptyStringEvent.count == 3)

        let eventCEP = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .CEP,
                customUserID: nil
            )
        )

        #expect(eventCEP.count == 1)

        let secondEventCEP = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .CEP,
                customUserID: nil
            )
        )

        #expect(secondEventCEP.count == 2)

        let emptyStringEventCEP = try #require(
            datasource.trackEvent(
                forCampaignID: campaignID,
                kind: .view,
                version: .CEP,
                customUserID: ""
            )
        )

        #expect(emptyStringEventCEP.count == 1)

        datasource.clear()
    }
}
