//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

/// Convinence initializer for the generated BatchProfileError that makes it less verbose
/// to add a description
extension BatchProfileError {
    init(code: BatchProfileError.Code, reason: String) {
        self.init(code, userInfo: [NSLocalizedDescriptionKey: reason])
    }
}
