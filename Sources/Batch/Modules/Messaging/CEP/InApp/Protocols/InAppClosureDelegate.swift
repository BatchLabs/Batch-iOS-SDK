//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Generalize closure interactions
protocol InAppClosureDelegate {
    typealias Closure = (_ item: InAppCTAComponent?, _ error: Error?) -> Void

    var onClosureTap: Closure { get }
}
