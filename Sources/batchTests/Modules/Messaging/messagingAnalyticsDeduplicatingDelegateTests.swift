import Batch.Batch_Private
import Foundation
import XCTest

class messagingAnalyticsDeduplicatingDelegateTests: XCTestCase {
    func testDeduplicate() {
        let wrappedDelegate = TestMessagingAnalyticsDelegate()
        let deduplicateDelegate = BAMessagingAnalyticsDeduplicatingDelegate(wrappedDelegate: wrappedDelegate)

        let message = BAMSGMEPMessage()

        let trackMethods: () -> Void = {
            deduplicateDelegate.messageShown(message)
            deduplicateDelegate.messageClosed(message)
            deduplicateDelegate.messageClosed(message, byError: .serverFailure)
            deduplicateDelegate.messageDismissed(message)
            deduplicateDelegate.messageButtonClicked(message, ctaIdentifier: "0", action: BAMSGCTA())
            deduplicateDelegate.messageAutomaticallyClosed(message)
            deduplicateDelegate.messageGlobalTapActionTriggered(message, action: BAMSGAction())
            deduplicateDelegate.messageWebViewClickTracked(
                message, action: BAMSGAction(), analyticsIdentifier: "foobar"
            )
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
    var withLoadingImageErrorCalled = false
    var dismissedCalled = false
    var buttonClickedCalled = false
    var autoCloseCalled = false
    var globalTapCalled = false
    var timesWebviewClickCalled = 0
    var lastErrorCause: BATMessagingCloseErrorCause?

    func messageShown(_: BAMSGMessage) {
        if shownCalled {
            fail()
        }
        shownCalled = true
    }

    func messageClosed(_: BAMSGMessage) {
        if closedCalled {
            fail()
        }
        closedCalled = true
    }

    func messageClosed(_: BAMSGMessage, byError: BATMessagingCloseErrorCause) {
        if closedByErrorCalled {
            fail()
        }
        closedByErrorCalled = true
        lastErrorCause = byError
    }

    func messageDismissed(_: BAMSGMessage) {
        if dismissedCalled {
            fail()
        }
        dismissedCalled = true
    }

    func messageButtonClicked(_: BAMSGMessage, ctaIdentifier _: String, action _: BAMSGCTA) {
        if buttonClickedCalled {
            fail()
        }
        buttonClickedCalled = true
    }

    func messageButtonClicked(_: BAMSGMessage, ctaIdentifier _: String, ctaType _: String, action _: BAMSGAction) {
        if buttonClickedCalled {
            fail()
        }
        buttonClickedCalled = true
    }

    func messageAutomaticallyClosed(_: BAMSGMessage) {
        if autoCloseCalled {
            fail()
        }
        autoCloseCalled = true
    }

    func messageGlobalTapActionTriggered(_: BAMSGMessage, action _: BAMSGAction) {
        if globalTapCalled {
            fail()
        }
        globalTapCalled = true
    }

    func messageWebViewClickTracked(
        _: BAMSGMessage, action _: BAMSGAction, analyticsIdentifier _: String
    ) {
        timesWebviewClickCalled = timesWebviewClickCalled + 1
    }

    func fail(method: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        XCTFail("Method called twice: \(method) - \(file) at line \(line)")
    }
}
