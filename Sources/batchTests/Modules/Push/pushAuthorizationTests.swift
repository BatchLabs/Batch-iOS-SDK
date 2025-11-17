//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import XCTest

@testable import Batch

final class pushAuthorizationTests: XCTestCase {
    func testRegister() async throws {
        let pushSystemHelper = MockPushSystemHelper()
        let _ = BAInjection.overlayProtocol(BAPushSystemHelperProtocol.self, returnedInstance: pushSystemHelper)

        var result = try await BatchPush.requestNotificationAuthorization()
        XCTAssertTrue(result)
        result = try await BatchPush.requestProvisionalNotificationAuthorization()
        XCTAssertFalse(result)
    }

    func testRegisterSync() {
        let pushSystemHelper = MockPushSystemHelper()
        let _ = BAInjection.overlayProtocol(BAPushSystemHelperProtocol.self, returnedInstance: pushSystemHelper)

        BatchPush.requestNotificationAuthorization()
        XCTAssertTrue(pushSystemHelper.calledRegister)
        XCTAssertFalse(pushSystemHelper.calledProvisionalRegister)

        pushSystemHelper.reset()
        BatchPush.requestProvisionalNotificationAuthorization()
        XCTAssertFalse(pushSystemHelper.calledRegister)
        XCTAssertTrue(pushSystemHelper.calledProvisionalRegister)
    }
}

@objc
private class MockPushSystemHelper: NSObject, BAPushSystemHelperProtocol {
    public var calledRegister = false
    public var calledProvisionalRegister = false

    func register(forRemoteNotificationsTypes _: BatchNotificationType, providesNotificationSettings _: Bool, completionHandler: ((Bool, (any Error)?) -> Void)!) {
        calledRegister = true
        if let completionHandler {
            completionHandler(true, nil)
        }
    }

    func register(forProvisionalNotifications _: BatchNotificationType, providesNotificationSettings _: Bool, completionHandler: ((Bool, (any Error)?) -> Void)!) {
        calledProvisionalRegister = true
        if let completionHandler {
            completionHandler(false, nil)
        }
    }

    func reset() {
        calledRegister = false
        calledProvisionalRegister = false
    }
}
