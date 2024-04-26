//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch
@testable import Batch.Batch_Private
import Foundation

/// A test BATProfileEditor that has a controllable canSetEmail
class TestProfileEditor: BATProfileEditor {
    public var test_canSetEmail = true

    override func canSetEmail() -> Bool {
        return test_canSetEmail
    }
}
