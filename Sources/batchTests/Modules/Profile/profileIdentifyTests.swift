//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import Testing

/// Test suite for profile identification functionality, covering identity changes and JIT campaign cache management.
@Suite(.serialized)
struct ProfileIdentifyTests {
    /// Tests that a valid custom ID triggers an identify event.
    @Test func validIdentification() throws {
        let expectedCustomID = "identifier12345678"

        let eventTracker = MockEventTracker()
        _ = eventTracker.registerOverlay()
        // Reinstanciate it as the shared instance did not get our event tracker mock
        let profileModule = BAProfileCenter()

        profileModule.identify(expectedCustomID)

        #expect(eventTracker.findEvent(name: .profileIdentify, parameters: [
            "identifiers": [
                "custom_id": expectedCustomID,
                "install_id": BatchUser.installationID!,
            ],
        ]) != nil)

        // Logout
        profileModule.identify(nil)

        #expect(eventTracker.findEvent(name: .profileIdentify, parameters: [
            "identifiers": [
                "custom_id": NSNull(),
                "install_id": BatchUser.installationID!,
            ],
        ]) != nil)
    }

    /// Tests that an invalid custom ID doesn't trigger an identify event.
    @Test func invalidIdentification() throws {
        let invalidCustomIDs: [String] = [
            String(repeating: "foo", count: 1000),
            "",
            "foo\nbar",
        ]

        let eventTracker = MockEventTracker()
        _ = eventTracker.registerOverlay()
        let profileModule = BAProfileCenter()

        for customID in invalidCustomIDs {
            print("Testing identify: '\(customID)'")
            profileModule.identify(customID)

            #expect(eventTracker.findEvent(name: .profileIdentify, parameters: [
                "identifiers": [
                    "custom_id": customID,
                    "install_id": BatchUser.installationID!,
                ],
            ]) == nil)
        }
    }

    /// Tests that setting a custom ID calls the compatibility code.
    @Test func compatibility() throws {
        let expectedCustomID = "identifier12345678"

        let eventTracker = MockEventTracker()
        _ = eventTracker.registerOverlay()
        let profileModule = BAProfileCenter()

        let installDataEditor = BAInstallDataEditorMock()
        _ = BAInjection.overlayClass(BAInstallDataEditor.self, returnedInstance: installDataEditor)

        profileModule.identify(expectedCustomID)

        #expect(installDataEditor.identifierToSet == expectedCustomID)
        #expect(installDataEditor.saveCalled == true)

        // Logout
        installDataEditor.reset()
        profileModule.identify(nil)

        #expect(installDataEditor.setIdentifierCalled == true)
        #expect(installDataEditor.identifierToSet == nil)
        #expect(installDataEditor.saveCalled == true)

        // Invalid
        installDataEditor.reset()
        let invalidCustomID = String(repeating: "foo", count: 1000)
        profileModule.identify(invalidCustomID)
        #expect(installDataEditor.setIdentifierCalled == false)
        // "save" can be called or not on an invalid custom id, we don't care
    }

    /// Tests that JIT campaign cache is reset when user identity changes.
    @Test func jitCacheResetOnIdentityChange() throws {
        // GIVEN an existing custom ID
        let originalCustomID = "original_identifier"
        let newCustomID = "new_identifier"

        let eventTracker = MockEventTracker()
        _ = eventTracker.registerOverlay()
        let profileModule = BAProfileCenter()

        // Mock BALocalCampaignsManager to track resetJITCampaingsCaches calls
        let mockCampaignsManager = MockBALocalCampaignsManager()
        _ = BAInjection.overlayClass(BALocalCampaignsManager.self, returnedInstance: mockCampaignsManager)

        // Set initial identifier
        profileModule.identify(originalCustomID)

        // Verify initial state - reset should be called for first identify
        #expect(mockCampaignsManager.resetJITCampaignsCachesCalled == true)

        // Reset mock state
        mockCampaignsManager.resetJITCampaignsCachesCalled = false

        // WHEN we change the user identity to a different custom ID
        profileModule.identify(newCustomID)

        // THEN the JIT campaigns cache should be reset
        #expect(mockCampaignsManager.resetJITCampaignsCachesCalled == true)

        // Reset mock state
        mockCampaignsManager.resetJITCampaignsCachesCalled = false

        // WHEN we identify with the same custom ID again
        profileModule.identify(newCustomID)

        // THEN the JIT campaigns cache should NOT be reset
        #expect(mockCampaignsManager.resetJITCampaignsCachesCalled == false)
    }

    /// Tests that JIT cache is reset when logging out (setting nil custom ID).
    @Test func jitCacheResetOnLogout() throws {
        // GIVEN a user with a custom ID
        let customID = "user_identifier"

        let eventTracker = MockEventTracker()
        _ = eventTracker.registerOverlay()
        let profileModule = BAProfileCenter()

        // Mock BALocalCampaignsManager to track resetJITCampaingsCaches calls
        let mockCampaignsManager = MockBALocalCampaignsManager()
        _ = BAInjection.overlayClass(BALocalCampaignsManager.self, returnedInstance: mockCampaignsManager)

        // Set identifier
        profileModule.identify(customID)
        #expect(mockCampaignsManager.resetJITCampaignsCachesCalled == true)

        // Reset mock state
        mockCampaignsManager.resetJITCampaignsCachesCalled = false

        // WHEN we log out by setting custom ID to nil
        profileModule.identify(nil)

        // THEN the JIT campaigns cache should be reset
        #expect(mockCampaignsManager.resetJITCampaignsCachesCalled == true)
    }

    /// Tests that JIT cache is NOT reset when identifying with invalid custom ID.
    @Test func jitCacheNotResetOnInvalidIdentify() throws {
        // GIVEN a user with a valid custom ID
        let validCustomID = "valid_identifier"
        let invalidCustomID = String(repeating: "invalid", count: 1000)

        let eventTracker = MockEventTracker()
        _ = eventTracker.registerOverlay()
        let profileModule = BAProfileCenter()

        // Mock BALocalCampaignsManager to track resetJITCampaingsCaches calls
        let mockCampaignsManager = MockBALocalCampaignsManager()
        _ = BAInjection.overlayClass(BALocalCampaignsManager.self, returnedInstance: mockCampaignsManager)

        // Set valid identifier
        profileModule.identify(validCustomID)
        #expect(mockCampaignsManager.resetJITCampaignsCachesCalled == true)

        // Reset mock state
        mockCampaignsManager.resetJITCampaignsCachesCalled = false

        // WHEN we try to identify with an invalid custom ID
        profileModule.identify(invalidCustomID)

        // THEN the JIT campaigns cache should NOT be reset
        #expect(mockCampaignsManager.resetJITCampaignsCachesCalled == false)
    }
}

// Mock class for BALocalCampaignsManager to track method calls
class MockBALocalCampaignsManager: BALocalCampaignsManager {
    var resetJITCampaignsCachesCalled = false

    override func resetJITCampaignsCaches() {
        resetJITCampaignsCachesCalled = true
        super.resetJITCampaignsCaches()
    }
}
