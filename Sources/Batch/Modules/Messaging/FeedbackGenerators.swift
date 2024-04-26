//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

// Wrapper around UIImpactFeedbackGenerator that is safe to use on visionOS
@objc
@objcMembers
public class BATImpactFeedbackGenerator: NSObject {
    @objc(BATImpactFeedbackStyle)
    public enum FeedbackStyle: UInt {
        case light
        case medium
        case heavy
    }

    #if !os(visionOS)
        let feedbackGenerator: UIImpactFeedbackGenerator
    #endif

    public required init(style: FeedbackStyle) {
        #if !os(visionOS)
            let convertedStyle: UIImpactFeedbackGenerator.FeedbackStyle = switch style {
                case .light: UIImpactFeedbackGenerator.FeedbackStyle.light
                case .medium: UIImpactFeedbackGenerator.FeedbackStyle.medium
                case .heavy: UIImpactFeedbackGenerator.FeedbackStyle.heavy
            }
            self.feedbackGenerator = UIImpactFeedbackGenerator(style: convertedStyle)
        #endif
        super.init()
    }

    public func prepare() {
        #if !os(visionOS)
            self.feedbackGenerator.prepare()
        #endif
    }

    public func impactOccurred() {
        #if !os(visionOS)
            self.feedbackGenerator.impactOccurred()
        #endif
    }
}

// Wrapper around UINotificationFeedbackGenerator that is safe to use on visionOS
@objc
@objcMembers
public class BATNotificationFeedbackGenerator: NSObject {
    @objc(BATNotificationFeedbackType)
    public enum FeedbackType: UInt {
        case success
        case warning
        case error
    }

    #if !os(visionOS)
        let feedbackGenerator: UINotificationFeedbackGenerator
    #endif

    override public required init() {
        #if !os(visionOS)
            self.feedbackGenerator = UINotificationFeedbackGenerator()
        #endif
        super.init()
    }

    public func prepare() {
        #if !os(visionOS)
            self.feedbackGenerator.prepare()
        #endif
    }

    public func notificationOccurred(_ type: FeedbackType) {
        #if !os(visionOS)
            let convertedType: UINotificationFeedbackGenerator.FeedbackType = switch type {
                case .success: UINotificationFeedbackGenerator.FeedbackType.success
                case .warning: UINotificationFeedbackGenerator.FeedbackType.warning
                case .error: UINotificationFeedbackGenerator.FeedbackType.error
            }
            feedbackGenerator.notificationOccurred(convertedType)
        #endif
    }
}
