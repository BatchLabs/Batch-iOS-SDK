//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import XCTest

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
}
