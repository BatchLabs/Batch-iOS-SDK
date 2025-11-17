//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// A provider class that determines and instantiates the correct `UIViewController` for a given in-app message.
/// This is the main entry point for displaying a message from a push payload or a message object.
@objcMembers
public class InAppViewControllerProvider: NSObject {
    /// Custom error type for payload parsing failures.
    enum PayloadError: Error {
        case invalidPayload
    }

    /// Creates a view controller from a raw push notification payload.
    /// This is a convenience method that first parses the payload to extract the message data.
    /// - Parameter pushPayload: The push notification payload dictionary.
    /// - Returns: A fully configured `UIViewController` ready for presentation.
    /// - Throws: `PayloadError.invalidPayload` if the payload cannot be parsed into a valid message.
    public static func viewController(pushPayload: [String: Any]) throws -> UIViewController {
        guard let sourceMessage = BatchMessaging.message(fromPushPayload: pushPayload),
            let message = BAMSGPayloadParser.message(forCEPRawMessage: sourceMessage, bailIfNotAlert: false)
        else { throw PayloadError.invalidPayload }

        return try viewController(message: message)
    }

    /// Creates a view controller from a `BAMSGCEPMessage` object.
    /// This is the core logic that deserializes the message, builds the configuration, and selects the appropriate view controller subclass.
    /// - Parameter message: The parsed message object.
    /// - Returns: A fully configured `UIViewController` ready for presentation.
    /// - Throws: An error if JSON deserialization or message building fails.
    public static func viewController(message: BAMSGCEPMessage) throws -> UIViewController {
        // 1. Deserialize the raw JSON payload into the InAppMessage data model.
        let jsonData = try JSONSerialization.data(withJSONObject: message.sourceMessage.messagePayload)
        let inAppMessage = try JSONDecoder().decode(InAppMessage.self, from: jsonData)

        // 2. Use the builder to create the complete view controller configuration.
        let configuration = try InAppMessageBuilder.configuration(for: inAppMessage, message: message)

        // 3. Switch on the format and position to instantiate the correct UIViewController subclass.
        return switch inAppMessage.format {
        case .webview:
            // For webview format, create webview controller with configuration
            InAppWebviewViewController(configuration: configuration)
        case .modal, .fullscreen:
            switch (configuration.format, configuration.placement.position) {
            case (.modal, .center):  // A centered modal.
                InAppModalViewController(configuration: configuration)
            case (.modal, _):  // A modal that behaves like a banner (e.g., top or bottom of the screen).
                InAppBannerViewController(configuration: configuration)
            case (_, _):  // Any non-modal format is treated as fullscreen.
                InAppFullscreenViewController(configuration: configuration)
            }
        }
    }
}
