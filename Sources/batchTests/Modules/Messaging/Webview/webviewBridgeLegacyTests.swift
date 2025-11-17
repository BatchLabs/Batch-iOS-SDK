//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import InstantMock
import WebKit
import XCTest

class webviewBridgeLegacyTests: XCTestCase, BATWebviewBridgeLegacyWKHandlerWebViewSource {
    fileprivate let webViewMock = MockWKWebView()
    let contentController = WKUserContentController()
    var bridge: MinimalWebviewJavascriptBridge!
    var handler: BATWebviewBridgeLegacyWKHandler!

    override func setUp() {
        webViewMock.it.resetExpectations()
        bridge = MinimalWebviewJavascriptBridge()
        handler = BATWebviewBridgeLegacyWKHandler(bridge: bridge, webViewProvider: self)
    }

    func testTaskIDParsing() {
        // Unfortunately, a bad task ID doesn't do anything
        // Just test that we don't crash
        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": "2",
                "method": "success",
                "args": [:],
            ])
        )

        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": NSNull(),
                "method": "success",
                "args": [:],
            ])
        )

        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": nil,
                "method": "success",
                "args": [:],
            ])
        )

        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": [],
                "method": "success",
                "args": [:],
            ])
        )

        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": true,
                "method": "success",
                "args": [:],
            ])
        )

        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": 2,
                "method": "success",
                "args": [:],
            ])
        )

        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": -2,
                "method": "success",
                "args": [:],
            ])
        )
    }

    func testJavascriptCallbackEvaluation() {
        var taskID = 24

        webViewMock.it.expect()
            .call(
                webViewMock.evaluateJavaScript(
                    Arg.eq(makeJSEvalExpectationForSuccess(expected: "ok", taskID: taskID)),
                    completionHandler: Arg.closure()
                )
            )

        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": taskID,
                "method": "success",
                "args": [:],
            ])
        )

        taskID = 25

        webViewMock.it.expect()
            .call(
                webViewMock.evaluateJavaScript(
                    Arg.eq(makeJSEvalExpectationForSuccess(expected: "test_value", taskID: taskID)),
                    completionHandler: Arg.closure()
                )
            )

        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": taskID,
                "method": "echo",
                "args": ["value": "test_value"],
            ])
        )

        taskID = 26

        webViewMock.it.expect()
            .call(
                webViewMock.evaluateJavaScript(
                    Arg.eq(makeJSEvalExpectationForSuccess(expected: nil, taskID: taskID)),
                    completionHandler: Arg.closure()
                )
            )

        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": taskID,
                "method": "echo_nil",
                "args": [:],
            ])
        )

        taskID = 30

        webViewMock.it.expect()
            .call(
                webViewMock.evaluateJavaScript(
                    Arg.eq(makeJSEvalExpectationForError(expected: bridge.expectedErrorMessage, taskID: taskID)),
                    completionHandler: Arg.closure()
                )
            )

        handler.userContentController(
            contentController,
            didReceive: MockWKMessage(body: [
                "taskID": taskID,
                "method": "failure",
                "args": [:],
            ])
        )

        webViewMock.it.verify()
    }

    func makeJSEvalExpectationForSuccess(expected result: String?, taskID: Int) -> String {
        var expectedResponse = "{}"
        if let result {
            expectedResponse = """
                {\"result\":\"\(result)\"}
                """
        }
        return """
            window.batchInAppSDK.__onWebkitCallback(\(taskID), \(expectedResponse));
            """
    }

    func makeJSEvalExpectationForError(expected error: String, taskID: Int) -> String {
        return """
            window.batchInAppSDK.__onWebkitCallback(\(taskID), {\"error\":\"\(error)\"});
            """
    }

    func backingWebView(forLegacyHandler _: BATWebviewBridgeLegacyWKHandler) -> WKWebView? {
        return webViewMock
    }
}

private class MockWKWebView: WKWebView, MockDelegate {
    private let mock = Mock()

    var it: Mock {
        return mock
    }

    #if compiler(>=6.0)
        override func evaluateJavaScript(_ javaScriptString: String, completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)? = nil) {
            mock.call(javaScriptString, completionHandler)
        }
    #else
        override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
            mock.call(javaScriptString, completionHandler)
        }
    #endif
}
