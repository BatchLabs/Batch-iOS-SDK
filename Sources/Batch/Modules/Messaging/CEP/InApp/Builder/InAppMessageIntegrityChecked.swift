//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Ensure correct in app message configuration
struct InAppMessageChecker {
    // MARK: -

    enum Mandatory<T> {
        case `true`
        case `false`(T)

        var value: Bool {
            return switch self {
            case .true: true
            case .false: false
            }
        }
    }

    enum Component {
        case identifiable(_ identifiable: any Identifiable)
        case identifier(String)

        var description: String {
            return switch self {
            case let .identifiable(identifiable): "\(identifiable)"
            case let .identifier(identifier): identifier
            }
        }
    }

    enum Warning {
        case tooMuchValues(_ values: [String])
        case noValue
        case negativeValue(_ value: String, index: Int?)
        case emptyValue(index: Int?)
        case notEquals(_ expected: Int, _ actual: Int)
        case badFormat(_ format: String)

        func description(component: Component, source: AnyKeyPath) -> String {
            let base = "\(component.description)-\(source):"
            return switch self {
            case let .tooMuchValues(values):
                "\(base) Too much values: \(values)"
            case .noValue:
                "\(base) No value: \(source)"
            case let .negativeValue(value, index):
                "\(base) Negative value: \(value)\(index.map { " at index \($0)" })"
            case let .emptyValue(index):
                "\(base) Empty value: \(index.map { " at index \($0)" })"
            case let .notEquals(expected, actual):
                "\(base) Not equals: \(expected.formatted()) and \(actual.formatted())"
            case let .badFormat(format):
                "\(base) Bad format: \(format)"
            }
        }
    }

    // MARK: -

    static func text(for value: String?, mandatory: Mandatory<String>, source: AnyKeyPath, component: Component) throws -> String {
        Checker.checkStringIntegrity(for: value.map { [$0] }, source: source, component: component)

        return try Sanitizer.sanitizeString(value: value, mandatory: mandatory, source: source, component: component)
    }

    static func horizontalAlignment(for value: InAppHorizontalAlignment?, mandatory: Mandatory<InAppHorizontalAlignment>, source: AnyKeyPath, component: Component) throws -> InAppHorizontalAlignment {
        try anyType(for: value, mandatory: mandatory, source: source, component: component)
    }

    static func verticalAlignment(for value: InAppVerticalAlignment?, mandatory: Mandatory<InAppVerticalAlignment>, source: AnyKeyPath, component: Component) throws -> InAppVerticalAlignment {
        try anyType(for: value, mandatory: mandatory, source: source, component: component)
    }

    static func fontSize(for value: Int, mandatory: Mandatory<Int>, source: AnyKeyPath, component: Component) throws -> Int {
        Checker.checkValuesIntegrity(for: [value], acceptNegativeValue: false, source: source, component: component)

        let value = try Sanitizer.sanitizeValue(value: value, mandatory: mandatory, acceptNegativeValue: false, source: source, component: component)
        return try anyType(for: value, mandatory: mandatory, source: source, component: component)
    }

    static func margins(for values: [Int]?, mandatory: Mandatory<Int>, source: AnyKeyPath, component: Component) throws -> UIEdgeInsets {
        let values = try marginsOrPadding(for: values, mandatory: mandatory, acceptNegativeValue: true, source: source, component: component)
        return InAppUIEdgeInsetsBuilder.build(from: values)
    }

    static func paddings(for values: [Int]?, mandatory: Mandatory<Int>, source: AnyKeyPath, component: Component) throws -> UIEdgeInsets {
        let values = try marginsOrPadding(for: values, mandatory: mandatory, acceptNegativeValue: true, source: source, component: component)
        return InAppUIEdgeInsetsBuilder.build(from: values)
    }

    private static func marginsOrPadding(for values: [Int]?, mandatory: Mandatory<Int>, acceptNegativeValue: Bool, source: AnyKeyPath, component: Component) throws -> [Int] {
        Checker.checkLengthIntegrity(
            for: values,
            arrayLimit: 4,
            isMandatory: mandatory.value,
            formatter: { $0.formatted() },
            source: source,
            component: component
        )

        Checker.checkValuesIntegrity(
            for: values,
            acceptNegativeValue: acceptNegativeValue,
            source: source,
            component: component
        )

        return try Sanitizer.sanitizeMarginsOrPadding(values: values, mandatory: mandatory, arrayLimit: 4, source: source, component: component)
    }

    static func aspectRatio(for value: InAppAspectRatio?, mandatory: Mandatory<InAppAspectRatio>, source: AnyKeyPath, component: Component) throws -> InAppAspectRatio {
        try anyType(for: value, mandatory: mandatory, source: source, component: component)
    }

    static func radius(for values: [Int]?, mandatory: Mandatory<Int>, source: AnyKeyPath, component: Component) throws -> [Int] {
        Checker.checkLengthIntegrity(
            for: values,
            arrayLimit: 4,
            isMandatory: mandatory.value,
            formatter: { $0.formatted() },
            source: source,
            component: component
        )

        Checker.checkValuesIntegrity(
            for: values,
            acceptNegativeValue: false,
            source: source,
            component: component
        )

        return try Sanitizer.sanitizeRadius(values: values, mandatory: mandatory, arrayLimit: 4, source: source, component: component)
    }

    static func borderWidth(for value: Int?, mandatory: Mandatory<Int>, source: AnyKeyPath, component: Component) throws -> Int {
        try integer(for: value, mandatory: mandatory, acceptNegativeValue: false, source: source, component: component)
    }

    static func maxLines(for value: Int?, mandatory: Mandatory<Int>, source: AnyKeyPath, component: Component) throws -> Int {
        try integer(for: value, mandatory: mandatory, acceptNegativeValue: true, source: source, component: component)
    }

    static func heightType(for value: InAppHeightType?, mandatory: Mandatory<InAppHeightType>, source: AnyKeyPath, component: Component) throws -> InAppHeightType {
        try anyType(for: value, mandatory: mandatory, source: source, component: component)
    }

    static func widthType(for value: InAppWidthType?, mandatory: Mandatory<InAppWidthType>, source: AnyKeyPath, component: Component) throws -> InAppWidthType {
        try anyType(for: value, mandatory: mandatory, source: source, component: component)
    }

    static func url(for value: URL?, mandatory: Mandatory<URL>, source: AnyKeyPath, component: Component) throws -> URL {
        try anyType(for: value, mandatory: mandatory, source: source, component: component)
    }

    static func anyType<T>(for value: T?, mandatory: Mandatory<T>, source: AnyKeyPath, component: Component) throws -> T {
        Checker.checkNil(for: value, isMandatory: mandatory.value, source: source, component: component)

        return try Sanitizer.sanitizeAny(value: value, mandatory: mandatory, source: source, component: component)
    }

    static func ratio(for values: [Int]?, count: Int, mandatory: Mandatory<Int>, source: AnyKeyPath, component: Component) -> [Int] {
        Checker.checkRatio(for: values, count: count, isMandatory: mandatory.value, source: source, component: component)

        return Sanitizer.sanitizeRatio(values: values, count: count, source: source, component: component)
    }

    static func integer(for value: Int?, mandatory: Mandatory<Int>, acceptNegativeValue: Bool, source: AnyKeyPath, component: Component) throws -> Int {
        Checker.checkValuesIntegrity(for: value.map { [$0] }, acceptNegativeValue: acceptNegativeValue, source: source, component: component)

        return try Sanitizer.sanitizeValue(value: value, mandatory: mandatory, acceptNegativeValue: acceptNegativeValue, source: source, component: component)
    }

    static func estimateHeight(for url: URL, acceptNegativeValue: Bool, source: AnyKeyPath, component: Component) throws -> Int? {
        try estimateValue(for: url, key: "h", acceptNegativeValue: false, source: source, component: component)
    }

    static func estimateWidth(for url: URL, acceptNegativeValue: Bool, source: AnyKeyPath, component: Component) throws -> Int? {
        try estimateValue(for: url, key: "w", acceptNegativeValue: false, source: source, component: component)
    }

    static func estimateValue(for url: URL, key: String, acceptNegativeValue: Bool, source: AnyKeyPath, component: Component) throws -> Int? {
        let value: Int? = getIntParams(from: url, key: key)

        Checker.checkValuesIntegrity(for: value.map { [$0] }, acceptNegativeValue: acceptNegativeValue, source: source, component: component)

        return value
    }

    static func colors(for values: [String]?, mandatory: Mandatory<(light: String, dark: String)>, source: AnyKeyPath, component: Component) throws -> UIColor {
        Checker.checkLengthIntegrity(
            for: values,
            arrayLimit: 2,
            isMandatory: mandatory.value,
            formatter: { $0 },
            source: source,
            component: component
        )

        Checker.checkStringIntegrity(for: values, source: source, component: component)

        return try Sanitizer.sanitizeColors(values: values, mandatory: mandatory, source: source, component: component)
    }

    static func queryParameters(from url: URL) -> [String: String]? {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = urlComponents.queryItems
        else {
            return nil
        }

        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value
        }
        return parameters
    }

    static func getIntParams(from url: URL, key: String) -> Int? {
        return queryParameters(from: url)?[key]
            .flatMap(Int.init)
    }

    static func action(action: InAppAction, source: AnyKeyPath, component: Component) throws -> BAMSGAction? {
        return try Sanitizer.action(action: action, source: source, component: component)
    }
}

extension InAppMessageChecker {
    struct Sanitizer {
        enum InternalError: Error {
            case missingMandatoryParameter(source: AnyKeyPath)
            case wrongRepartition(source: AnyKeyPath)
            case actionWithUnsupportedParameters(source: AnyKeyPath, name: String, key: String)

            func description(component: Component, source: AnyKeyPath) -> String {
                let base = "\(component.description)-\(source):"
                return switch self {
                case let .missingMandatoryParameter(source):
                    "\(base) Missing mandatory parameter: \(source)"
                case let .wrongRepartition(source):
                    "\(base) Wrong repartition: \(source)"
                case let .actionWithUnsupportedParameters(source, name, key):
                    "\(base) Action (\(name)) with unsupported parameters for key: \(key): \(source)"
                }
            }
        }

        static func sanitizeRadius(values: [Int]?, mandatory: Mandatory<Int>, arrayLimit: Int, source: AnyKeyPath, component: Component) throws -> [Int] {
            let radius: [Int]? =
                if let values {
                    switch values.count {
                    case 0: nil
                    case 1: (0..<arrayLimit).map { _ in values[0] }
                    case 2: [values[0], values[1], values[0], values[1]]
                    case 3: throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                    default: values[0..<arrayLimit].map { $0 }
                    }
                } else {
                    nil
                }

            switch mandatory {
            case let .false(defaultValue):
                return radius ?? (0..<arrayLimit).map { _ in defaultValue }
            case .true:
                if let radius {
                    return radius
                } else {
                    throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                }
            }
        }

        static func sanitizeMarginsOrPadding(values: [Int]?, mandatory: Mandatory<Int>, arrayLimit: Int, source: AnyKeyPath, component: Component) throws -> [Int] {
            let margins: [Int]? =
                if let values {
                    switch values.count {
                    case 0: nil
                    case 1: (0..<arrayLimit).map { _ in values[0] }
                    case 2: [values[0], values[1], values[0], values[1]]
                    case 3: throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                    default: values[0..<arrayLimit].map { $0 }
                    }
                } else {
                    nil
                }

            switch mandatory {
            case let .false(defaultValue):
                return margins ?? (0..<arrayLimit).map { _ in defaultValue }
            case .true:
                if let margins {
                    return margins
                } else {
                    throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                }
            }
        }

        static func sanitizeColors(values: [String]?, mandatory: Mandatory<(light: String, dark: String)>, source: AnyKeyPath, component: Component) throws -> UIColor {
            let colors: [String] =
                switch mandatory {
                case .true:
                    if let values {
                        switch values.filter({ !$0.isEmpty }).count {
                        case 0: throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                        case 1: [values[0], values[0]]
                        default: values[0..<2].map { $0 }
                        }
                    } else {
                        throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                    }
                case let .false(fallbackValues):
                    if let values {
                        switch values.filter({ !$0.isEmpty }).count {
                        case 0: [fallbackValues.light, fallbackValues.dark]
                        case 1: [values[0], values[0]]
                        default: values[0..<2].map { $0 }
                        }
                    } else {
                        [fallbackValues.light, fallbackValues.dark]
                    }
                }

            var lightColor = BAMSGStylableViewHelper.color(fromValue: colors[0])
            var darkColor = BAMSGStylableViewHelper.color(fromValue: colors[1])
            switch mandatory {
            case .true:
                switch (lightColor, darkColor) {
                case (nil, nil): throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                case (lightColor, nil):
                    darkColor = lightColor
                case (nil, darkColor):
                    lightColor = darkColor
                default: break
                }
            case let .false((light, dark)):
                switch (lightColor, darkColor) {
                case (nil, nil):
                    lightColor = BAMSGStylableViewHelper.color(fromValue: light)
                    darkColor = BAMSGStylableViewHelper.color(fromValue: dark)
                case (lightColor, nil):
                    darkColor = lightColor
                case (nil, darkColor):
                    lightColor = darkColor
                default: break
                }
            }

            guard let lightColor, let darkColor else {
                throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
            }

            return UIColor { trait in
                switch trait.userInterfaceStyle {
                case .dark: darkColor
                case .light, .unspecified: lightColor
                @unknown default: lightColor
                }
            }
        }

        static func sanitizeValue(value: Int?, mandatory: Mandatory<Int>, acceptNegativeValue: Bool, source: AnyKeyPath, component: Component) throws -> Int {
            switch mandatory {
            case let .false(defaultValue):
                if let value, !acceptNegativeValue, value < 0 {
                    return defaultValue
                } else if let value {
                    return value
                } else {
                    return defaultValue
                }
            case .true:
                if let value, !acceptNegativeValue, value < 0 {
                    throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                } else if let value {
                    return value
                } else {
                    throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                }
            }
        }

        static func sanitizeString(value: String?, mandatory: Mandatory<String>, source: AnyKeyPath, component: Component) throws -> String {
            switch mandatory {
            case let .false(defaultValue):
                if value?.isEmpty == true {
                    return defaultValue
                } else if let value {
                    return value
                } else {
                    return defaultValue
                }
            case .true:
                if value?.isEmpty == true {
                    throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                } else if let value {
                    return value
                } else {
                    throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                }
            }
        }

        static func sanitizeRatio(values: [Int]?, count: Int, source _: AnyKeyPath, component _: Component) -> [Int] {
            if let values, values.reduce(0, +) == 100, values.count == count {
                return values
            } else {
                let defaultValue = 100 / count
                var defaultValues = (0..<count).map { _ in defaultValue }

                if defaultValues.reduce(0, +) != 100 {
                    defaultValues[defaultValues.count - 1] = 100 - defaultValues.dropLast().reduce(0, +)
                }

                return defaultValues
            }
        }

        static func sanitizeAny<T>(value: T?, mandatory: Mandatory<T>, source: AnyKeyPath, component: Component) throws -> T {
            switch mandatory {
            case let .false(defaultValue):
                return value ?? defaultValue
            case .true:
                if let value {
                    return value
                } else {
                    throw errorWithLogs(InternalError.missingMandatoryParameter(source: source), component: component, source: source)
                }
            }
        }

        static func action(action: InAppAction, source: AnyKeyPath, component: Component) throws -> BAMSGAction? {
            var args: [String: NSObject] = [:]
            for row in action.params ?? [:] {
                if let value = row.value.value as? NSObject {
                    args[row.key] = value
                } else {
                    throw errorWithLogs(InternalError.actionWithUnsupportedParameters(source: source, name: action.action, key: row.key), component: component, source: source)
                }
            }

            let msgAction = BAMSGAction()
            msgAction.actionIdentifier = action.action
            msgAction.actionArguments = args
            return msgAction
        }

        /// Sanitizes and provides default close button configuration for webview format
        /// Ensures webview messages always have a close button with appropriate default styling
        /// when no explicit close button configuration is provided
        static func cross(format: InAppFormat, cross: InAppViewController.Configuration.CloseConfiguration.Cross?, source: AnyKeyPath, component: Component) throws -> InAppViewController.Configuration
            .CloseConfiguration.Cross?
        {
            guard let cross else {
                // For webview format, provide default close button styling if none specified
                if format == .webview {
                    return InAppViewController.Configuration.CloseConfiguration.Cross(
                        color: try colors(for: nil, mandatory: .false((light: "#292945ff", dark: "#7575ffff")), source: source, component: component),
                        backgroundColor: try colors(for: nil, mandatory: .false((light: "#ebebebff", dark: "#4d4d4dff")), source: source, component: component)
                    )
                } else {
                    return nil
                }
            }

            return cross
        }

        static func errorWithLogs(_ error: InternalError, component: Component, source: AnyKeyPath) -> InternalError {
            BALogger.debug(domain: String(describing: Self.self), message: error.description(component: component, source: source))

            return error
        }
    }

    struct Checker {
        static func checkRatio(for values: [Int]?, count: Int, isMandatory: Bool, source: AnyKeyPath, component: Component) {
            var warnings: [Warning] = []

            if let values {
                if values.count != count, isMandatory {
                    warnings.append(.notEquals(values.count, count))
                }

                if values.reduce(0, +) != 100 {
                    warnings.append(.notEquals(values.reduce(0, +), 100))
                }
            } else {
                warnings.append(.noValue)
            }

            logs(warnings, component: component, source: source)
        }

        static func checkNil(for value: Any?, isMandatory: Bool, source: AnyKeyPath, component: Component) {
            var warnings: [Warning] = []

            if value == nil, isMandatory {
                warnings.append(.noValue)
            }

            logs(warnings, component: component, source: source)
        }

        static func checkLengthIntegrity<T>(for value: [T]?, arrayLimit: Int, isMandatory: Bool, formatter: (T) -> String, source: AnyKeyPath, component: Component) {
            var warnings: [Warning] = []
            let value: [T] = value ?? []

            if value.count == 0, isMandatory {
                warnings.append(.noValue)
            }

            // To much values
            if value.count > arrayLimit {
                warnings.append(.tooMuchValues(value[arrayLimit..<value.count].map(formatter)))
            }

            logs(warnings, component: component, source: source)
        }

        static func checkValuesIntegrity(for values: [Int]?, acceptNegativeValue: Bool, source: AnyKeyPath, component: Component) {
            guard !acceptNegativeValue else { return }

            var warnings: [Warning] = []

            // Negative value
            values?.enumerated()
                .forEach { value in
                    if value.element < 0 {
                        warnings.append(.negativeValue(value.element.formatted(), index: value.offset))
                    }
                }

            logs(warnings, component: component, source: source)
        }

        static func checkStringIntegrity(for values: [String]?, source: AnyKeyPath, component: Component) {
            var warnings: [Warning] = []

            // Negative value
            values?.enumerated()
                .forEach { value in
                    if value.element.isEmpty {
                        warnings.append(.emptyValue(index: value.offset))
                    }
                }

            logs(warnings, component: component, source: source)
        }

        static func checkColorsIntegrity(for values: [String]?, source: AnyKeyPath, component: Component) {
            var warnings: [Warning] = []
            let values: [String] = values ?? []

            values.forEach { value in
                if BAMSGStylableViewHelper.color(fromValue: value) == nil {
                    warnings.append(.badFormat(value))
                }
            }

            logs(warnings, component: component, source: source)
        }

        static func logs(_ warnings: [Warning], component: Component, source: AnyKeyPath) {
            warnings.forEach {
                BALogger.debug(domain: String(describing: Self.self), message: $0.description(component: component, source: source))
            }
        }
    }
}
