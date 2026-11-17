//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Testing

@testable import Batch

// `.serialized` is the repository default: suites touching shared SDK state or `BAInjection`
// overlays clobber each other when they run in parallel.
@Suite(.serialized)
struct ___FILEBASENAMEASIDENTIFIER___ {

    @Test func example() throws {
        // Write the test here and check expectations with `#expect(…)` / `#require(…)`.
        // Mark the test `async` to await asynchronous work, and `throws` to fail on an uncaught error.
    }

}
