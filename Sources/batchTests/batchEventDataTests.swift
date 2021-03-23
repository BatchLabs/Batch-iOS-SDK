//
//  batchEventDataTests.swift
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation
import XCTest
import Batch

class BatchEventDataTests: XCTestCase
{
    func testValidData()
    {
        let data = BatchEventData()
        data.add(tag: "foo")
        data.add(tag: "BAR")
        data.add(tag: "baz")
        
        let now = Date(timeIntervalSince1970: 1589466748.930)
        data.put(1, forKey: "int")
        data.put(1.0 as Float, forKey: "float")
        data.put(1.0 as Double, forKey: "double")
        data.put(true, forKey: "bool")
        data.put("foobar", forKey: "string")
        data.put(" 456 ", forKey: "123")
        data.put(now, forKey: "now")
        
        let internalRepresentation = data._internalDictionaryRepresentation()
        let tags = internalRepresentation["tags"] as! [String]
        let attributes = internalRepresentation["attributes"] as! [String: AnyObject]
        
        XCTAssertTrue(tags.contains("foo"))
        XCTAssertTrue(tags.contains("bar"))
        XCTAssertTrue(tags.contains("baz"))
        
        XCTAssertEqual(1, attributes["int.i"] as! Int)
        XCTAssertEqual(1.0 as Float, attributes["float.f"] as! Float)
        XCTAssertEqual(1.0 as Double, attributes["double.f"] as! Double)
        XCTAssertEqual(true, attributes["bool.b"] as! Bool)
        XCTAssertEqual("foobar", attributes["string.s"] as! String)
        XCTAssertEqual(" 456 ", attributes["123.s"] as! String)
        XCTAssertEqual(1589466748930, attributes["now.t"] as! Int64)
        
        XCTAssertNil(internalRepresentation["converted"])
    }
    
    func testSizeLimits()
    {
        let data = BatchEventData()
        
        for i in 0...20 {
            data.add(tag: String(i))
            data.put(i, forKey:String(i))
        }
        
        let internalRepresentation = data._internalDictionaryRepresentation()
        let tags = internalRepresentation["tags"] as! [String]
        let attributes = internalRepresentation["attributes"] as! [String: AnyObject]
        
        XCTAssertEqual(10, tags.count)
        XCTAssertEqual(15, attributes.count)
    }
    
    func testOverwrite()
    {
        // Tests that users can still overwite keys even if they hit the limit
        // Issue #57
        let data = BatchEventData()
        
        for i in 0...14 {
            data.put(i, forKey:String(i))
        }
        data.put("foobar", forKey:"2")
        
        let internalRepresentation = data._internalDictionaryRepresentation()
        let attributes = internalRepresentation["attributes"] as! [String: AnyObject]
        
        XCTAssertEqual(15, attributes.count)
        XCTAssertEqual("foobar", attributes["2.s"] as! String)
    }
    
    func testInvalidData()
    { 
        let data = BatchEventData()
        
        data.add(tag: "A way too long string that goes for quiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiite too long"
            + "Lorem ipsum dolor and other various stuff.")
        data.add(tag: "")
        
        data.put("A way too long string that goes for quiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiite too long"
            + "Lorem ipsum dolor and other various stuff.", forKey:"string");
        data.put("foobar", forKey:"invalid_key%%%");
        data.put("foobar", forKey:"key_that_is_too_long_really_it_should_be_more_than_thirty_chars");
        
        let internalRepresentation = data._internalDictionaryRepresentation()
        let tags = internalRepresentation["tags"] as! [String]
        let attributes = internalRepresentation["attributes"] as! [String: AnyObject]
        
        XCTAssertEqual(0, tags.count)
        XCTAssertEqual(0, attributes.count)
    }
    
    func testLegacyDataConversion()
    {
        let legacyData: [String:Any] = [
        "int": Int(1),
        "long": Int(1),
        "float": Float(1.0),
        "double": Double(1.0),
        "bool": true,
        "string": "foobar",
        ]
        
        let data = BatchEventData()
        data._copyLegacyData(legacyData)
        
        let internalRepresentation = data._internalDictionaryRepresentation()
        let tags = internalRepresentation["tags"] as! [String]
        let attributes = internalRepresentation["attributes"] as! [String: AnyObject]
        
        
        XCTAssertEqual(0, tags.count)
        XCTAssertEqual(6, attributes.count)
        
        XCTAssertEqual(1, attributes["int.i"] as! Int)
        XCTAssertEqual(1, attributes["long.i"] as! Int)
        XCTAssertEqual(1.0 as Float, attributes["float.f"] as! Float)
        XCTAssertEqual(1.0 as Double, attributes["double.f"] as! Double)
        XCTAssertEqual(true, attributes["bool.b"] as! Bool)
        XCTAssertEqual("foobar", attributes["string.s"] as! String)
        
        XCTAssertTrue(internalRepresentation["converted"] as! Bool)
    }
    
    func testLegacyDataConversionOrdering()
    {
        // This test checks that the first 10 legacy array keys are picked in a predictable way
        // They should be ordered
        
        let value = "test"
        let unorderedKeys = [
            "drLAjNhvYs",
            "wNMFqBvSHe",
            "xZivnkZdZv",
            "ZEZVbaXwDD",
            "tvwZZnHsoJ",
            "nCDiIffIqq",
            "bXybuzBSvX",
            "uImQWnrAyw",
            "dIHDhyyDsk",
            "AEBVYnPTuo",
            "jfzUsSnTDf",
            "vhochDgxOB",
            "bJZgGgwKIM",
            "GvdPlhWfyT",
            "HQiXZQNHLs",
            "wUGgNuvdTY",
            "JHLZaOOoBQ",
            "vemRXpXcUK",
            "MEiAzZWjga",
            "FViUCTCzfE",
        ]
        
        let legacyData: [String:String] = unorderedKeys.reduce(into: [:]) { (data, key) in
            data[key] = value
        }
        
        let data = BatchEventData()
        data._copyLegacyData(legacyData)
        
        let internalRepresentation = data._internalDictionaryRepresentation()
        let attributeKeys = (internalRepresentation["attributes"] as! [String: AnyObject]).keys
        
        // Dicts are not ordered, so we need to sort the keys beforehand, and check if they're all there
        
        XCTAssertEqual(15, attributeKeys.count)
        
        let expectedConvertedKeys = unorderedKeys.map({ "\($0.lowercased()).s" }).sorted().prefix(10)
        expectedConvertedKeys.forEach({
            XCTAssertTrue(attributeKeys.contains($0))
        })
    }
}
