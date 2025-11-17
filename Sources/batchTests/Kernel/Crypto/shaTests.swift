//
//  shaTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import XCTest

class shaTests: XCTestCase {
    static let testData =
        "!&é\"'(§è!çà)-12567890°_%^$mù`=*/.,?,;:=‘{«ÇøÇø}—ë‘¶Ç¡@#|¿¡ïŒ€£µ~©®†™≈<>≤≥êÊ•π‡∂ƒÌ¬◊ß∞÷≠+∫√¢‰∆∑Ω¥∏ªŸ[]å”„ック金型илджفيحةحديد"
        .data(using: .utf8)!

    func testSHA1() {
        let expected = "pG+tIWKFrPjoZ4RHGLE4/mQllCE="
        XCTAssertNil(BASHA.sha1Hash(of: nil))
        XCTAssertNil(BASHA.sha1Hash(of: Data()))
        XCTAssertEqual(Data(base64Encoded: expected), BASHA.sha1Hash(of: shaTests.testData))
    }

    func testSHA256() {
        let expected = "mXBL5btsUw7w1NsW5b6+6uqKDNH70sxhkJfvPf3cM4E="
        XCTAssertNil(BASHA.sha256Hash(of: nil))
        XCTAssertNil(BASHA.sha256Hash(of: Data()))
        XCTAssertEqual(Data(base64Encoded: expected), BASHA.sha256Hash(of: shaTests.testData))
    }
}
