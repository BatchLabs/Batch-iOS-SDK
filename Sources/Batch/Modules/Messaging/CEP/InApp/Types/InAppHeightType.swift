//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Define the height logic than a component could use
public enum InAppHeightType: Equatable {
    // MARK: -

    public static let fixedKey = "px"
    public static let autoKey = "auto"

    case auto
    case fixed(value: Int)

    var value: Int? {
        return switch self {
            case .auto: nil
            case let .fixed(value): value
        }
    }

    // MARK: -

    init?(stringValue: String) {
        if stringValue.hasSuffix(Self.fixedKey), let value = Int(stringValue.dropLast(Self.fixedKey.count)) {
            self = .fixed(value: value)
        } else if stringValue == Self.autoKey {
            self = .auto
        } else {
            return nil
        }
    }
}
