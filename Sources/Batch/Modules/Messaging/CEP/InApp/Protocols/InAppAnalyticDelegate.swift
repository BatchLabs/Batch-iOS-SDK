//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Generalize analytic interactions
protocol InAppAnalyticDelegate {
    typealias Trigger = (_ source: InAppAnalyticWrapper.Kind) -> Void

    var analyticTrigger: Trigger { get }
}
