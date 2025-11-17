//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Testing

@testable import Batch

@Suite("InAppMessageChecker") struct InAppMessageCheckerTests {
    static let component = InAppMessageChecker.Component.identifier("InAppMessageCheckerTests")
    static let source: AnyKeyPath = \InAppMessageCheckerTests.self

    // MARK: - Text

    @Suite("Text") struct InAppMessageCheckerText {
        @Test func value() throws {
            let value = "text"
            let result = try InAppMessageChecker.text(for: value, mandatory: .true, source: source, component: component)

            #expect(value == result)
        }

        @Test func throwing() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.text(for: nil, mandatory: .true, source: source, component: component)
                }
            )
        }

        @Test func defaultValue() throws {
            let defaultValue = "defaultValue"
            let value = "value"

            let valueResult = try InAppMessageChecker.text(for: value, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = try InAppMessageChecker.text(for: nil, mandatory: .false(defaultValue), source: source, component: component)

            #expect(valueResult == value)
            #expect(defaultValueResult == defaultValue)
        }
    }

    // MARK: - Horizontal Alignment

    @Suite("Horizontal Alignment") struct InAppMessageCheckerHorizontalAlignment {
        @Test func value() throws {
            let horizontalAlignment: InAppHorizontalAlignment = .left
            let result = try InAppMessageChecker.horizontalAlignment(for: horizontalAlignment, mandatory: .true, source: source, component: component)

            #expect(horizontalAlignment == result)
        }

        @Test func throwing() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.horizontalAlignment(for: nil, mandatory: .true, source: source, component: component)
                }
            )
        }

        @Test func defaultValue() throws {
            let value: InAppHorizontalAlignment = .left
            let defaultValue: InAppHorizontalAlignment = .center

            let valueResult = try InAppMessageChecker.horizontalAlignment(for: value, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = try InAppMessageChecker.horizontalAlignment(for: nil, mandatory: .false(defaultValue), source: source, component: component)

            #expect(valueResult == value)
            #expect(defaultValueResult == defaultValue)
        }
    }

    // MARK: - Vertical Alignment

    @Suite("Vertical Alignment") struct InAppMessageCheckerVerticalAlignment {
        @Test func value() throws {
            let value: InAppVerticalAlignment = .top
            let result = try InAppMessageChecker.verticalAlignment(for: value, mandatory: .true, source: source, component: component)

            #expect(value == result)
        }

        @Test func throwing() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.verticalAlignment(for: nil, mandatory: .true, source: source, component: component)
                }
            )
        }

        @Test func defaultValue() throws {
            let value: InAppVerticalAlignment = .top
            let defaultValue: InAppVerticalAlignment = .center

            let valueResult = try InAppMessageChecker.verticalAlignment(for: value, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = try InAppMessageChecker.verticalAlignment(for: nil, mandatory: .false(defaultValue), source: source, component: component)

            #expect(valueResult == value)
            #expect(defaultValueResult == defaultValue)
        }
    }

    // MARK: - Font Size

    @Suite("Font Size") struct InAppMessageCheckerFontSize {
        @Test func value() throws {
            let value = 12
            let result = try InAppMessageChecker.fontSize(for: value, mandatory: .true, source: source, component: component)

            #expect(value == result)
        }

        @Test func throwing() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.fontSize(for: -1, mandatory: .true, source: source, component: component)
                }
            )
        }

        @Test func defaultValue() throws {
            let value = 12
            let defaultValue = 28

            let valueResult = try InAppMessageChecker.fontSize(for: value, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = try InAppMessageChecker.fontSize(for: -1, mandatory: .false(defaultValue), source: source, component: component)

            #expect(valueResult == value)
            #expect(defaultValueResult == defaultValue)
        }
    }

    // MARK: - Margins

    @Suite("Margin") struct InAppMessageCheckerMargin {
        @Test func values() throws {
            let values: [Int] = [12, 12, 12, 12]
            let result = try InAppMessageChecker.margins(for: values, mandatory: .true, source: source, component: component)

            #expect(UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12) == result)
        }

        @Test func throwing() throws {
            // Should throws
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.margins(for: nil, mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.margins(for: [], mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.margins(for: [1, 1, 1], mandatory: .true, source: source, component: component)
                }
            )

            // Should not throws
            _ = try InAppMessageChecker.margins(for: [1, 1, 1, 1, 1], mandatory: .false(2), source: source, component: component)
            _ = try InAppMessageChecker.margins(for: [1, 1, 1, 1], mandatory: .true, source: source, component: component)
            _ = try InAppMessageChecker.margins(for: [1, 1], mandatory: .true, source: source, component: component)
            _ = try InAppMessageChecker.margins(for: [1], mandatory: .true, source: source, component: component)
        }

        @Test func defaultValue() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.margins(for: [1, 1, 1], mandatory: .false(2), source: source, component: component)
                }
            )

            let result1 = try InAppMessageChecker.margins(for: [1, 1, 1, 1], mandatory: .false(2), source: source, component: component)
            let result2 = try InAppMessageChecker.margins(for: [1], mandatory: .false(2), source: source, component: component)
            let result3 = try InAppMessageChecker.margins(for: [1, 1], mandatory: .false(2), source: source, component: component)
            let result4 = try InAppMessageChecker.margins(for: [], mandatory: .false(2), source: source, component: component)
            let result5 = try InAppMessageChecker.margins(for: nil, mandatory: .false(2), source: source, component: component)
            let result6 = try InAppMessageChecker.margins(for: [1, 1, 1, 1, 1], mandatory: .false(2), source: source, component: component)

            #expect(UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1) == result1)
            #expect(UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1) == result2)
            #expect(UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1) == result3)
            #expect(UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2) == result4)
            #expect(UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2) == result5)
            #expect(UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1) == result6)
        }
    }

    // MARK: - Paddings

    @Suite("Padding") struct InAppMessageCheckerPadding {
        @Test func values() throws {
            let values: [Int] = [12, 12, 12, 12]
            let result = try InAppMessageChecker.paddings(for: values, mandatory: .true, source: source, component: component)

            #expect(UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12) == result)
        }

        @Test func throwing() throws {
            // Should throws
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.paddings(for: nil, mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.paddings(for: [], mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.paddings(for: [1, 1, 1], mandatory: .true, source: source, component: component)
                }
            )

            // Should not throws
            _ = try InAppMessageChecker.paddings(for: [1, 1, 1, 1, 1], mandatory: .true, source: source, component: component)
            _ = try InAppMessageChecker.paddings(for: [1, 1, 1, 1], mandatory: .true, source: source, component: component)
            _ = try InAppMessageChecker.paddings(for: [1, 1], mandatory: .true, source: source, component: component)
            _ = try InAppMessageChecker.paddings(for: [1], mandatory: .true, source: source, component: component)
        }

        @Test func defaultValue() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.margins(for: [1, 1, 1], mandatory: .false(2), source: source, component: component)
                }
            )

            let result1 = try InAppMessageChecker.paddings(for: [1, 1, 1, 1], mandatory: .false(2), source: source, component: component)
            let result2 = try InAppMessageChecker.paddings(for: [1], mandatory: .false(2), source: source, component: component)
            let result3 = try InAppMessageChecker.paddings(for: [1, 2], mandatory: .false(2), source: source, component: component)
            let result4 = try InAppMessageChecker.paddings(for: [], mandatory: .false(2), source: source, component: component)
            let result5 = try InAppMessageChecker.paddings(for: nil, mandatory: .false(2), source: source, component: component)
            let result6 = try InAppMessageChecker.paddings(for: [1, 1, 1, 1, 1], mandatory: .false(2), source: source, component: component)

            #expect(UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1) == result1)
            #expect(UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1) == result2)
            #expect(UIEdgeInsets(top: 1, left: 2, bottom: 1, right: 2) == result3)
            #expect(UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2) == result4)
            #expect(UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2) == result5)
            #expect(UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1) == result6)
        }
    }

    // MARK: - Radius

    @Suite("Radius") struct InAppMessageCheckerRadius {
        @Test func values() throws {
            let values: [Int] = [12, 12, 12, 12]
            let result = try InAppMessageChecker.radius(for: values, mandatory: .true, source: source, component: component)

            #expect(values == result)
        }

        @Test func throwing() throws {
            // Should throws
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.radius(for: nil, mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.radius(for: [], mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.radius(for: [1, 1, 1], mandatory: .true, source: source, component: component)
                }
            )

            // Should not throws
            _ = try InAppMessageChecker.radius(for: [1, 1, 1, 1, 1], mandatory: .true, source: source, component: component)
            _ = try InAppMessageChecker.radius(for: [1, 1, 1, 1], mandatory: .true, source: source, component: component)
            _ = try InAppMessageChecker.radius(for: [1, 1], mandatory: .true, source: source, component: component)
            _ = try InAppMessageChecker.radius(for: [1], mandatory: .true, source: source, component: component)
        }

        @Test func defaultValue() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.radius(for: [1, 1, 1], mandatory: .false(2), source: source, component: component)
                }
            )

            let result1 = try InAppMessageChecker.radius(for: [1, 1, 1, 1], mandatory: .false(2), source: source, component: component)
            let result2 = try InAppMessageChecker.radius(for: [1], mandatory: .false(2), source: source, component: component)
            let result3 = try InAppMessageChecker.radius(for: [1, 2], mandatory: .false(2), source: source, component: component)
            let result4 = try InAppMessageChecker.radius(for: [], mandatory: .false(2), source: source, component: component)
            let result5 = try InAppMessageChecker.radius(for: nil, mandatory: .false(2), source: source, component: component)
            let result6 = try InAppMessageChecker.radius(for: [1, 1, 1, 1, 1], mandatory: .false(2), source: source, component: component)

            #expect(result1 == [1, 1, 1, 1])
            #expect(result2 == [1, 1, 1, 1])
            #expect(result3 == [1, 2, 1, 2])
            #expect(result4 == [2, 2, 2, 2])
            #expect(result5 == [2, 2, 2, 2])
            #expect(result6 == [1, 1, 1, 1])
        }
    }

    // MARK: - Aspect Ratio

    @Suite("Aspect Ratio") struct InAppMessageCheckerAspectRatio {
        @Test func value() throws {
            let value: InAppAspectRatio = .fill
            let result = try InAppMessageChecker.aspectRatio(for: value, mandatory: .true, source: source, component: component)

            #expect(value == result)
        }

        @Test func throwing() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.aspectRatio(for: nil, mandatory: .true, source: source, component: component)
                }
            )
        }

        @Test func defaultValue() throws {
            let value: InAppAspectRatio = .fill
            let defaultValue: InAppAspectRatio = .fit

            let valueResult = try InAppMessageChecker.aspectRatio(for: value, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = try InAppMessageChecker.aspectRatio(for: nil, mandatory: .false(defaultValue), source: source, component: component)

            #expect(valueResult == value)
            #expect(defaultValueResult == defaultValue)
        }
    }

    // MARK: - Border width

    @Suite("Border") struct InAppMessageCheckerBorder {
        @Test func value() throws {
            let value = 12
            let result = try InAppMessageChecker.borderWidth(for: value, mandatory: .true, source: source, component: component)

            #expect(value == result)
        }

        @Test func throwing() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.borderWidth(for: nil, mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.borderWidth(for: -1, mandatory: .true, source: source, component: component)
                }
            )
        }

        @Test func defaultValue() throws {
            let value = 12
            let defaultValue = 24

            let valueResult = try InAppMessageChecker.borderWidth(for: value, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = try InAppMessageChecker.borderWidth(for: nil, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult2 = try InAppMessageChecker.borderWidth(for: -1, mandatory: .false(defaultValue), source: source, component: component)

            #expect(valueResult == value)
            #expect(defaultValueResult == defaultValue)
            #expect(defaultValueResult2 == defaultValue)
        }
    }

    // MARK: - Max lines

    @Suite("Max Lines") struct InAppMessageCheckerMaxLines {
        @Test func value() throws {
            let value = 12
            let result = try InAppMessageChecker.maxLines(for: value, mandatory: .true, source: source, component: component)

            #expect(value == result)
        }

        @Test func throwing() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.maxLines(for: nil, mandatory: .true, source: source, component: component)
                }
            )

            // Should not throw
            _ = try InAppMessageChecker.maxLines(for: -5, mandatory: .true, source: source, component: component)
        }

        @Test func defaultValue() throws {
            let value = 12
            let defaultValue = 24
            let negativeValue: Int = -2

            let valueResult = try InAppMessageChecker.maxLines(for: value, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = try InAppMessageChecker.maxLines(for: nil, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult2 = try InAppMessageChecker.maxLines(for: negativeValue, mandatory: .false(defaultValue), source: source, component: component)

            #expect(valueResult == value)
            #expect(defaultValueResult == defaultValue)
            #expect(defaultValueResult2 == negativeValue)
        }
    }

    // MARK: - Height types

    @Suite("Height Type") struct InAppMessageCheckerHeightType {
        @Test func value() throws {
            let value: InAppHeightType = .fixed(value: 12)
            let result = try InAppMessageChecker.heightType(for: value, mandatory: .true, source: source, component: component)

            #expect(value == result)
        }

        @Test func throwing() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.heightType(for: nil, mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.heightType(for: .init(stringValue: "unknow"), mandatory: .true, source: source, component: component)
                }
            )
        }

        @Test func defaultValue() throws {
            let value: InAppHeightType = .auto
            let defaultValue: InAppHeightType = .fixed(value: 12)
            let unknowValue: InAppHeightType? = .init(stringValue: "unknow")

            let valueResult = try InAppMessageChecker.heightType(for: value, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = try InAppMessageChecker.heightType(for: nil, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult2 = try InAppMessageChecker.heightType(for: unknowValue, mandatory: .false(defaultValue), source: source, component: component)

            #expect(valueResult == value)
            #expect(defaultValueResult == defaultValue)
            #expect(defaultValueResult2 == defaultValue)
        }
    }

    // MARK: - Width types

    @Suite("Width Type") struct InAppMessageCheckerWidthType {
        @Test func value() throws {
            let value: InAppWidthType = .percent(value: 12)
            let result = try InAppMessageChecker.widthType(for: value, mandatory: .true, source: source, component: component)

            #expect(value == result)
        }

        @Test func throwing() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.heightType(for: nil, mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.heightType(for: .init(stringValue: "unknow"), mandatory: .true, source: source, component: component)
                }
            )
        }

        @Test func defaultValue() throws {
            let value: InAppWidthType = .auto
            let defaultValue: InAppWidthType = .percent(value: 12)
            let unknowValue: InAppWidthType? = .init(stringValue: "unknow")

            let valueResult = try InAppMessageChecker.widthType(for: value, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = try InAppMessageChecker.widthType(for: nil, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult2 = try InAppMessageChecker.widthType(for: unknowValue, mandatory: .false(defaultValue), source: source, component: component)

            #expect(valueResult == value)
            #expect(defaultValueResult == defaultValue)
            #expect(defaultValueResult2 == defaultValue)
        }
    }

    // MARK: - Colors

    @Suite("Colors") struct InAppMessageCheckerColors {
        @Test func value() throws {
            let value = ["#FFFFFFFF", "#000000FF"]
            let result = try InAppMessageChecker.colors(for: value, mandatory: .true, source: source, component: component)

            let dark = BAMSGStylableViewHelper.color(fromValue: value[1]) ?? .clear
            let light = BAMSGStylableViewHelper.color(fromValue: value[0]) ?? .clear
            let color = UIColor { trait in
                switch trait.userInterfaceStyle {
                case .dark: dark
                case .light, .unspecified: light
                @unknown default: light
                }
            }

            #expect(color.cgColor == result.cgColor)
        }

        @Test func throwing() throws {
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.colors(for: nil, mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.colors(for: [], mandatory: .true, source: source, component: component)
                }
            )
            #expect(
                throws: (any Error).self,
                performing: {
                    try InAppMessageChecker.colors(for: ["ad", "adzazd"], mandatory: .true, source: source, component: component)
                }
            )
        }

        @Test func defaultValue() throws {
            let value = ["#FFAAFFFF", "#FFEEFFFF", "#AAEEFFFF"]
            let defaultValue = (light: "#FFBBFFFF", dark: "#FFEAAAFF")

            let valueResult = try InAppMessageChecker.colors(for: value, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = try InAppMessageChecker.colors(for: nil, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult2 = try InAppMessageChecker.colors(for: ["azdazd", "azaefzefzefze"], mandatory: .false(defaultValue), source: source, component: component)

            let colorValue = UIColor { trait in
                switch trait.userInterfaceStyle {
                case .dark: BAMSGStylableViewHelper.color(fromValue: value[1]) ?? .clear
                case .light, .unspecified: BAMSGStylableViewHelper.color(fromValue: value[0]) ?? .clear
                @unknown default: BAMSGStylableViewHelper.color(fromValue: value[0]) ?? .clear
                }
            }

            let colorDefaultValue = UIColor { trait in
                switch trait.userInterfaceStyle {
                case .dark: BAMSGStylableViewHelper.color(fromValue: defaultValue.dark) ?? .clear
                case .light, .unspecified: BAMSGStylableViewHelper.color(fromValue: defaultValue.light) ?? .clear
                @unknown default: BAMSGStylableViewHelper.color(fromValue: defaultValue.light) ?? .clear
                }
            }

            #expect(valueResult.cgColor == colorValue.cgColor)
            #expect(defaultValueResult.cgColor == colorDefaultValue.cgColor)
            #expect(defaultValueResult2.cgColor == colorDefaultValue.cgColor)
        }
    }

    // MARK: - Ratio

    @Suite("Ratio") struct InAppMessageCheckerRatio {
        @Test func value() {
            let values: [Int] = [80, 20]
            let result = InAppMessageChecker.ratio(for: values, count: values.count, mandatory: .false(50), source: source, component: component)

            #expect(values == result)
        }

        @Test func testDefaultValueRatioUpper100() {
            let values: [Int] = [80, 30]
            let defaultValue = 100 / values.count

            let valueResult = InAppMessageChecker.ratio(for: values, count: values.count, mandatory: .false(defaultValue), source: source, component: component)
            let defaultValueResult = InAppMessageChecker.ratio(for: nil, count: values.count, mandatory: .false(defaultValue), source: source, component: component)

            #expect(valueResult == defaultValueResult)
            #expect(defaultValueResult == (0..<values.count).map { _ in defaultValue })
        }

        @Test func testDefaultValueRatioWrongCount() {
            let count = 2
            let values: [Int] = [80, 10, 10]
            let defaultValue = 100 / count

            let valueResult = InAppMessageChecker.ratio(for: values, count: count, mandatory: .true, source: source, component: component)

            #expect(valueResult == (0..<count).map { _ in defaultValue })
        }
    }
}
