//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import XCTest

@testable import Batch

final class profileCenterTests: XCTestCase {
    let eventTracker = MockEventTracker()

    override func setUp() {
        super.setUp()
        let _ = eventTracker.registerOverlay()
    }

    override func tearDown() {
        eventTracker.reset()
    }

    func testApplyEditor() throws {
        let editor = BatchProfile.editor()
        try? editor.set(attribute: true, forKey: "booleanAttribute")
        editor.save()
        XCTAssertNotNil(eventTracker.findEvent(name: .profileDataChanged, parameters: nil))
    }

    func testEmptyApplyEditor() throws {
        let editor = BatchProfile.editor()
        editor.save()
        XCTAssertNil(eventTracker.findEvent(name: .profileDataChanged, parameters: nil))
    }

    func testOnProjectChangedSendsNativeData() throws {
        let profileCenter = BAProfileCenter()
        profileCenter.onProjectChanged(oldProjectKey: nil, newProjectKey: "test_project")

        let event = eventTracker.findEvent(name: .nativeDataChanged, parameters: nil)
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.parametersDictionary["app_bundle_id"] as? String, BAPropertiesCenter.value(forShortName: "bid"))
        XCTAssertEqual(event?.parametersDictionary["os_version"] as? String, BAPropertiesCenter.value(forShortName: "osv"))
    }
    func testApplyEditorPayloadTooLarge() throws {
        // 20 string-array attributes × 25 distinct strings × 295 chars ≈ 147 kB, well above 25 kB
        let editor = BatchProfile.editor()
        let largeList = (0..<25).map { String(repeating: "a", count: 295) + String(format: "%05d", $0) }
        for i in 0..<20 {
            try? editor.set(attribute: largeList, forKey: "attr_\(i)")
        }
        editor.save()
        XCTAssertNil(eventTracker.findEvent(name: .profileDataChanged, parameters: nil))
    }
}
