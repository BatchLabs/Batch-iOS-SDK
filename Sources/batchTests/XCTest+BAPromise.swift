//
//  XCTest+BAPromise.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import XCTest

// Asserts that the promise resolved with the expected value
// Note: this doesn't wait for the promise to have been executed before completing the tests
public func XCTAssertResolves<T>(
    _ expected: @autoclosure () throws -> T?,
    _ promise: @autoclosure () throws -> BAPromise<T>,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) where T: Equatable {
    let promise = try! promise()
    let expected = try! expected()
    let message = message()
    promise.then { (_ resolvedValue: T?) in
        XCTAssertEqual(expected, resolvedValue, message, file: file, line: line)
    }
    promise.catch { err in
        XCTFail(
            "Promise was expected to be resolved with '\(String(describing: expected))' but was rejected with '\(String(describing: err))'.",
            file: file,
            line: line
        )
    }
}

// Asserts that the promise is rejected
// Note: this doesn't wait for the promise to have been executed before completing the tests.
// As there is no way to signal the test runner that we should wait for a value, please call XCTAssertNoPendingPromise at the end of your test
public func XCTAssertRejects<T>(
    _ promise: @autoclosure () throws -> BAPromise<T>,
    _: @autoclosure () -> String = "",
    file _: StaticString = #filePath,
    line _: UInt = #line
) {
    let promise = try! promise()
    promise.then { (_ resolvedValue: T?) in
        XCTFail("Promise to be rejected, but was resolved with '\(String(describing: resolvedValue))'.")
    }
}

// Asserts that the promise isn't pending, but has been resolved or rejected
// This should be ran at the end of your test
public func XCTAssertNoPendingPromise<T>(
    _ promise: @autoclosure () throws -> BAPromise<T>,
    file _: StaticString = #filePath,
    line _: UInt = #line
) {
    let promise = try! promise()
    XCTAssertNotEqual(BAPromiseStatus.pending, promise.status)
}

// Asserts that none of the given promises are pending, but have been resolved or rejected
// This should be ran at the end of your test
public func XCTAssertNoPendingPromise<T>(
    _ promises: @autoclosure () throws -> [BAPromise<T>],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let promises = try! promises()
    promises.forEach { promise in
        XCTAssertNotEqual(BAPromiseStatus.pending, promise.status, file: file, line: line)
    }
}

// Extension that allows pushing a promise to an array while returning it
// Useful for XCTAssertNoPendingPromise
extension Array {
    mutating func push<T>(_ promise: Element) -> Element where Element: BAPromise<T> {
        append(promise)
        return promise
    }
}
