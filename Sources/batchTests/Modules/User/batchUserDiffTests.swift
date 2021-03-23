//
//  batchUserDiffTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation
import XCTest
import Batch

class BatchUserDiffTests: XCTestCase
{
    func testAttributesDiff()
    {
        let date = Date(timeIntervalSince1970: 123456)
        let newAttributes: [String: BAUserAttribute] = [
            "c.integer": BAUserAttribute(value: 2, type: .longLong),
            "c.string": BAUserAttribute(value: "foo", type: .string),
            "c.date": BAUserAttribute(value: date, type: .date)
        ]
        
        let oldAttributes: [String: BAUserAttribute] = [
            "c.removed": BAUserAttribute(value: "removed", type: .string),
            "c.string": BAUserAttribute(value: "foobar", type: .string),
            "c.date": BAUserAttribute(value: date, type: .date)
        ]
        
        let diff = BAUserAttributesDiff(newAttributes: newAttributes, previous: oldAttributes)
        
        XCTAssertEqual(diff.added, [
            "c.integer": BAUserAttribute(value: 2, type: .longLong),
            "c.string": BAUserAttribute(value: "foo", type: .string),
            ])
        
        XCTAssertEqual(diff.removed, [
            "c.removed": BAUserAttribute(value: "removed", type: .string),
            "c.string": BAUserAttribute(value: "foobar", type: .string),
            ])
        
        XCTAssertTrue(diff.hasChanges())
        
        let noChangeDiff = BAUserAttributesDiff(newAttributes: newAttributes, previous: newAttributes)
        
        XCTAssertFalse(noChangeDiff.hasChanges())
    }
    
    func testTagsDiff()
    {
        let newCollections: [String: Set<String>] = [
            "newtags": ["added", "collection"],
            "added_one": ["foo", "bar"],
            "removed_one": ["bar"],
            "updated_one": ["foo", "baz"],
            "unchanged": ["foo"]
        ]
        
        let oldCollections: [String: Set<String>] = [
            "removed": ["remo", "ved"],
            "added_one": ["foo"],
            "removed_one": ["foo", "bar"],
            "updated_one": ["foo", "bar"],
            "unchanged": ["foo"]
        ]
        
        let diff = BAUserTagCollectionsDiff(newTagCollections: newCollections, previous: oldCollections)
        
        XCTAssertEqual(diff.added, [
            "updated_one": ["baz"],
            "added_one": ["bar"],
            "newtags": ["added", "collection"],
            ])
        
        XCTAssertEqual(diff.removed, [
            "removed": ["ved", "remo"],
            "removed_one": ["foo"],
            "updated_one": ["bar"]
            ])
        
        XCTAssertTrue(diff.hasChanges())
        
        let noChangeDiff = BAUserTagCollectionsDiff(newTagCollections: newCollections, previous: newCollections)
        
        XCTAssertFalse(noChangeDiff.hasChanges())
    }
    
    func testEventSerialization()
    {
        
        let newCollections: [String: Set<String>] = [
            "newtags": ["new"]
        ]
        
        let oldCollections: [String: Set<String>] = [
            "oldtags": ["old"]
        ]
        
        let newAttributes: [String: BAUserAttribute] = [
            "c.new": BAUserAttribute(value: "newvalue", type: .string)
        ]
        
        let attributeTimestamp = 12345678
        let oldAttributes: [String: BAUserAttribute] = [
            "c.old": BAUserAttribute(value: Date(timeIntervalSince1970: 12345678), type: .date)
        ]
        
        let serializedDiff = BAUserDataDiffTransformer.eventParameters(fromAttributes: BAUserAttributesDiff(newAttributes: newAttributes, previous: oldAttributes),
                                                                       tagCollections: BAUserTagCollectionsDiff(newTagCollections: newCollections, previous: oldCollections),
                                                                       version: 2)
        
        XCTAssertEqual(serializedDiff["version"] as? Int, 2)
        XCTAssertEqual(serializedDiff["added"] as! NSDictionary, [
            "t.newtags": ["new"],
            "new.s": "newvalue"
            ] as NSDictionary)
        XCTAssertEqual(serializedDiff["removed"] as! NSDictionary, [
            "t.oldtags": ["old"],
            "old.t": attributeTimestamp*1000
            ] as NSDictionary)
        
    }
}
