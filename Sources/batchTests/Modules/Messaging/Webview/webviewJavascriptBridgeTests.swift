//
//  webviewJavascriptBridgeTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import XCTest
import InstantMock
import Batch.Batch_Private

class webviewJavascriptBridgeTests: XCTestCase {

    var promises = [BAPromise<NSString>]()
    
    override func setUp() {
        promises = []
    }
    
    func testExecuteMethod() {
        let bridge = BATWebviewJavascriptBridge()
        
        XCTAssertRejects(promises.push(bridge.executeMethod(nil, arguments: [:])))
        XCTAssertRejects(promises.push(bridge.executeMethod("dismiss", arguments: nil)))
        XCTAssertRejects(promises.push(bridge.executeMethod(nil, arguments: nil)))
        
        XCTAssertRejects(promises.push(bridge.executeMethod("unknown_method", arguments: [:])))
        
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("dismiss", arguments: [:])))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("DisMISS", arguments: [:])))
        
        XCTAssertNoPendingPromise(promises)
    }
    
    func testExpectedResults() {
        let bridge = MockBridge()
        func executeDataMethod(_ method: String) -> BAPromise<NSString> {
            return promises.push(bridge.executeMethod(method, arguments: [:]))
        }
     
        XCTAssertResolves(BridgeExpectations.installationID, executeDataMethod("getInstallationID"))
        XCTAssertResolves(BridgeExpectations.customLanguage, executeDataMethod("getCustomLanguage"))
        XCTAssertResolves(BridgeExpectations.customRegion, executeDataMethod("getCustomRegion"))
        XCTAssertResolves(BridgeExpectations.customUserID, executeDataMethod("getCustomUserID"))
        
        bridge.shouldReturnCustomDatas = false
        
        XCTAssertResolves(nil, executeDataMethod("getCustomLanguage"))
        XCTAssertResolves(nil, executeDataMethod("getCustomRegion"))
        XCTAssertResolves(nil, executeDataMethod("getCustomUserID"))
        
        XCTAssertResolves(BridgeExpectations.attributionID as NSString, executeDataMethod("getAttributionID"))
        bridge.shouldReturnAttributionID = false
        XCTAssertRejects(executeDataMethod("getAttributionID"))
        
        XCTAssertNoPendingPromise(promises)
    }
    
    func testTrackingID() {
        var bridge = MockBridge(trackingID: BridgeExpectations.trackingID)
        
        XCTAssertResolves(BridgeExpectations.trackingID as NSString, promises.push(bridge.executeMethod("getTrackingID", arguments: [:])))
        
        bridge = MockBridge(trackingID: nil)
        XCTAssertResolves(nil, promises.push(bridge.executeMethod("getTrackingID", arguments: [:])))
        
        XCTAssertNoPendingPromise(promises)
    }
    
    func testOpenDeeplink() {
        let delegate = MockBridgeDelegate()
        let bridge = MockBridge(trackingID: nil, delegate: delegate)
        
        let batchURL = "https://batch.com"
        
        delegate.expect().call(
            delegate.bridge(Arg.eq(bridge), shouldOpenDeeplink: Arg.eq(batchURL), openInAppOverride: Arg.eq(nil), analyticsID: Arg.eq(nil))
        )
        delegate.expect().call(
            delegate.bridge(Arg.eq(bridge), shouldOpenDeeplink: Arg.eq(batchURL), openInAppOverride: Arg.eq(NSNumber?(false)), analyticsID: Arg.eq(nil))
        )
        // 2nd is the bad analyticsID type
        delegate.expect().call(
            delegate.bridge(Arg.eq(bridge), shouldOpenDeeplink: Arg.eq(batchURL), openInAppOverride: Arg.eq(NSNumber?(true)), analyticsID: Arg.eq(nil)),
            count: 3
        )
        delegate.expect().call(
            delegate.bridge(Arg.eq(bridge),
                            shouldOpenDeeplink: Arg.eq(batchURL),
                            openInAppOverride: Arg.eq(NSNumber?(true)),
                            analyticsID: Arg.eq(BridgeExpectations.analyticsID as String?))
        )
        
        XCTAssertRejects(promises.push(bridge.executeMethod("openDeeplink", arguments: [:])))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("openDeeplink", arguments:
                                                                    [ "url" : batchURL ]
        )))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("openDeeplink", arguments:
                                                                    [
                                                                        "url" : batchURL,
                                                                        "openInApp": false
                                                                    ]
        )))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("openDeeplink", arguments:
                                                                    [
                                                                        "url" : batchURL,
                                                                        "openInApp": true
                                                                    ]
        )))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("openDeeplink", arguments:
                                                                    [
                                                                        "url" : batchURL,
                                                                        "openInApp": true,
                                                                        "analyticsID": 2
                                                                    ]
        )))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("openDeeplink", arguments:
                                                                    [
                                                                        "url" : batchURL,
                                                                        "openInApp": true,
                                                                        "analyticsID": NSNull()
                                                                    ]
        )))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("openDeeplink", arguments:
                                                                    [
                                                                        "url" : batchURL,
                                                                        "openInApp": true,
                                                                        "analyticsID": BridgeExpectations.analyticsID
                                                                    ]
        )))
        
        XCTAssertNoPendingPromise(promises)
        delegate.verify()
    }
    
    func testDismiss() {
        let delegate = MockBridgeDelegate()
        let bridge = MockBridge(trackingID: nil, delegate: delegate)
        
        // 2nd is the bad analyticsID type
        delegate.expect().call(
            delegate.bridge(Arg.eq(bridge), shouldDismissMessageWithAnalyticsID: Arg.eq(nil)),
            count: 2
        )
        delegate.expect().call(
            delegate.bridge(Arg.eq(bridge), shouldDismissMessageWithAnalyticsID: Arg.eq(BridgeExpectations.analyticsID as String?))
        )
        
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("dismiss", arguments: [:])))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("dismiss", arguments:
                                                                    [
                                                                        "analyticsID": 2
                                                                    ]
        )))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("dismiss", arguments:
                                                                    [
                                                                        "analyticsID": BridgeExpectations.analyticsID
                                                                    ]
        )))
        
        XCTAssertNoPendingPromise(promises)
        delegate.verify()
    }
    
    func testPerformAction() {
        let delegate = MockBridgeDelegate()
        let bridge = MockBridge(trackingID: nil, delegate: delegate)
        
        delegate.expect().call(
            delegate.bridge(Arg.eq(bridge),
                            shouldPerformAction: Arg.eq("batch.test"),
                            arguments: Arg.eq([:]),
                            analyticsID: Arg.eq(nil))
        )
        
        delegate.expect().call(
            delegate.bridge(Arg.eq(bridge),
                            shouldPerformAction: Arg.eq("batch.test"),
                            arguments: Arg.eq(["arg1":"value"]),
                            analyticsID: Arg.eq(nil)),
            count: 2
        )
        
        delegate.expect().call(
            delegate.bridge(Arg.eq(bridge),
                            shouldPerformAction: Arg.eq("batch.test"),
                            arguments: Arg.eq(["arg1":"value"]),
                            analyticsID: Arg.eq(" "))
        )
        
        delegate.expect().call(
            delegate.bridge(Arg.eq(bridge),
                            shouldPerformAction: Arg.eq("batch.test"),
                            arguments: Arg.eq(["arg1":"value"]),
                            analyticsID: Arg.eq(BridgeExpectations.analyticsID as String?))
        )
        
        XCTAssertRejects(promises.push(bridge.executeMethod("performAction", arguments: [:])))
        XCTAssertRejects(promises.push(bridge.executeMethod("performAction", arguments: ["invalid":"payload"])))
        
        XCTAssertRejects(promises.push(bridge.executeMethod("performAction", arguments: [
                                                                "name": "batch.test",
                                                                "args": []
                                                            ]
        )))
        

        XCTAssertResolves("ok", promises.push(bridge.executeMethod("performAction", arguments: [
                                                                        "name": "batch.test",
                                                                        "args": [:]
                                                                    ]
        )))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("performAction", arguments: [
                                                                        "name": "batch.test",
                                                                        "args": [
                                                                            "arg1": "value"
                                                                        ]
                                                                    ]
        )))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("performAction", arguments: [
                                                                        "name": "batch.test",
                                                                        "args": [
                                                                            "arg1": "value"
                                                                        ],
                                                                        "analyticsID": 2
                                                                    ]
        )))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("performAction", arguments: [
                                                                        "name": "batch.test",
                                                                        "args": [
                                                                            "arg1": "value"
                                                                        ],
                                                                        "analyticsID": " "
                                                                    ]
        )))
        XCTAssertResolves("ok", promises.push(bridge.executeMethod("performAction", arguments: [
                                                                        "name": "batch.test",
                                                                        "args": [
                                                                            "arg1": "value"
                                                                        ],
                                                                        "analyticsID": BridgeExpectations.analyticsID
                                                                    ]
        )))
        
        XCTAssertNoPendingPromise(promises)
        delegate.verify()
    }
}

fileprivate struct BridgeExpectations {
    static let installationID: NSString = "install"
    static let customLanguage: NSString = "xx"
    static let customRegion: NSString = "XX"
    static let customUserID: NSString = "customid"
    static let attributionID = "abcdef-ghijkl"
    static let trackingID = "tracking_test"
    
    static let analyticsID = "test_analytics"
}

fileprivate class MockBridgeDelegate: Mock, BATWebviewJavascriptBridgeDelegate {
    
    func bridge(_ bridge: BATWebviewJavascriptBridge, shouldDismissMessageWithAnalyticsID analyticsIdentifier: String?) {
        super.call(bridge, analyticsIdentifier)
    }
    
    func bridge(_ bridge: BATWebviewJavascriptBridge, shouldOpenDeeplink url: String, openInAppOverride: NSNumber?, analyticsID analyticsIdentifier: String?) {
        super.call(bridge, url, openInAppOverride, analyticsIdentifier)
    }
    
    func bridge(_ bridge: BATWebviewJavascriptBridge, shouldPerformAction action: String, arguments: [String : Any], analyticsID analyticsIdentifier: String?) {
        super.call(bridge, action, arguments, analyticsIdentifier)
    }
    
}

fileprivate class MockBridge: BATWebviewJavascriptBridge {
    
    var shouldReturnCustomDatas = true
    var shouldReturnAttributionID = true
    
    init(trackingID: String? = nil, delegate: BATWebviewJavascriptBridgeDelegate? = nil) {
        let message = BAMSGMessageWebView()
        message.sourceMessage = MockBatchMessage(devTrackingIdentifier: trackingID)
        super.init(message: message, delegate: delegate)
    }
    
    override func installationID() -> BAPromise<NSString> {
        return BAPromise.resolved(BridgeExpectations.installationID)
    }
    
    override func readAttributionIDFromSDK() -> String? {
        if shouldReturnAttributionID {
            return BridgeExpectations.attributionID
        }
        return nil
    }
    
    override func customRegion() -> BAPromise<NSString> {
        if !shouldReturnCustomDatas {
            return BAPromise.resolved(nil)
        }
        return BAPromise.resolved(BridgeExpectations.customRegion)
    }
    
    override func customLanguage() -> BAPromise<NSString> {
        if !shouldReturnCustomDatas {
            return BAPromise.resolved(nil)
        }
        return BAPromise.resolved(BridgeExpectations.customLanguage)
    }
    
    override func customUserID() -> BAPromise<NSString> {
        if !shouldReturnCustomDatas {
            return BAPromise.resolved(nil)
        }
        return BAPromise.resolved(BridgeExpectations.customUserID)
    }
    
}

fileprivate class MockBatchMessage: BatchMessage {
    init(devTrackingIdentifier: String?) {
        super.init()
        self.devTrackingIdentifier = devTrackingIdentifier
    }
}
