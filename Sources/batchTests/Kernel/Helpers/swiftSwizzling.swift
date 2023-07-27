//
//  swiftSwizzling.swift
//  BatchTests
//
//  Created by arnaud on 15/09/2020.
//  Copyright © 2020 Batch.com. All rights reserved.
//

import Foundation
import UIKit

@objc
class SwiftStubApplicationDelegate: NSObject, UIApplicationDelegate {
    @objc public var didFailToRegisterRecorded = false

    @objc
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {
        didFailToRegisterRecorded = true
    }
}
