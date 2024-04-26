//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import Foundation

@objc
class MockEventTracker: NSObject, BATEventTracker {
    var trackedEvents: [BAEvent] = []

    func trackPublicEvent(name: String, attributes: BatchEventAttributes?) {
        var parameters = [AnyHashable: Any]()
        if let attributes {
            parameters = try! BATEventAttributesSerializer.serialize(eventAttributes: attributes)
        }
        trackPrivateEvent(name: "E.\(name.uppercased())", parameters: parameters, collapsable: false)
    }

    func trackLocation(_: CLLocation) {
        // TODO: Implement this
    }

    func trackPrivateEvent(name: String, parameters: [AnyHashable: Any]?, collapsable _: Bool) {
        trackedEvents.append(BAEvent(name: name, andParameters: parameters))
    }

    func trackManualPrivateEvent(_ event: BAEvent) {
        trackedEvents.append(event)
    }

    @objc
    func reset() {
        trackedEvents.removeAll()
    }

    // Find an event by its name and parameters
    // If `parameters` is nil, all events of this name will be matched.
    // To match events without parameters, provide an empty dictionary
    func findEvent(name: BATInternalEvent, parameters: [AnyHashable: Any]?) -> BAEvent? {
        return findEvent(name: name.rawValue, parameters: parameters)
    }

    // Find an event by its name and parameters
    // If `parameters` is nil, all events of this name will be matched.
    // To match events without parameters, provide an empty dictionary
    @objc
    func findEvent(name: String, parameters: [AnyHashable: Any]?) -> BAEvent? {
        return trackedEvents.filter { event in
            if event.name != name {
                return false
            }

            if let parameters {
                let eventParameters = (event.parametersDictionary ?? [:]) as NSDictionary
                if !eventParameters.isEqual(to: parameters) {
                    return false
                }
            }

            return true
        }.first
    }

    @objc
    func registerOverlay() -> BAOverlayedInjectable {
        return BAInjection.overlayProtocol(BATEventTracker.self, returnedInstance: self)
    }
}
