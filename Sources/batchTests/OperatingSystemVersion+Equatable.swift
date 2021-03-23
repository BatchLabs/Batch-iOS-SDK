//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

extension OperatingSystemVersion: Equatable {
    public static func == (lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool {
        return lhs.majorVersion == rhs.majorVersion &&
            lhs.minorVersion == rhs.minorVersion &&
            lhs.patchVersion == rhs.patchVersion
    }
}
