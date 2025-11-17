//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

/// Defines the vertical sizing behavior that a component can adopt.
public enum InAppHeightType: Equatable {
    // MARK: - String Constants for Raw Values

    public static let fixedKey = "px"
    public static let autoKey = "auto"
    public static let fillKey = "fill"

    // MARK: - Cases

    /// The height is determined by the component's intrinsic content size.
    case auto

    /// The component expands to fill any remaining vertical space in its container.
    case fill

    /// The height is a fixed value in pixels.
    case fixed(value: Int)

    /// The integer value for a fixed height, or nil for dynamic heights.
    var value: Int? {
        switch self {
        case .auto, .fill: return nil
        case let .fixed(value): return value
        }
    }

    /// The raw string representation of the height type, used for serialization.
    var rawValue: String {
        switch self {
        case .auto: return Self.autoKey
        case .fill: return Self.fillKey
        case let .fixed(value): return "\(value)\(Self.fixedKey)"
        }
    }

    // MARK: - Initializer

    /// Initializes an `InAppHeightType` from its raw string value.
    /// - Parameter stringValue: The string to parse (e.g., "100px", "auto", "fill").
    init?(stringValue: String) {
        if stringValue.hasSuffix(Self.fixedKey), let value = Int(stringValue.dropLast(Self.fixedKey.count)) {
            self = .fixed(value: value)
        } else if stringValue == Self.autoKey {
            self = .auto
        } else if stringValue == Self.fillKey {
            self = .fill
        } else {
            return nil
        }
    }
}
