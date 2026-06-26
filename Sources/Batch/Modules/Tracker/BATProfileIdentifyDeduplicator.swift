//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

// Removes duplicate consecutive _PROFILE_IDENTIFY events carrying the same custom_id
// from an event batch. Non-identify events pass through unchanged and do not reset
// deduplication tracking, so two identify events with the same custom_id are always
// collapsed even when other event types appear between them.
@objc
public final class BATProfileIdentifyDeduplicator: NSObject {
    private override init() {}

    @objc
    public static func deduplicate(_ events: NSArray) -> NSArray {
        var result: [BAEvent] = []
        var hasSeenIdentify = false
        var lastCustomId: String?

        for case let event as BAEvent in events {
            if event.name == BATInternalEvent.profileIdentify.rawValue {
                let currentCustomId = extractCustomId(from: event.parameters)
                if hasSeenIdentify && currentCustomId == lastCustomId {
                    BALogger.debug(
                        domain: "ProfileIdentifyDeduplicator",
                        message: "Deduplicating consecutive _PROFILE_IDENTIFY event with custom_id: \(currentCustomId ?? "nil")"
                    )
                    continue
                }
                hasSeenIdentify = true
                lastCustomId = currentCustomId
            }
            result.append(event)
        }
        return result as NSArray
    }

    public static func extractCustomId(from parameters: String?) -> String? {
        if let parameters,
            let data = parameters.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let identifiers = json["identifiers"] as? [String: Any]
        {
            return identifiers["custom_id"] as? String
        }
        return nil
    }
}
