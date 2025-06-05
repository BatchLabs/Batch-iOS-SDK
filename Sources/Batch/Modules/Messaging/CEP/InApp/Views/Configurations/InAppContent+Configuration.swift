//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

public extension InAppContent {
    // MARK: - Structures

    struct Configuration {
        // MARK: - Parameters

        let urls: [String: String]
        let texts: [String: String]
        let child: CodableInAppRootContainer

        // MARK: - Initializer

        init(urls: [String: String], texts: [String: String], child: CodableInAppRootContainer) {
            self.urls = urls
            self.texts = texts
            self.child = child
        }
    }
}
