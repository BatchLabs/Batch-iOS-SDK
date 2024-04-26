//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import XCTest

final class profileIdentifyTests: XCTestCase {
    // Test that a valid custom ID triggers an identify
    func testValidIdentification() throws {
        let expectedCustomID = "identifier12345678"

        let eventTracker = MockEventTracker()
        let _ = eventTracker.registerOverlay()
        // Reinstanciate it as the shared instance did not get our event tracker mock
        let profileModule = BAProfileCenter()

        profileModule.identify(expectedCustomID)

        XCTAssertNotNil(eventTracker.findEvent(name: .profileIdentify, parameters: [
            "identifiers": [
                "custom_id": expectedCustomID,
                "install_id": BatchUser.installationID!,
            ],
        ]))

        // Logout
        profileModule.identify(nil)

        XCTAssertNotNil(eventTracker.findEvent(name: .profileIdentify, parameters: [
            "identifiers": [
                "custom_id": NSNull(),
                "install_id": BatchUser.installationID!,
            ],
        ]))
    }

    // Test that an invalid custom id doesn't do anything
    func testInvalidIdentification() throws {
        let invalidCustomIDs: [String] = [
            String(repeating: "foo", count: 1000),
            "",
            "foo\nbar",
        ]

        let eventTracker = MockEventTracker()
        let _ = eventTracker.registerOverlay()
        let profileModule = BAProfileCenter()

        for customID in invalidCustomIDs {
            print("Testing identify: '\(customID)'")
            profileModule.identify(customID)

            XCTAssertNil(eventTracker.findEvent(name: .profileIdentify, parameters: [
                "identifiers": [
                    "custom_id": customID,
                    "install_id": BatchUser.installationID!,
                ],
            ]))
        }
    }

    // Test that setting a custom ID calls the compatiblity code
    func testCompatibility() throws {
        let expectedCustomID = "identifier12345678"

        let eventTracker = MockEventTracker()
        let _ = eventTracker.registerOverlay()
        let profileModule = BAProfileCenter()

        let installDataEditor = BAInstallDataEditorMock()
        let _ = BAInjection.overlayClass(BAInstallDataEditor.self, returnedInstance: installDataEditor)

        profileModule.identify(expectedCustomID)

        XCTAssertEqual(installDataEditor.identifierToSet, expectedCustomID)
        XCTAssertTrue(installDataEditor.saveCalled)

        // Logout
        installDataEditor.reset()
        profileModule.identify(nil)

        XCTAssertTrue(installDataEditor.setIdentifierCalled)
        XCTAssertEqual(installDataEditor.identifierToSet, nil)
        XCTAssertTrue(installDataEditor.saveCalled)

        // Invalid
        installDataEditor.reset()
        let invalidCustomID = String(repeating: "foo", count: 1000)
        profileModule.identify(invalidCustomID)
        XCTAssertFalse(installDataEditor.setIdentifierCalled)
        // "save" can be called or not on an invalid custom id, we don't care
    }
}
