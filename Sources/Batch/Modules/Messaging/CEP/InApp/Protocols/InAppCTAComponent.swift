//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Generalize CTA component
protocol InAppCTAComponent {
    var analyticsIdentifier: String { get }
    var action: BAMSGAction? { get }
    var type: InAppCTAType { get }
}
