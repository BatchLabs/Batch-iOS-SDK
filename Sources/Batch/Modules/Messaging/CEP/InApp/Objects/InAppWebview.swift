//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app webview component
public struct InAppWebview: Codable, Identifiable, InAppTypedComponent {
    // MARK: -

    public let id: String
    public let type: InAppComponent
    public let inAppDeeplinks: Bool
    public let devMode: Bool
    public let timeout: TimeInterval

    // MARK: -

    public init(id: String, inAppDeeplink: Bool, devMode: Bool, timeout: TimeInterval) {
        self.id = id
        self.type = .webview
        self.inAppDeeplinks = inAppDeeplink
        self.devMode = devMode
        self.timeout = timeout
    }
}
