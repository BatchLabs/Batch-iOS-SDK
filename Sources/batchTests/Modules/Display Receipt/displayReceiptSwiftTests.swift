//
//  displayReceiptSwiftTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation
import XCTest
@testable import Batch
//@testable import BatchExtension

class DisplayReceiptSwiftTests: XCTestCase {
    
    /*
    func testPackSwiftUnpackObjC() throws
    {
        let od: [AnyHashable: Any] = [
            "sef": "toto", "bool": true, "hip": "hop"
        ]
        
        let ed: [AnyHashable: Any] = [
            "i": "test-i", "ex": "test-ex", "va": "test-va"
        ]
       
        let validPayload: [AnyHashable: Any] = [
            "com.batch": ["r":["m":1], "od": od, "i": "test-i", "ex": "test-ex", "va": "test-va"]
        ]
       
        // We create and pack a receipt using the Swift lib
        let receipt = try! DisplayReceiptHelper().displayReceipt(fromPayload: validPayload)
        XCTAssertFalse(receipt.replay)
        XCTAssertEqual(receipt.sendAttempt, 0)
        XCTAssert(NSDictionary(dictionary: od).isEqual(to: receipt.od!));
        XCTAssert(NSDictionary(dictionary: ed).isEqual(to: receipt.ed!));
        
        let packedData = try receipt.pack()
        XCTAssertNotNil(packedData);
        
        // We try to read and unpack it using the ObjC lib
        let objcReceipt = try? BADisplayReceipt.unpack(packedData)
        XCTAssertNotNil(objcReceipt!)
        XCTAssertFalse(objcReceipt!.replay)
        XCTAssertEqual(objcReceipt!.sendAttempt, 0)
        XCTAssert(NSDictionary(dictionary: od).isEqual(to: objcReceipt!.od!));
        XCTAssert(NSDictionary(dictionary: ed).isEqual(to: objcReceipt!.ed!));
    }
    */
    
}
