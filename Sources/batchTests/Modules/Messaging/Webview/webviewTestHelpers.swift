//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import WebKit

class MinimalWebviewJavascriptBridge: BATWebviewJavascriptBridge {
    public let expectedErrorMessage = "test_error_message"

    override init() {
        super.init(message: BAMSGMessageWebView(), delegate: nil)
    }

    override func executeMethod(_ method: String?, arguments rawJSONArguments: [AnyHashable: Any]?) -> BAPromise<
        NSString
    > {
        switch method {
            case "success":
                return BAPromise.resolved("ok")
            case "failure":
                return BAPromise.rejected(
                    NSError(domain: "tests", code: 0, userInfo: [NSLocalizedDescriptionKey: expectedErrorMessage]))
            case "echo":
                return BAPromise.resolved((rawJSONArguments!["value"] as! NSString))
            case "echo_nil":
                return BAPromise.resolved(nil)
            default:
                return BAPromise.rejected(nil)
        }
    }
}

class MockWKMessage: WKScriptMessage {
    let mockBody: Any

    init(body: Any) {
        mockBody = body
        super.init()
    }

    init(method: String, args: [AnyHashable: Any]) {
        mockBody = [
            "method": method,
            "args": args,
        ]
        super.init()
    }

    override var body: Any {
        return mockBody
    }
}
