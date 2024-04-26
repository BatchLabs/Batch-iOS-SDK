//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import XCTest

/// XCTestCase extension to handle BAInjection lifetimes
extension XCTestCase {
    /// Extends an BAOverlayedInjectable lifetime so that it is not deallocated instantly.
    /// Meant to be used in a defer {} for async tests
    /// Use:
    /// ```swift
    ///  class MyTest: XCTestCase {
    ///      func test() async {
    ///          let injectable = BAInjection.overlayxxxx
    ///          defer { removeOverlay(injectable) }
    ///          await runMyTest
    ///      }
    ///  }
    /// ```
    func removeOverlay(_ injectable: BAOverlayedInjectable) {
        // This method doesn't need to do anything. The mere fact that the variable
        // is retained to call this method in a defer prevents it from being
        // deallocated
        withExtendedLifetime(injectable) {}
    }
}
