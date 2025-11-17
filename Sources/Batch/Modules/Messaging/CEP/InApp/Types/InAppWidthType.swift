//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Define the width logic than a component could use
public enum InAppWidthType: Equatable {
    // MARK: -

    public static let percentKey = "%"
    public static let autoKey = "auto"

    case auto
    case percent(value: Int)

    var value: Int? {
        return switch self {
        case .auto: nil
        case let .percent(value: value): value
        }
    }

    // MARK: -

    init?(stringValue: String) {
        if stringValue.hasSuffix(Self.percentKey), let value = Int(stringValue.dropLast(Self.percentKey.count)) {
            self = .percent(value: value)
        } else if stringValue == Self.autoKey {
            self = .auto
        } else {
            return nil
        }
    }
}
