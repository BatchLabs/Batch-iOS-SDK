//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import Foundation

class BAInstallDataEditorMock: BAInstallDataEditor {
    var setIdentifierCalled: Bool = false
    var identifierToSet: String?
    var saveCalled: Bool = false

    override init() {
        super.init()
        self.reset()
    }

    override func setIdentifier(_ identifier: String?) {
        setIdentifierCalled = true
        identifierToSet = identifier
    }

    override func save() {
        // Do nothing
        saveCalled = true
    }

    func reset() {
        setIdentifierCalled = false
        identifierToSet = nil
        saveCalled = false
    }
}
