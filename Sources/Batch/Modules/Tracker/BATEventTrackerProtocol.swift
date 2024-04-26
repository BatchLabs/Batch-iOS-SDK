//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

// Protocol that defines Batch's event tracker to facilitate dependency injection
// For now, this only handles private events
@objc(BATEventTrackerProtocol)
public protocol BATEventTracker {
    // Tracks a public event. Do not add "E." to the event name, the tracker will do it.
    @objc(trackPublicEvent:attributes:)
    func trackPublicEvent(name: String, attributes: BatchEventAttributes?)

    @objc(trackPrivateEvent:parameters:collapsable:)
    func trackPrivateEvent(name: String, parameters: [AnyHashable: Any]?, collapsable: Bool)

    @objc(trackManualPrivateEvent:)
    func trackManualPrivateEvent(_ event: BAEvent)

    @objc(trackLocation:)
    func trackLocation(_ location: CLLocation)
}

extension BATEventTracker {
    func trackPrivateEvent(event: BATInternalEvent, parameters: [AnyHashable: Any]?, collapsable: Bool) {
        trackPrivateEvent(name: event.rawValue, parameters: parameters, collapsable: collapsable)
    }
}
