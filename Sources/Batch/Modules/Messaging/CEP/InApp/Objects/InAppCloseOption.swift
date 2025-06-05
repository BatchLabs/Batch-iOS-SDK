//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app close option
/// Could be a delay, a cross button or both
public struct InAppCloseOption: Codable {
    // MARK: -

    let auto: InAppCloseOptionDelay?
    let button: InAppCloseOptionCross?

    // MARK: -

    public init(auto: InAppCloseOptionDelay?, button: InAppCloseOptionCross?) {
        self.auto = auto
        self.button = button
    }
}
