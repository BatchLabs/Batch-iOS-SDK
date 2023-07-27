//
//  webserviceHMACTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import XCTest

class webserviceHMACTests: XCTestCase {
    var hmac: BATWebserviceHMAC!

    override func setUp() {
        hmac = BATWebserviceHMAC(key: "12345")!
    }

    func testInstanciation() {
        XCTAssertNil(BATWebserviceHMAC(key: ""))
        XCTAssertNotNil(BATWebserviceHMAC(key: "foo"))
    }

    func testURLRequest() {
        var request = NSMutableURLRequest(url: URL(string: "https://batch.com/foo/BAR?param=value")!)

        request.httpMethod = "GET"
        request.addValue("application/JSON", forHTTPHeaderField: "Content-Type")
        request.addValue("2", forHTTPHeaderField: "x-batch-CIPHER-version")
        request.addValue("bar", forHTTPHeaderField: "foo")
        request.addValue("", forHTTPHeaderField: "empty")

        hmac.append(toMutableRequest: request)
        XCTAssertEqual(nil, request.allHTTPHeaderFields?["Content-SHA1"])
        XCTAssertEqual(
            "SHA256 content-type,foo,x-batch-cipher-version Gf8afLnF3TY/LqACciolOoALYeQSZ2dXy8Vxhfl7kI4=",
            request.allHTTPHeaderFields?["X-Batch-Signature"] ?? "error"
        )

        let body =
            "!&é\"'(§è!çà)-12567890°_%^$mù`=*/.,?,;:=‘{«ÇøÇø}—ë‘¶Ç¡@#|¿¡ïŒ€£µ~©®†™≈<>≤≥êÊ•π‡∂ƒÌ¬◊ß∞÷≠+∫√¢‰∆∑Ω¥∏ªŸ[]å”„ック金型илджفيحةحديد"

        request = NSMutableURLRequest(url: URL(string: "https://batch.com/foo/BAR?param=value")!)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)

        request.addValue("application/JSON", forHTTPHeaderField: "Content-Type")
        request.addValue("2", forHTTPHeaderField: "x-batch-CIPHER-version")
        request.addValue("bar", forHTTPHeaderField: "foo")
        request.addValue("", forHTTPHeaderField: "empty")

        hmac.append(toMutableRequest: request)
        XCTAssertEqual("pG+tIWKFrPjoZ4RHGLE4/mQllCE=", request.allHTTPHeaderFields?["Content-SHA1"] ?? "error")
        XCTAssertEqual(
            "SHA256 content-sha1,content-type,foo,x-batch-cipher-version +FZLG5QtIKKrW1zxwzboezVNAb5VJ5RZI0319Wrzal0=",
            request.allHTTPHeaderFields?["X-Batch-Signature"] ?? "error"
        )
    }

    func testHmac() {
        // key: 12345
        let precomputedHmacWithHeaders =
            "SHA256 content-type,foo,x-batch-cipher-version 8Qc8LvpoiakXejOZ9HzkxJOhLulKUdU3fzIL8dk720M="
        let precomputedHmacWithoutHeaders = "SHA256 GuWkDmJXZa5LJCRCDw5DZEWMm+BWUFL3b8ZjV1oEOcU=" // key: 12345
        let precomputedHmacWithNoPath = "SHA256 jqvGLeh81CwCwjJxbTDWtmbk9F+kKnfpWqtI4+RbTkY=" // key: 12345
        XCTAssertEqual(
            precomputedHmacWithHeaders,
            hmac.hmac(
                forMethod: "post",
                relativeURL: "/foo/BAR?param=value",
                headers: [
                    "foo": "bar",
                    "x-batch-CIPHER-version": "2",
                    "Content-Type": "application/JSON",
                ]
            )
        )
        XCTAssertEqual(
            precomputedHmacWithoutHeaders,
            hmac.hmac(
                forMethod: "post",
                relativeURL: "/foo/BAR?param=value",
                headers: [:]
            )
        )

        XCTAssertEqual(
            precomputedHmacWithNoPath,
            hmac.hmac(
                forMethod: "post",
                relativeURL: "",
                headers: [:]
            )
        )
    }

    func testRequestSummary() {
        XCTAssertEqual(
            """
            POST /foo/BAR?param=value
            content-type: application/JSON
            foo: bar
            x-batch-cipher-version: 2
            """,
            hmac._requestSummary(
                forMethod: "post",
                relativeURL: "/foo/BAR?param=value",
                headers: [
                    "foo": "bar",
                    "x-batch-CIPHER-version": "2",
                    "Content-Type": "application/JSON",
                ]
            )
        )

        XCTAssertEqual(
            "POST /foo/BAR?param=value",
            hmac._requestSummary(
                forMethod: "post",
                relativeURL: "/foo/BAR?param=value",
                headers: [:]
            )
        )
    }

    func testShaHMAC() {
        var testString = "Lorem Ipsum Dolor 😂"
        var b64PrecomputedHmac256 = "mih9WNLUTSrPTUOpoviX/PWCHaD2ie0ju716raNCv3Y=" // key: 12345
        var precomputedHmac256 = Data(base64Encoded: b64PrecomputedHmac256)!
        XCTAssertEqual(precomputedHmac256, hmac._sha256Hmac(of: testString.data(using: .utf8)!))

        testString = "Lorem Ipsum\nDolor 😂"
        b64PrecomputedHmac256 = "Vy5unOf7ylcT6prTXfld7THbjp7zChN1tx8oPFO2dso="
        precomputedHmac256 = Data(base64Encoded: b64PrecomputedHmac256)!
        XCTAssertEqual(precomputedHmac256, hmac._sha256Hmac(of: testString.data(using: .utf8)!))
    }

    func testContentHash() {
        let testString = "Lorem Ipsum Dolor 😂"
        let b64Sha1 = "eAetj/A3sg1fDZV9IChIfhvPpPk="
        XCTAssertEqual(b64Sha1, hmac.hashedContent(testString.data(using: .utf8)!))
    }

    func testHeaderKeys() {
        // Those are static so check that no one messed with them
        XCTAssertEqual("X-Batch-Signature", hmac.hmacHeaderKey())
        XCTAssertEqual("Content-SHA1", hmac.contentHashHeaderKey())
    }

    func testHeaderFiltering() {
        // This test only tests the removal of empty headers since we have no header to filter yet
        let headers = [
            "User-Agent": "foo/bar",
            "X-Batch-Cipher-Version": "2",
            "foo": "bar",
            "X-Empty": "",
            "X-NotEmpty": " ",
            "pro": "guard",
        ]
        var expected = headers
        expected.removeValue(forKey: "X-Empty")
        XCTAssertEqual(expected, hmac._filteredHeaders(headers))
    }

    func testHeaderSorting() {
        let headers = [
            "User-Agent": "foo/bar",
            "X-Batch-Cipher-Version": "2",
            "foo": "bar",
            "pro": "guard",
        ]
        XCTAssertEqual(
            [
                "foo",
                "pro",
                "User-Agent",
                "X-Batch-Cipher-Version",
            ], hmac._sortedHeaderKeys(headers)
        )
    }

    func testRelativeURLs() {
        XCTAssertEqual("/", hmac._extractRelativeURL(URL(string: "https://batch.com")!))
        XCTAssertEqual("/foo/bar", hmac._extractRelativeURL(URL(string: "https://batch.com/foo/bar")!))
        XCTAssertEqual(
            "/foo/b😂 a r",
            {
                let path = "foo/b😂 a r".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "error"
                return hmac._extractRelativeURL(URL(string: "https://batch.com/\(path)")!)
            }()
        )
        XCTAssertEqual(
            "/foo/bar?param1=value1&param2=value2",
            hmac._extractRelativeURL(URL(string: "https://batch.com/foo/bar?param1=value1&param2=value2")!)
        )
    }

    func testURLPathFixup() {
        // Tests a codepath that's not supposed to happen
        class FakeURL: NSURL {
            override var path: String? {
                return "foo/bar"
            }
        }

        let url = FakeURL(string: "https://batch.com")!
        XCTAssertEqual("/foo/bar", hmac._extractRelativeURL(url as URL))
    }
}
