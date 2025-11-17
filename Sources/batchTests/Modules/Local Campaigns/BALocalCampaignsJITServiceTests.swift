//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation
import InstantMock
import Testing

@testable import Batch

/// Test suite for the `BALocalCampaignsJITService` class, covering request serialization and response deserialization.
@Suite(.serialized)
struct BALocalCampaignsJITServiceTests {
    init() {
        _ = BACoreCenter.instance().configuration.setDevelopperKey("DEV_KEY")
    }

    /// Test serialization of request body dictionary for CEP campaigns
    @Test func requestBodySerializationCEP() throws {
        let mockCampaign = Self.createMockCampaign(id: "campaign_1")
        let viewTracker = BALocalCampaignsTracker()
        let campaigns = [mockCampaign]

        // Setup mock expectations
        let expectedEvent = BALocalCampaignCountedEvent()
        expectedEvent.count = 5
        expectedEvent.lastOccurrence = Date()

        let service = try #require(
            BALocalCampaignsJITService(
                localCampaigns: campaigns,
                viewTracker: viewTracker,
                version: .CEP,
                success: { _ in },
                error: { _, _ in }
            )
        )

        let requestBody = service.requestBodyDictionary()

        #expect(requestBody["ids"] != nil)
        #expect(requestBody["campaigns"] != nil)
        #expect(requestBody["views"] != nil)
        #expect(requestBody["attributes"] == nil)  // CEP should not include attributes

        let campaignIds = try #require(requestBody["campaigns"] as? [String])
        #expect(campaignIds.count == 1)
        #expect(campaignIds.first == "campaign_1")
    }

    /// Test serialization of request body dictionary for MEP campaigns
    @Test func requestBodySerializationMEP() throws {
        let mockCampaign = Self.createMockCampaign(id: "campaign_2")
        let viewTracker = BALocalCampaignsTracker()
        let campaigns = [mockCampaign]

        let service = try #require(
            BALocalCampaignsJITService(
                localCampaigns: campaigns,
                viewTracker: viewTracker,
                version: .MEP,
                success: { _ in },
                error: { _, _ in }
            )
        )

        let requestBody = service.requestBodyDictionary()

        #expect(requestBody["ids"] != nil)
        #expect(requestBody["campaigns"] != nil)
        #expect(requestBody["views"] != nil)
        #expect(requestBody["attributes"] != nil)  // MEP should include attributes

        let campaignIds = try #require(requestBody["campaigns"] as? [String])
        #expect(campaignIds.count == 1)
        #expect(campaignIds.first == "campaign_2")
    }

    /// Test serialization with multiple campaigns
    @Test func requestBodySerializationMultipleCampaigns() throws {
        let mockCampaign1 = Self.createMockCampaign(id: "campaign_1")
        let mockCampaign2 = Self.createMockCampaign(id: "campaign_2")
        let viewTracker = BALocalCampaignsTracker()
        let campaigns = [mockCampaign1, mockCampaign2]

        let service = try #require(
            BALocalCampaignsJITService(
                localCampaigns: campaigns,
                viewTracker: viewTracker,
                version: .CEP,
                success: { _ in },
                error: { _, _ in }
            )
        )

        let requestBody = service.requestBodyDictionary()

        let campaignIds = try #require(requestBody["campaigns"] as? [String])
        #expect(campaignIds.count == 2)
        #expect(campaignIds.contains("campaign_1") == true)
        #expect(campaignIds.contains("campaign_2") == true)

        let views = try #require(requestBody["views"] as? [String: [String: Any]])
        #expect(views["campaign_1"] != nil)
        #expect(views["campaign_2"] != nil)
    }

    /// Test serialization with empty campaigns array
    @Test func requestBodySerializationEmptyCampaigns() {
        let viewTracker = BALocalCampaignsTracker()
        let campaigns: [BALocalCampaign] = []

        let service = BALocalCampaignsJITService(
            localCampaigns: campaigns,
            viewTracker: viewTracker,
            version: .MEP,
            success: { _ in },
            error: { _, _ in }
        )

        let requestBody = service?.requestBodyDictionary()

        #expect(requestBody != nil)
        #expect(requestBody?.count == 0)
    }

    /// Test deserialization of valid JSON response
    @Test func responseDeserialization() async throws {
        let viewTracker = BALocalCampaignsTracker()
        let campaigns = [Self.createMockCampaign(id: "campaign_1")]

        try await confirmation("Success handler called with correct campaigns") { confirm in
            let service = try #require(
                BALocalCampaignsJITService(
                    localCampaigns: campaigns,
                    viewTracker: viewTracker,
                    version: .CEP,
                    success: { eligibleCampaigns in
                        #expect(eligibleCampaigns.count == 2)
                        confirm()
                    },
                    error: { _, _ in
                        Issue.record("Error handler should not be called")
                        confirm()
                    }
                )
            )

            let validResponseJSON = """
                {
                    "eligibleCampaigns": ["campaign_1", "campaign_2"]
                }
                """

            let responseData = validResponseJSON.data(using: .utf8)!
            service.connectionDidFinishLoading(with: responseData)
        }
    }

    /// Test deserialization of invalid JSON response
    @Test func responseDeserializationInvalidJSON() async {
        let viewTracker = BALocalCampaignsTracker()
        let campaigns = [Self.createMockCampaign(id: "campaign_1")]

        await confirmation("Error handler called for invalid JSON") { confirm in
            let service = BALocalCampaignsJITService(
                localCampaigns: campaigns,
                viewTracker: viewTracker,
                version: .CEP,
                success: { _ in
                    Issue.record("Success handler should not be called")
                    confirm()
                },
                error: { _, _ in
                    confirm()
                }
            )

            let invalidJSON = "{ invalid json }"
            let responseData = invalidJSON.data(using: .utf8)!
            service?.connectionDidFinishLoading(with: responseData)
        }
    }

    /// Test deserialization with missing eligibleCampaigns field
    @Test func responseDeserializationMissingField() async {
        let viewTracker = BALocalCampaignsTracker()
        let campaigns = [Self.createMockCampaign(id: "campaign_1")]

        await confirmation("Error handler called for missing field") { confirm in
            let service = BALocalCampaignsJITService(
                localCampaigns: campaigns,
                viewTracker: viewTracker,
                version: .CEP,
                success: { _ in
                    Issue.record("Success handler should not be called")
                    confirm()
                },
                error: { _, _ in
                    confirm()
                }
            )

            let responseWithoutEligibleCampaigns = """
                {
                    "otherField": "value"
                }
                """

            let responseData = responseWithoutEligibleCampaigns.data(using: .utf8)!
            service?.connectionDidFinishLoading(with: responseData)
        }
    }

    /// Test deserialization with empty eligibleCampaigns array
    @Test func responseDeserializationEmptyArray() async {
        let viewTracker = BALocalCampaignsTracker()
        let campaigns = [Self.createMockCampaign(id: "campaign_1")]

        await confirmation("Success handler called with empty array") { confirm in
            let service = BALocalCampaignsJITService(
                localCampaigns: campaigns,
                viewTracker: viewTracker,
                version: .CEP,
                success: { eligibleCampaigns in
                    #expect(eligibleCampaigns.count == 0)
                    confirm()
                },
                error: { _, _ in
                    Issue.record("Error handler should not be called")
                    confirm()
                }
            )

            let emptyResponseJSON = """
                {
                    "eligibleCampaigns": []
                }
                """

            let responseData = emptyResponseJSON.data(using: .utf8)!
            service?.connectionDidFinishLoading(with: responseData)
        }
    }

    /// Test deserialization with null data
    @Test func responseDeserializationNullData() {
        let viewTracker = BALocalCampaignsTracker()
        let campaigns = [Self.createMockCampaign(id: "campaign_1")]

        var successCalled = false
        var errorCalled = false

        let service = BALocalCampaignsJITService(
            localCampaigns: campaigns,
            viewTracker: viewTracker,
            version: .CEP,
            success: { _ in
                successCalled = true
            },
            error: { _, _ in
                errorCalled = true
            }
        )

        service?.connectionDidFinishLoading(with: Data())

        #expect(successCalled == false)
        #expect(errorCalled)
    }

    /// Test connection failure handling
    @Test func connectionFailure() async {
        let viewTracker = BALocalCampaignsTracker()
        let campaigns = [Self.createMockCampaign(id: "campaign_1")]

        await confirmation("Error handler called on connection failure") { confirm in
            let service = BALocalCampaignsJITService(
                localCampaigns: campaigns,
                viewTracker: viewTracker,
                version: .CEP,
                success: { _ in
                    Issue.record("Success handler should not be called")
                    confirm()
                },
                error: { error, retryAfter in
                    #expect((error as NSError).code == 500)
                    #expect(retryAfter?.intValue == 60)
                    confirm()
                }
            )

            let networkError = NSError(domain: "TestError", code: 500, userInfo: nil)
            service?.connectionFailedWithError(networkError)
        }
    }

    // MARK: - Helper Methods

    private static func createMockCampaign(id: String) -> BALocalCampaign {
        let campaign = BALocalCampaign()
        campaign.campaignID = id
        campaign.priority = 10
        campaign.requiresJustInTimeSync = true
        return campaign
    }
}
