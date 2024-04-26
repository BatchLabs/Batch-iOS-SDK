//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import XCTest

/// XCTestCase extension to help with threading
public extension XCTestCase {
    /// Waits for the main thread to consume its tasks before continuing. Useful for tests that need to wait on something
    /// that has been dispatched on the main thread.
    @objc
    func waitForMainThreadLoop() {
        // Since some tests use methods that schedules async work on the main thread, we have
        // to perform a little dance to correctly test the behaviour
        // To work around this, we schedule something to run on the main thread
        // AFTER other work has been submitted, and wait for our dummy
        // task to finish
        let expectation = self.expectation(description: "Wait for a main thread loop run")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }

    @objc
    func waitForQueueLoop(queue: DispatchQueue) {
        // Since some tests use methods that schedules async work on dispatch queue, we have
        // to perform a little dance to correctly test the behaviour
        // To work around this, we schedule something to run on the given queue
        // AFTER other work has been submitted, and wait for our dummy
        // task to finish
        let expectation = self.expectation(description: "Wait for a dispatch queue loop run")
        queue.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }
}
