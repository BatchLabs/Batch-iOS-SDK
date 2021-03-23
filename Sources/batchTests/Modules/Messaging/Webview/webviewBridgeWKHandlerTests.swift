//
//  webviewBridgeWKHandlerTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import XCTest
import Batch.Batch_Private

class webviewBridgeWKHandlerTests: XCTestCase {

    let controller = WKUserContentController()
    
    let handler = BATWebviewBridgeWKHandler(bridge: MinimalWebviewJavascriptBridge())
    
    func testArgumentValidation() {
        handler.userContentController(controller,
                                      didReceive: MockWKMessage(body: []),
                                      replyHandler: makeExpectErrorReplyHandler())
        
        handler.userContentController(controller,
                                      didReceive: MockWKMessage(body: "test"),
                                      replyHandler: makeExpectErrorReplyHandler())
        
        handler.userContentController(controller,
                                      didReceive: MockWKMessage(body: [:]),
                                      replyHandler: makeExpectErrorReplyHandler())
        
        handler.userContentController(controller,
                                      didReceive: MockWKMessage(body: ["method": 2]),
                                      replyHandler: makeExpectErrorReplyHandler())
        
        handler.userContentController(controller,
                                      didReceive: MockWKMessage(body: ["method": 2, "args": [:]]),
                                      replyHandler: makeExpectErrorReplyHandler())
        
        handler.userContentController(controller,
                                      didReceive: MockWKMessage(body: ["method": "success", "args": []]),
                                      replyHandler: makeExpectErrorReplyHandler())
        
        handler.userContentController(controller,
                                      didReceive: MockWKMessage(method: "success", args: [:]),
                                      replyHandler: makeExpectValueReplyHandler(expected: "ok"))
        
    }
    
    func testSuccess() {
        handler.userContentController(controller,
                                      didReceive: MockWKMessage(method: "success", args: [:]),
                                      replyHandler: makeExpectValueReplyHandler(expected: "ok"))
        
        handler.userContentController(controller,
                                      didReceive: MockWKMessage(method: "echo", args: ["value": "echoed_value"]),
                                      replyHandler: makeExpectValueReplyHandler(expected: "echoed_value"))
    }
    
    func testError() {
        handler.userContentController(controller,
                                      didReceive: MockWKMessage(method: "failure", args: [:]),
                                      replyHandler: makeExpectErrorReplyHandler())
    }
    
    func makeExpectValueReplyHandler<T>(expected: T?, file: StaticString = #filePath, line: UInt = #line) -> (Any?, String?) -> Void where T: Equatable {
        return { (value, error) in
            if let value = value as? T {
                XCTAssertEqual(expected, value, file: file, line: line)
            }
            XCTAssertNil(error, file: file, line: line)
        }
    }
    
    func makeExpectErrorReplyHandler(file: StaticString = #filePath, line: UInt = #line) -> (Any?, String?) -> Void {
        return { (value, error) in
            XCTAssertNil(value, file: file, line: line)
            XCTAssertNotNil(error, file: file, line: line)
        }
    }
}
