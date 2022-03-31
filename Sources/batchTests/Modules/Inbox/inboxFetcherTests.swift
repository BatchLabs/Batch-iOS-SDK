//
//  batchEventDataTests.swift
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation
import XCTest
import Batch

class inboxFetcherTests: XCTestCase
{
    func testFilterSilentNotificationsProperty() {
        // This test makes sure that the default silent notification property value is right and that it can be set.
        // The implementation of this flag isn't tested here.
        func verifyValues(_ fetcher: BatchInboxFetcher) {
            XCTAssertTrue(fetcher.filterSilentNotifications)
            fetcher.filterSilentNotifications = false
            XCTAssertFalse(fetcher.filterSilentNotifications)
            fetcher.filterSilentNotifications = true
            XCTAssertTrue(fetcher.filterSilentNotifications)
        }
        
        verifyValues(BatchInbox.fetcher())
        verifyValues(BatchInbox.fetcher(forUserIdentifier: "foobar", authenticationKey: "12345")!)
    }
}
