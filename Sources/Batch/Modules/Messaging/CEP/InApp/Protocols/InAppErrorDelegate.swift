//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Generalize error interactions
protocol InAppErrorDelegate {
    typealias Closure = (_ error: any Error, _ component: InAppComponent) -> Void

    var onError: Closure { get }
}
