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
    public var test_isProfileIdentified = true

    override func isProfileIdentified() -> Bool {
        return test_isProfileIdentified
    }
}
