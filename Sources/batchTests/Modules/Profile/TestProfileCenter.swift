//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch
import Foundation

@testable import Batch.Batch_Private

/// A test BATProfileEditor that has a controllable canSetEmail
class TestProfileCenter: BAProfileCenterProtocol {
    public var onProjectChangedHasBeenCalled = false

    func identify(_: String?) {}

    func trackPublicEvent(name _: String, attributes _: BatchEventAttributes?) throws {}

    func trackLocation(_: CLLocation) {}

    func validateEventAttributes(_: BatchEventAttributes) -> [String] {
        return []
    }

    func applyEditor(_: BATProfileEditor) {}

    func onProjectChanged(oldProjectKey _: String?, newProjectKey _: String?) {
        onProjectChangedHasBeenCalled = true
    }
}
