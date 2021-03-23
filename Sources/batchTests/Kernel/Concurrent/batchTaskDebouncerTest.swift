//
//  batchTaskDebouncerTest.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import XCTest
import Batch.Batch_Private

class batchTaskDebouncerTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOneshotDebouncer() {
        var callCounter = 0;
        let expectation = self.expectation(description: "Debounced task executed")
        let debouncer = BATaskDebouncer(delay: 0.5, queue: DispatchQueue.global(qos: .default)) {
            callCounter = callCounter + 1
            expectation.fulfill()
        }
        debouncer?.schedule()
        debouncer?.schedule()
        debouncer?.schedule()
        
        waitForExpectations(timeout: 2.0, handler: nil)
        XCTAssertEqual(callCounter, 1)
    }
    
    func testRepeatingDebouncer() {
        // Maybe we also could measure the elapsed time?
        var callCounter = 0;
        let expectation = self.expectation(description: "Debounced task executed")
        var debouncer: BATaskDebouncer? = nil
        debouncer = BATaskDebouncer(delay: 0.2, queue: DispatchQueue.global(qos: .default)) {
            callCounter = callCounter + 1
            if (callCounter >= 3) {
                expectation.fulfill()
            } else {
                debouncer?.schedule()
            }
            
        }
        debouncer?.schedule()
        debouncer?.schedule()
        debouncer?.schedule()
        
        waitForExpectations(timeout: 4.0, handler: nil)
        XCTAssertEqual(callCounter, 3)
    }
}
