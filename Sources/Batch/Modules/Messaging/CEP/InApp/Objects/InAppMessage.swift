//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app message
public struct InAppMessage: Codable {
    // MARK: -

    public let format: InAppFormat
    let minMLvl: Int
    let position: InAppVerticalAlignment
    let root: InAppRootContainer
    let closeOptions: InAppCloseOption
    let texts: [String: String]?
    let urls: [String: String]?
    let actions: [String: InAppAction]?
    let eventData: [String: String]?
    let trackingId: String?

    // MARK: -

    public init(format: InAppFormat, position: InAppVerticalAlignment, root: InAppRootContainer, closeOptions: InAppCloseOption, texts: [String: String], urls: [String: String], actions: [String: InAppAction], eventData: [String: String], trackingId: String?) {
        self.format = format
        self.position = position
        self.root = root
        self.closeOptions = closeOptions
        self.texts = texts
        self.urls = urls
        self.actions = actions
        self.eventData = eventData
        self.trackingId = trackingId
        self.minMLvl = 0
    }
}
