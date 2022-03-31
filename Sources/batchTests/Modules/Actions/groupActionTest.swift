//
//  groupActionTest.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import XCTest

class groupActionTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGroup() {
        let first = StateRecordingAction()
        let second = StateRecordingAction()

        let actionsCenter = BAActionsCenter()
        actionsCenter.register(
            BatchUserAction(
                identifier: "first",
                actionBlock: { (identifier: String, args: [String: Any], source: BatchUserActionSource?) in
                    first.run()
                }))
        actionsCenter.register(
            BatchUserAction(
                identifier: "second",
                actionBlock: { (identifier: String, args: [String: Any], source: BatchUserActionSource?) in
                    second.run()
                }))

        let groupJSON = "{\"actions\":[[\"first\", {\"foo\": \"bar\"}],[],[\"invalid\"],[\"second\"]]}"

        actionsCenter.performAction("batch.group", withArgs: parseJSON(groupJSON), andSource: nil)

        XCTAssertTrue(first.didRun)
        XCTAssertTrue(second.didRun)

        // Test that an invalid json doesn't crash
        actionsCenter.performAction("batch.group", withArgs: parseJSON("{}"), andSource: nil)
        actionsCenter.performAction("batch.group", withArgs: parseJSON("{\"foo\":\"bar\"}"), andSource: nil)
        actionsCenter.performAction(
            "batch.group",
            withArgs: parseJSON("{\"actions\":\"bar\"}"),
            andSource: nil)
        actionsCenter.performAction("batch.group", withArgs: parseJSON("{\"actions\":[]}"), andSource: nil)
        actionsCenter.performAction(
            "batch.group",
            withArgs: parseJSON("{\"actions\":{\"foo\":\"bar\"}}"),
            andSource: nil)
        actionsCenter.performAction(
            "batch.group",
            withArgs: parseJSON("{\"actions\":[{\"foo\":\"bar\"}]}"),
            andSource: nil)
    }

    func testGroupLimits() {
        var actionsCenter = BAActionsCenter()
        var shouldNotRun = StateRecordingAction()

        actionsCenter.register(
            BatchUserAction(
                identifier: "shouldNotRun",
                actionBlock: { (identifier: String, args: [String: Any], source: BatchUserActionSource?) in
                    shouldNotRun.run()
                }))

        let nestedAction = "{\"actions\":[[\"batch.group\", {\"actions\": [\"shouldNotRun\"]}]]}"

        actionsCenter.performAction("batch.group", withArgs: parseJSON(nestedAction), andSource: nil)

        XCTAssertFalse(shouldNotRun.didRun)

        // Check that you can't run too many actions

        actionsCenter = BAActionsCenter()
        shouldNotRun = StateRecordingAction()
        let dummy = StateRecordingAction()

        actionsCenter.register(
            BatchUserAction(
                identifier: "shouldNotRun",
                actionBlock: { (identifier: String, args: [String: Any], source: BatchUserActionSource?) in
                    shouldNotRun.run()
                }))
        actionsCenter.register(
            BatchUserAction(
                identifier: "dummy",
                actionBlock: { (identifier: String, args: [String: Any], source: BatchUserActionSource?) in
                    dummy.run()
                }))

        // Make sure that 10 actions max can run
        // This should only count valid actions
        let manyActions =
            "{\"actions\":[[\"dummy\"], [], [\"foo\", \"bar\"], [\"dummy\"], [\"dummy\"], [\"dummy\"], [\"dummy\"], [\"dummy\"], [\"dummy\"], [\"dummy\"], [\"dummy\"], [\"dummy\"], [\"shouldNotRun\"]]}"
        actionsCenter.performAction("batch.group", withArgs: parseJSON(manyActions), andSource: nil)

        XCTAssertTrue(dummy.didRun)
        XCTAssertFalse(shouldNotRun.didRun)
    }

    func parseJSON(_ rawJSON: String) -> [String: NSObject] {
        return try! JSONSerialization.jsonObject(with: rawJSON.data(using: .utf8)!, options: []) as! [String: NSObject]
    }
}

class StateRecordingAction {
    var didRun = false

    func run() {
        didRun = true
    }
}
