//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

// Provide the good view controller according the format and the position
@objcMembers
public class InAppViewControllerProvider: NSObject {
    enum PayloadError: Error {
        case invalidPayload
    }

    public static func viewController(pushPayload: [String: Any]) throws -> UIViewController {
        guard let sourceMessage = BatchMessaging.message(fromPushPayload: pushPayload),
              let message = BAMSGPayloadParser.message(forCEPRawMessage: sourceMessage, bailIfNotAlert: false)
        else { throw PayloadError.invalidPayload }

        return try viewController(message: message)
    }

    public static func viewController(message: BAMSGCEPMessage) throws -> UIViewController {
        let jsonData = try JSONSerialization.data(withJSONObject: message.sourceMessage.messagePayload)
        let inAppMessage = try JSONDecoder().decode(InAppMessage.self, from: jsonData)

        let configuration = try InAppMessageBuilder.configuration(for: inAppMessage)
        return switch (configuration.style.isModal, configuration.placement.position) {
            case (true, .center): InAppModalViewController(configuration: configuration, message: message)
            case (true, _): InAppBannerViewController(configuration: configuration, message: message)
            case (_, _): InAppFullscreenViewController(configuration: configuration, message: message)
        }
    }
}
