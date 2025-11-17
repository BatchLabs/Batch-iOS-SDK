//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Handle all in app analytic interactions to avoid to enforce all UI components to internally implement it
struct InAppAnalyticWrapper {
    // MARK: -

    enum Kind {
        case automaticallyClosed
        case shown
        case dismissed
        case closed
        case cta(component: InAppCTAComponent)
        case webView(component: InAppCTAComponent)
        case closeError(_ error: BATMessagingCloseErrorCause)
    }

    // MARK: -

    private let message: BAMSGCEPMessage
    let analyticsDelegate: BAMessagingAnalyticsDelegate?

    // MARK: -

    init(message: BAMSGCEPMessage) {
        self.analyticsDelegate = BAInjection.inject(BAMessagingAnalyticsDelegate.self)
        self.message = message
    }

    // MARK: -

    func track(_ source: Kind) {
        switch source {
        case .automaticallyClosed:
            analyticsDelegate?.messageAutomaticallyClosed(message)
        case .closed:
            analyticsDelegate?.messageClosed(message)
        case .dismissed:
            analyticsDelegate?.messageDismissed(message)
        case .shown:
            analyticsDelegate?.messageShown(message)
        case let .cta(component):
            guard let action = component.action else { return }

            analyticsDelegate?.messageButtonClicked(message, ctaIdentifier: component.analyticsIdentifier, ctaType: component.type.rawValue, action: action)
        case let .webView(component):
            guard let action = component.action else { return }

            analyticsDelegate?.messageWebViewClickTracked(message, action: action, analyticsIdentifier: component.analyticsIdentifier)
        case let .closeError(error):
            analyticsDelegate?.messageClosed(message, byError: error)
        }
    }
}
