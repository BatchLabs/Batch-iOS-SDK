//
//  batchContextTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation
import XCTest
import Batch.Batch_Private

class batchContextTests: XCTestCase {
    
    func testMetaContext() {
        let context = BALMetaContext(contexts: [
                SimpleVariableContext(name: "foo", value: BALPrimitiveValue(string: "bar")!),
                SimpleVariableContext(name: "lorem", value: BALPrimitiveValue(string: "ipsum")!)
            ])
        
        XCTAssertEqual(context.resolveVariableNamed("foo"), BALPrimitiveValue(string: "bar"))
        XCTAssertEqual(context.resolveVariableNamed("lorem"), BALPrimitiveValue(string: "ipsum"))
        XCTAssertNil(context.resolveVariableNamed("missing"))
    }
    
    func testCachingContext() {
        // Context that only returns a valid value on the first call
        @objc class AlternatingContext: NSObject, BALEvaluationContext {
            let value: BALValue
            var shouldReturnValue = true
            
            init(value: BALValue) {
                self.value = value
            }
            
            func resolveVariableNamed(_ name: String) -> BALValue? {
                if (shouldReturnValue) {
                    shouldReturnValue = false
                    return self.value
                }
                return nil
            }
        }
        
        var alternatingContext = AlternatingContext(value: BALPrimitiveValue.init(string: "foo")!)
        var cachingContext = BALCachingContext(context: alternatingContext)
        XCTAssertEqual(cachingContext.resolveVariableNamed("foo"), BALPrimitiveValue.init(string: "foo"))
        // Test that the alternating context works
        XCTAssertNil(alternatingContext.resolveVariableNamed("foo"))
        XCTAssertEqual(cachingContext.resolveVariableNamed("foo"), BALPrimitiveValue.init(string: "foo"))
        
        alternatingContext = AlternatingContext(value: BALPrimitiveValue.nil())
        cachingContext = BALCachingContext(context: alternatingContext)
        XCTAssertEqual(cachingContext.resolveVariableNamed("foo"), BALPrimitiveValue.nil())
        // Test that the alternating context works
        XCTAssertNil(alternatingContext.resolveVariableNamed("foo"))
        XCTAssertEqual(cachingContext.resolveVariableNamed("foo"), BALPrimitiveValue.nil())
    }
    
    func testPrivateEventContext() {
        let context = BALEventContext(privateEvent: "_START")
        func resolve(_ name: String) -> BALValue? {
            return context.resolveVariableNamed(name.lowercased())
        }
        
        XCTAssertEqual(resolve("e.name"), BALPrimitiveValue(string: "_START"))
        XCTAssertEqual(resolve("e.label"), BALPrimitiveValue.nil())
        XCTAssertEqual(resolve("e.tags"), BALPrimitiveValue.nil())
        XCTAssertEqual(resolve("e.attr['foo']"), BALPrimitiveValue.nil())
        
        // Check that the context fall through unknown variables
        XCTAssertNil(resolve("test"))
    }
    
    func testPublicEventContext() {
        let eventData = BatchEventData()
        eventData.add(tag: "foo")
        eventData.add(tag: "bar")
        eventData.put(true, forKey: "bool")
        eventData.put(2 as Double, forKey: "double")
        eventData.put(2 as Float, forKey: "float")
        eventData.put(2 as Int, forKey: "int")
        eventData.put("str", forKey: "string")
        eventData.put("str", forKey: "CAPS")
        
        let context = BALEventContext(publicEvent: "E.TEST_EVENT", label: "test label", data: eventData)
        func resolve(_ name: String) -> BALValue? {
            return context.resolveVariableNamed(name.lowercased())
        }
        
        XCTAssertEqual(resolve("e.name"), BALPrimitiveValue(string: "E.TEST_EVENT"))
        XCTAssertEqual(resolve("e.label"), BALPrimitiveValue(string: "test label"))
        XCTAssertEqual(resolve("e.tags"), BALPrimitiveValue(stringSet: ["foo", "bar"]))
        
        XCTAssertEqual(resolve("e.attr['bool']"), BALPrimitiveValue(boolean: true))
        XCTAssertEqual(resolve("e.attr['double']"), BALPrimitiveValue(double: 2.0))
        XCTAssertEqual(resolve("e.attr['float']"), BALPrimitiveValue(double: 2.0))
        XCTAssertEqual(resolve("e.attr['int']"), BALPrimitiveValue(double: 2.0))
        XCTAssertEqual(resolve("e.attr['string']"), BALPrimitiveValue(string: "str"))
        XCTAssertEqual(resolve("e.attr['missing']"), BALPrimitiveValue.nil())
        
        XCTAssertEqual(resolve("e.attr['STRING']"), BALPrimitiveValue(string: "str"))
        XCTAssertEqual(resolve("e.attr['caps']"), BALPrimitiveValue(string: "str"))
        
        // Check that the context fall through unknown variables
        XCTAssertNil(resolve("test"))
    }
    
    func testNativeAttributeContext() {
        let context = BALNativeAttributeContext()
        func resolve(_ name: String) -> BALValue? {
            return context.resolveVariableNamed(name.lowercased())
        }
        
        XCTAssertEqual(resolve("b.lvl"), BALPrimitiveValue(string: String(BAAPILevel)))
        XCTAssertEqual(resolve("b.foobar"), BALPrimitiveValue.nil())
        
        // Check that the context fall through unknown variables
        XCTAssertNil(resolve("test"))
    }
    
    func testUserAttributeContext() {
        @objc class MockCustomDataDatasource: BaseMockCustomDataDatasource {
            override func attributes() -> [String : BAUserAttribute] {
                return [
                    "c.str" : BAUserAttribute(value: "string" as NSString, type: .string),
                    "c.long" : BAUserAttribute(value: NSNumber(value: 2), type: .longLong),
                    "c.double" : BAUserAttribute(value: NSNumber(value: 234.567), type: .double),
                    "c.bool" : BAUserAttribute(value: NSNumber(value: true), type: .bool),
                    "c.date" : BAUserAttribute(value: NSDate(timeIntervalSince1970: 1536325808.2345678), type: .date),
                    "c.null" : BAUserAttribute(value: NSNull(), type: .deleted),
                    "c.inconsistent" : BAUserAttribute(value: NSNumber(value: 2), type: .string)
                ]
            }
            
            override func tagCollections() -> [String : Set<String>] {
                return ["collection1": ["foo", "bar", "foo"]]
            }
        }
        
        let context = BALUserAttributeContext(datasource: MockCustomDataDatasource())
        func resolve(_ name: String) -> BALValue? {
            return context.resolveVariableNamed(name.lowercased())
        }
        
        XCTAssertEqual(resolve("c.missing"), BALPrimitiveValue.nil())
        XCTAssertEqual(resolve("c.str"), BALPrimitiveValue(string: "string"))
        XCTAssertEqual(resolve("c.long"), BALPrimitiveValue(double: 2))
        XCTAssertEqual(resolve("c.double"), BALPrimitiveValue(double: 234.567))
        XCTAssertEqual(resolve("c.bool"), BALPrimitiveValue(boolean: true))
        XCTAssertEqual(resolve("c.date"), BALPrimitiveValue(double: 1536325808234))
        XCTAssertEqual(resolve("c.null"), BALPrimitiveValue.nil())
        XCTAssertEqual(resolve("c.inconsistent"), BALPrimitiveValue.nil())
        
        XCTAssertEqual(resolve("t.missing"), BALPrimitiveValue.nil())
        XCTAssertEqual(resolve("t.collection1"), BALPrimitiveValue(stringSet: ["foo", "bar"]))
        
        // Check that the context fall through unknown variables
        XCTAssertNil(resolve("test"))
    }
}

@objc class SimpleVariableContext: NSObject, BALEvaluationContext {
    let name: String
    let value: BALValue
    
    init(name: String, value: BALValue) {
        self.name = name.lowercased()
        self.value = value
    }
    
    func resolveVariableNamed(_ name: String) -> BALValue? {
        if name.lowercased() == self.name {
            return self.value
        }
        return nil
    }
}

@objc private class BaseMockCustomDataDatasource: NSObject, BAUserDatasourceProtocol {
    func attributes() -> [String: BAUserAttribute] {
        return [:]
    }
    
    func tagCollections() -> [String : Set<String>] {
        return [:]
    }
    
    func close() {}
    
    func clear() {}
    
    func acquireTransactionLock(withChangeset changeset: Int64) -> Bool { return false }
    
    func commitTransaction() -> Bool { return false }
    
    func rollbackTransaction() -> Bool { return false }
    
    func setLongLongAttribute(_ attribute: Int64, forKey key: String) -> Bool { return false }
    
    func setDoubleAttribute(_ attribute: Double, forKey key: String) -> Bool { return false }
    
    func setBoolAttribute(_ attribute: Bool, forKey key: String) -> Bool { return false }
    
    func setStringAttribute(_ attribute: String, forKey key: String) -> Bool { return false }
    
    func setDateAttribute(_ attribute: Date, forKey key: String) -> Bool { return false }
    
    func setURLAttribute(_ attribute: URL, forKey key: String) -> Bool { return false }
    
    func removeAttributeNamed(_ attribute: String) -> Bool { return false }
    
    func addTag(_ tag: String, toCollection collection: String) -> Bool { return false }
    
    func removeTag(_ tag: String, fromCollection collection: String) -> Bool { return false }
    
    func clearTags() -> Bool { return false }
    
    func clearTags(fromCollection collection: String) -> Bool { return false }
    
    func clearAttributes() -> Bool { return false }
    
    func printDebugDump() -> String { return "not implemented" }
    

}
