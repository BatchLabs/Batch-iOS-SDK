//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

// MARK: - WebviewCTAComponent

struct WebviewCTAComponent: InAppCTAComponent {
    let analyticsIdentifier: String
    let action: BAMSGAction?
    let type: InAppCTAType = .webview
}
