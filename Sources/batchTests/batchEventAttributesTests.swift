//
//  batchEventAttributesTests.swift
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch
import Foundation
import XCTest

class batchEventAttributesTests: XCTestCase {
    func testValidData() {
        let attributes = BatchEventAttributes()

        let now = Date(timeIntervalSince1970: 1_589_466_748.930)
        let url = URL(string: "https://batch.com")
        attributes.put(["foo", "BAR", "baz"], forKey: "$tags")
        attributes.put(1, forKey: "int")
        attributes.put(1.0 as Float, forKey: "float")
        attributes.put(1.0 as Double, forKey: "double")
        attributes.put(true, forKey: "bool")
        attributes.put("foobar", forKey: "string")
        attributes.put(" 456 ", forKey: "123")
        attributes.put(now, forKey: "now")
        attributes.put(url!, forKey: "url")

        let internalRepresentation = try! BATEventAttributesSerializer.serialize(eventAttributes: attributes)
        let tags = internalRepresentation["tags"] as! [String]
        let jsonAttributes = internalRepresentation["attributes"] as! [String: AnyObject]

        XCTAssertTrue(tags.contains("foo"))
        XCTAssertTrue(tags.contains("bar"))
        XCTAssertTrue(tags.contains("baz"))

        XCTAssertEqual(1, jsonAttributes["int.i"] as! Int)
        XCTAssertEqual(1.0 as Float, jsonAttributes["float.f"] as! Float)
        XCTAssertEqual(1.0 as Double, jsonAttributes["double.f"] as! Double)
        XCTAssertEqual(true, jsonAttributes["bool.b"] as! Bool)
        XCTAssertEqual("foobar", jsonAttributes["string.s"] as! String)
        XCTAssertEqual(" 456 ", jsonAttributes["123.s"] as! String)
        XCTAssertEqual(1_589_466_748_930, jsonAttributes["now.t"] as! Int64)
        XCTAssertEqual("https://batch.com", jsonAttributes["url.u"] as! String)

        XCTAssertNil(internalRepresentation["converted"])
    }

    func testInvalidData() {
        let attributes = BatchEventAttributes()

        attributes.put(
            "A way too long string that goes for quiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiite too long"
                + "Lorem ipsum dolor and other various stuff.", forKey: "string"
        )
        attributes.put("foobar", forKey: "invalid_key%%%")
        attributes.put("foobar", forKey: "key_that_is_too_long_really_it_should_be_more_than_thirty_chars")
        attributes.put(URL(string: "batch.com")!, forKey: "url_without_scheme")
        let _ = try! BATEventAttributesSerializer.serialize(eventAttributes: attributes)
    }
}
