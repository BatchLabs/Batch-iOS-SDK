//
//  batchEventAttributesTests.swift
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch
import Foundation
import Testing

struct BatchEventAttributesTests {
    @Test func validData() {
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

        #expect(tags.contains("foo"))
        #expect(tags.contains("bar"))
        #expect(tags.contains("baz"))

        #expect(jsonAttributes["int.i"] as! Int == 1)
        #expect(1.0 as Float == jsonAttributes["float.f"] as! Float)
        #expect(1.0 as Double == jsonAttributes["double.f"] as! Double)
        #expect(jsonAttributes["bool.b"] as! Bool == true)
        #expect(jsonAttributes["string.s"] as! String == "foobar")
        #expect(jsonAttributes["123.s"] as! String == " 456 ")
        #expect(jsonAttributes["now.t"] as! Int64 == 1_589_466_748_930)
        #expect(jsonAttributes["url.u"] as! String == "https://batch.com")

        #expect(internalRepresentation["converted"] == nil)
    }

    @Test func invalidData() throws {
        let attributes = BatchEventAttributes()

        attributes.put(
            "A way too long string that goes for quiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiite too long"
                + "Lorem ipsum dolor and other various stuff.", forKey: "string"
        )
        attributes.put("foobar", forKey: "invalid_key%%%")
        attributes.put("foobar", forKey: "key_that_is_too_long_really_it_should_be_more_than_thirty_chars")
        attributes.put(URL(string: "batch.com")!, forKey: "url_without_scheme")
        _ = try BATEventAttributesSerializer.serialize(eventAttributes: attributes)
    }
}
