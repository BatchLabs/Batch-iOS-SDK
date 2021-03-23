import Foundation
import XCTest
import Batch.Batch_Private

class messagingAnalyticsDeduplicatingDelegateTests: XCTestCase {
    func testDeduplicate() {
        let wrappedDelegate = TestMessagingAnalyticsDelegate()
        let deduplicateDelegate = BAMessagingAnalyticsDeduplicatingDelegate(wrappedDelegate: wrappedDelegate)
        
        let message = BAMSGMessage()
        
        let trackMethods: () -> Void = {
            deduplicateDelegate.messageShown(message)
            deduplicateDelegate.messageClosed(message)
            deduplicateDelegate.messageClosed(message, byError: .serverFailure)
            deduplicateDelegate.messageDismissed(message)
            deduplicateDelegate.messageButtonClicked(message, ctaIndex: 0, action: BAMSGCTA())
            deduplicateDelegate.messageAutomaticallyClosed(message)
            deduplicateDelegate.messageGlobalTapActionTriggered(message, action: BAMSGAction())
            deduplicateDelegate.messageWebViewClickTracked(message, action: BAMSGAction(), analyticsIdentifier: "foobar")
        }
        
        trackMethods()
        trackMethods()
        trackMethods()
        
        XCTAssertEqual(wrappedDelegate.timesWebviewClickCalled, 3)
        XCTAssertEqual(wrappedDelegate.lastErrorCause, .serverFailure)
    }
}

// Test analytics delegate that fails the test when any method is called twice
class TestMessagingAnalyticsDelegate: BAMessagingAnalyticsDelegate {
    
    var shownCalled = false
    var closedCalled = false
    var closedByErrorCalled = false
    var dismissedCalled = false
    var buttonClickedCalled = false
    var autoCloseCalled = false
    var globalTapCalled = false
    var timesWebviewClickCalled = 0
    var lastErrorCause: BATMessagingCloseErrorCause? = nil
    
    func messageShown(_ message: BAMSGMessage) {
        if (shownCalled) {
            fail()
        }
        shownCalled = true
    }
    
    func messageClosed(_ message: BAMSGMessage) {
        if (closedCalled) {
            fail()
        }
        closedCalled = true
    }
    
    func messageClosed(_ message: BAMSGMessage, byError: BATMessagingCloseErrorCause) {
        if (closedByErrorCalled) {
            fail()
        }
        closedByErrorCalled = true
        lastErrorCause = byError
    }
    
    func messageDismissed(_ message: BAMSGMessage) {
        if (dismissedCalled) {
            fail()
        }
        dismissedCalled = true
    }
    
    func messageButtonClicked(_ message: BAMSGMessage, ctaIndex: Int, action: BAMSGCTA) {
        if (buttonClickedCalled) {
            fail()
        }
        buttonClickedCalled = true
    }
    
    func messageAutomaticallyClosed(_ message: BAMSGMessage) {
        if (autoCloseCalled) {
            fail()
        }
        autoCloseCalled = true
    }
    
    func messageGlobalTapActionTriggered(_ message: BAMSGMessage, action: BAMSGAction) {
        if (globalTapCalled) {
            fail()
        }
        globalTapCalled = true
    }
    
    func messageWebViewClickTracked(_ message: BAMSGMessage, action: BAMSGAction, analyticsIdentifier analyticsID: String) {
        timesWebviewClickCalled = timesWebviewClickCalled + 1
    }
    
    func fail(method: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        XCTFail("Method called twice: \(method) - \(file) at line \(line)")
    }
}
