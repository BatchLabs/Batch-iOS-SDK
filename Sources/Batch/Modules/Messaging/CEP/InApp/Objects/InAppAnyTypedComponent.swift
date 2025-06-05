//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app component
/// Could be a button, a column, a divider, an image or a label
public struct InAppAnyTypedComponent: Codable {
    // MARK: -

    enum CodingKeys: CodingKey {
        case component
    }

    enum CodableError: Error {
        case unknownType
    }

    // MARK: -

    let component: InAppTypedComponent?

    // MARK: -

    public init(_ component: InAppTypedComponent?) {
        self.component = component
    }

    // MARK: -

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch component {
            case let button as InAppButton:
                try container.encode(button)
            case let columns as InAppColumns:
                try container.encode(columns)
            case let divider as InAppDivider:
                try container.encode(divider)
            case let image as InAppImage:
                try container.encode(image)
            case let label as InAppLabel:
                try container.encode(label)
            default:
                throw CodableError.unknownType
        }
    }

    // MARK: -

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch (try? container.decode(TypedComponent.self))?.type {
            case .button:
                self.init(try container.decode(InAppButton.self))
            case .columns:
                self.init(try container.decode(InAppColumns.self))
            case .divider:
                self.init(try container.decode(InAppDivider.self))
            case .image:
                self.init(try container.decode(InAppImage.self))
            case .text:
                self.init(try container.decode(InAppLabel.self))
            case .none:
                throw CodableError.unknownType
        }
    }
}

fileprivate struct TypedComponent: InAppTypedComponent {
    let type: InAppComponent
}
