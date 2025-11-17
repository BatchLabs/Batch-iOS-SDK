//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import XCTest

class internalLoggerTests: XCTestCase {
    static let expectedPublicLog = "[Batch] - sample log"
    static let expectedInternalLog = "[Batch-Internal] - sample internal log"

    fileprivate let loggerDelegate = MockLoggerDelegate()

    var previousLoggerDelegateSource: BALoggerDelegateSource?

    override func setUp() {
        loggerDelegate.reset()
        BatchSDK.loggerDelegate = loggerDelegate
    }

    override class func tearDown() {
        // Leave the internal logs true for other tests
        BALogger.internalLogsEnabled = true
        BatchSDK.loggerDelegate = nil
    }

    func testEnableInternalLogsWithAPI() {
        BALogger.internalLogsEnabled = false
        log()
        logInternal()
        XCTAssertEqual(loggerDelegate.lastMessage, internalLoggerTests.expectedPublicLog)

        BALogger.internalLogsEnabled = true
        log()
        logInternal()
        XCTAssertEqual(loggerDelegate.lastMessage, internalLoggerTests.expectedInternalLog)
    }

    func log() {
        BALogger.public(domain: nil, message: "sample log")
    }

    func logInternal() {
        BALogger.error(domain: nil, message: "sample internal log")
    }
}

@objc
private class MockLoggerDelegate: NSObject, BatchLoggerDelegate {
    var lastMessage: String?

    func log(withMessage message: String) {
        lastMessage = message
    }

    func reset() {
        lastMessage = nil
    }
}
