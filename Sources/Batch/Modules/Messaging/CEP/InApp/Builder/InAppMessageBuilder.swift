//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// The purpose of this struct is:
/// - To help the building of the in app message
struct InAppMessageBuilder {
    /// Identifier for rootContainer component
    static let rootContainerComponent: InAppMessageChecker.Component = .identifier("Root container")

    static let fallbackColor: (light: String, dark: String) = ("#000000FF", "#FFFFFFFF")
    static let transparentColor: (light: String, dark: String) = ("#00000000", "#00000000")

    /// Create configuration struct for root container
    /// - Parameter codable: Root container's codable
    /// - Returns: The configuration
    static func rootContainer(
        inAppMessage: InAppMessage
    ) throws -> InAppRootContainerView.Configuration {
        return InAppRootContainerView.Configuration(
            builder: InAppRootContainerView.Configuration.Builder(
                viewsBuilder: InAppAnyObjectTypeBuilder.build(
                    urls: inAppMessage.urls ?? [:],
                    texts: inAppMessage.texts ?? [:],
                    actions: inAppMessage.actions ?? [:],
                    componentTypes: inAppMessage.root.children
                ).compactMap { $0 }
            ),
            placement: InAppRootContainerView.Configuration.Placement(
                margins: try InAppMessageChecker.margins(
                    for: inAppMessage.root.margin,
                    mandatory: .false(0),
                    source: \InAppMessage.root.margin,
                    component: rootContainerComponent
                )
            )
        )
    }

    /// Create style struct for in app style
    /// - Parameter codable: In app style's codable
    /// - Returns: The style
    static func configurationStyle(inAppMessage: InAppMessage) throws -> InAppViewController.Configuration.Style {
        return InAppViewController.Configuration.Style(
            isModal: inAppMessage.format == .modal,
            backgroundColor: try InAppMessageChecker.colors(
                for: inAppMessage.root.backgroundColor,
                mandatory: .false((light: "#FFFFFFFF", dark: "#000000FF")),
                source: \InAppMessage.root.backgroundColor,
                component: rootContainerComponent
            ),
            radius: try InAppMessageChecker.radius(
                for: InAppMessageBuilderOverrider.values(format: inAppMessage.format, values: inAppMessage.root.radius),
                mandatory: .false(0),
                source: \InAppMessage.root.margin,
                component: rootContainerComponent
            ),
            borderWidth: try InAppMessageChecker.borderWidth(
                for: InAppMessageBuilderOverrider.values(format: inAppMessage.format, values: inAppMessage.root.borderWidth),
                mandatory: .false(0),
                source: \InAppMessage.root.borderWidth,
                component: rootContainerComponent
            ),
            borderColor: try InAppMessageChecker.colors(
                for: InAppMessageBuilderOverrider.values(format: inAppMessage.format, values: inAppMessage.root.borderColor),
                mandatory: .false(transparentColor),
                source: \InAppMessage.root.borderColor,
                component: rootContainerComponent
            )
        )
    }

    /// Create configuration struct for in app
    /// - Parameter codable: In app's codable
    /// - Returns: The configuration
    static func configuration(for inAppMessage: InAppMessage) throws -> InAppViewController.Configuration {
        let rootContainerConfiguration = try rootContainer(
            inAppMessage: inAppMessage
        )
        return InAppViewController.Configuration(
            style: try configurationStyle(inAppMessage: inAppMessage),
            placement: InAppViewController.Configuration.Placement(
                position: try InAppMessageChecker.verticalAlignment(
                    for: inAppMessage.position,
                    mandatory: .true,
                    source: \InAppMessage.position,
                    component: rootContainerComponent
                ),
                margins: try InAppMessageChecker.margins(
                    for: InAppMessageBuilderOverrider.values(format: inAppMessage.format, values: inAppMessage.root.margin),
                    mandatory: .false(0),
                    source: \InAppMessage.root.margin,
                    component: rootContainerComponent
                )
            ),
            builder: InAppViewController.Configuration.Builder(
                viewsBuilder: rootContainerConfiguration.builder.viewsBuilder
            ),
            closeConfiguration: InAppViewController.Configuration.CloseConfiguration(
                cross: try inAppMessage.closeOptions.button.map(closeCross),
                delay: try inAppMessage.closeOptions.auto.map(closeDelay)
            )
        )
    }
}

extension InAppTypedComponent {
    /// According the InAppObjectType it will create a builder to generate the right view
    /// It will use the ``InAppMessageBuilder`` to create the configuration
    /// - Parameters:
    ///   - codable: Object's codable
    ///   - urls: In app's urls
    ///   - texts: In app's texts
    /// - Returns: The builder
    func uiBuilder(urls: [String: String], texts: [String: String], actions: [String: InAppAction]) -> InAppViewBuilder? {
        switch type {
            case .button:
                guard let button = self as? InAppButton else { return nil }

                return InAppViewBuilder(component: self) { onClosureTap, _ in
                    let configuration = try InAppMessageBuilder.button(
                        text: texts[button.id],
                        action: actions[button.id],
                        button: button
                    )
                    return try InAppContainer(configuration: configuration.placement) {
                        InAppButtonView(
                            configuration: configuration,
                            onClosureTap: onClosureTap
                        )
                    }
                }
            case .divider:
                guard let divider = self as? InAppDivider else { return nil }

                return InAppViewBuilder(component: self) { _, _ in
                    let configuration = try InAppMessageBuilder.divider(divider: divider)
                    return try InAppContainer(configuration: configuration.placement) {
                        InAppDividerView(configuration: configuration)
                    }
                }
            case .image:
                guard let image = self as? InAppImage, let urlString = urls[image.id] else { return nil }

                let url = URL(string: urlString) ?? URL(fileURLWithPath: urlString)

                return InAppViewBuilder(component: self) { onClosureTap, onError in
                    let configuration = try InAppMessageBuilder.image(
                        url: url,
                        action: actions[image.id],
                        image: image,
                        contentDescription: texts[image.id]
                    )
                    return try InAppContainer(configuration: configuration.placement) {
                        InAppImageView(
                            configuration: configuration,
                            onClosureTap: onClosureTap,
                            onError: onError
                        )
                    }
                }
            case .text:
                guard let label = self as? InAppLabel else { return nil }

                return InAppViewBuilder(component: self) { _, _ in
                    let configuration = try InAppMessageBuilder.label(
                        text: texts[label.id],
                        label: label
                    )

                    return try InAppContainer(configuration: configuration.placement) {
                        InAppLabelView(configuration: configuration)
                    }
                }
            case .columns:
                guard let columns = self as? InAppColumns else { return nil }

                return InAppViewBuilder(component: self) { onClosureTap, onError in
                    let configuration = try InAppMessageBuilder.columns(
                        urls: urls,
                        texts: texts,
                        actions: actions,
                        columns: columns
                    )
                    return try InAppContainer(configuration: configuration.placement) {
                        InAppColumnsView(
                            configuration: configuration,
                            onClosureTap: onClosureTap,
                            onError: onError
                        )
                    }
                }
        }
    }
}

extension InAppMessageBuilder {
    // MARK: -

    /// Create cross struct for close cross button
    /// - Parameter codable: Close cross button's codable
    /// - Returns: The struct
    static func closeCross(cross: InAppCloseOptionCross) throws -> InAppViewController.Configuration.CloseConfiguration.Cross {
        return InAppViewController.Configuration.CloseConfiguration.Cross(
            color: try InAppMessageChecker.colors(
                for: cross.color,
                mandatory: .false(fallbackColor),
                source: \InAppCloseOptionCross.color,
                component: .identifier("InAppCloseOptionCross")
            ),
            backgroundColor: try InAppMessageChecker.colors(
                for: cross.backgroundColor,
                mandatory: .false(transparentColor),
                source: \InAppCloseOptionCross.backgroundColor,
                component: .identifier("InAppCloseOptionCross")
            )
        )
    }

    /// Create delay struct for close cross button
    /// - Parameter codable: Delay's codable
    /// - Returns: The struct
    static func closeDelay(delay: InAppCloseOptionDelay) throws -> InAppViewController.Configuration.CloseConfiguration.Delay {
        return InAppViewController.Configuration.CloseConfiguration.Delay(
            value: delay.delay,
            color: try InAppMessageChecker.colors(
                for: delay.color,
                mandatory: .false(fallbackColor),
                source: \InAppCloseOptionCross.color,
                component: .identifier("InAppCloseOptionCross")
            )
        )
    }

    // MARK: -

    /// Create configuration struct for divider
    /// - Parameter codable: Divider's codable
    /// - Returns: The configuration
    static func divider(
        divider: InAppDivider
    ) throws -> InAppDividerView.Configuration {
        let component: InAppMessageChecker.Component = .identifier("Divider")

        return InAppDividerView.Configuration(
            style: InAppDividerView.Configuration.Style(
                color: try InAppMessageChecker.colors(
                    for: divider.color,
                    mandatory: .false(fallbackColor),
                    source: \InAppCloseOptionCross.color,
                    component: component
                )
            ),
            placement: InAppDividerView.Configuration.Placement(
                margins: try InAppMessageChecker.margins(
                    for: divider.margin,
                    mandatory: .false(0),
                    source: \InAppDivider.margin,
                    component: component
                ),
                widthType: try InAppMessageChecker.widthType(
                    for: InAppWidthType(stringValue: divider.width),
                    mandatory: .false(.percent(value: 100)),
                    source: \InAppDivider.width,
                    component: component
                ),
                heightType: try InAppMessageChecker.heightType(
                    for: divider.thickness.map(InAppHeightType.fixed(value:)),
                    mandatory: .false(.fixed(value: 2)),
                    source: \InAppDivider.thickness,
                    component: component
                ),
                horizontalAlignment: try InAppMessageChecker.horizontalAlignment(
                    for: divider.align,
                    mandatory: .false(.center),
                    source: \InAppDivider.align,
                    component: component
                )
            )
        )
    }

    // MARK: -

    /// Create configuration struct for image
    /// - Parameters:
    ///   - url: Image's url
    ///   - codable: Image's codable
    /// - Returns: The configuration
    static func image(
        url: URL,
        action: InAppAction?,
        image: InAppImage,
        contentDescription: String?
    ) throws -> InAppImageView.Configuration {
        let component: InAppMessageChecker.Component = .identifiable(image)

        return InAppImageView.Configuration(
            url: url,
            style: InAppImageView.Configuration.Style(
                aspect: try InAppMessageChecker.aspectRatio(
                    for: image.aspect,
                    mandatory: .false(.fill),
                    source: \InAppImage.aspect,
                    component: component
                ),
                radius: try InAppMessageChecker.radius(
                    for: image.radius,
                    mandatory: .false(0),
                    source: \InAppImage.radius,
                    component: component
                )
            ),
            placement: InAppImageView.Configuration.Placement(
                heightType: InAppHeightType(stringValue: image.height),
                margins: try InAppMessageChecker.margins(
                    for: image.margin,
                    mandatory: .false(0),
                    source: \InAppImage.margin,
                    component: component
                ),
                estimateHeight: try InAppMessageChecker.estimateHeight(for: url, acceptNegativeValue: false, source: \URL.pathComponents, component: .identifiable(image)),
                estimateWidth: try InAppMessageChecker.estimateWidth(for: url, acceptNegativeValue: false, source: \URL.pathComponents, component: .identifiable(image))
            ),
            action: InAppImageView.Configuration.Action(
                analyticsIdentifier: image.id,
                action: action.flatMap {
                    try? InAppMessageChecker.action(
                        action: $0,
                        source: \InAppAction.params,
                        component: component
                    )
                }
            ),
            accessibility: InAppImageView.Configuration.Accessibility(
                label: contentDescription
            )
        )
    }

    // MARK: -

    /// Create configuration struct for button
    /// - Parameters:
    ///   - text: Button's text
    ///   - codable: Button's codable
    /// - Returns: The configuration
    static func button(
        text: String?,
        action: InAppAction?,
        button: InAppButton
    ) throws -> InAppButtonView.Configuration {
        let component: InAppMessageChecker.Component = .identifiable(button)

        return InAppButtonView.Configuration(
            content: InAppButtonView.Configuration.Content(
                text: try InAppMessageChecker.text(
                    for: text,
                    mandatory: .false(""),
                    source: \String.self,
                    component: component
                )
            ),
            fontStyle: InAppButtonView.Configuration.FontStyle(
                fontSize: try InAppMessageChecker.fontSize(
                    for: button.fontSize,
                    mandatory: .false(12),
                    source: \InAppButton.fontSize,
                    component: component
                ),
                fontDecoration: button.fontDecoration
            ),
            style: InAppButtonView.Configuration.Style(
                backgroundColor: try InAppMessageChecker.colors(
                    for: button.backgroundColor,
                    mandatory: .false(transparentColor),
                    source: \InAppButton.backgroundColor,
                    component: component
                ),
                radius: try InAppMessageChecker.radius(
                    for: button.radius,
                    mandatory: .false(4),
                    source: \InAppButton.radius,
                    component: component
                ),
                borderWidth: try InAppMessageChecker.borderWidth(
                    for: button.borderWidth,
                    mandatory: .false(0),
                    source: \InAppButton.borderWidth,
                    component: component
                ),
                borderColor: try button.borderColor.map { try InAppMessageChecker.colors(
                    for: $0,
                    mandatory: .false(transparentColor),
                    source: \InAppButton.borderColor,
                    component: component
                ) },
                textAlign: try InAppMessageChecker.horizontalAlignment(
                    for: button.textAlign,
                    mandatory: .false(.center),
                    source: \InAppButton.textAlign,
                    component: component
                ),
                textColor: try InAppMessageChecker.colors(
                    for: button.textColor,
                    mandatory: .false(fallbackColor),
                    source: \InAppButton.textColor,
                    component: component
                ),
                maxLines: try InAppMessageChecker.maxLines(
                    for: button.maxLines,
                    mandatory: .false(0),
                    source: \InAppButton.maxLines,
                    component: component
                )
            ),
            placement: InAppButtonView.Configuration.Placement(
                margins: try InAppMessageChecker.margins(
                    for: button.margin,
                    mandatory: .false(0),
                    source: \InAppButton.margin,
                    component: component
                ),
                widthType: button.width.map(InAppWidthType.init(stringValue:)) ?? .percent(value: 100),
                paddings: try InAppMessageChecker.paddings(
                    for: button.padding,
                    mandatory: .false(0),
                    source: \InAppButton.padding,
                    component: .identifiable(button)
                ),
                horizontalAlignment: try InAppMessageChecker.horizontalAlignment(
                    for: button.align,
                    mandatory: .false(.center),
                    source: \InAppButton.align,
                    component: component
                )
            ),
            action: InAppButtonView.Configuration.Action(
                analyticsIdentifier: button.id,
                action: action.flatMap {
                    try? InAppMessageChecker.action(
                        action: $0,
                        source: \InAppAction.params,
                        component: component
                    )
                }
            )
        )
    }

    // MARK: -

    /// Create configuration struct for label
    /// - Parameters:
    ///   - text: Text's url
    ///   - codable: Text's codable
    /// - Returns: The configuration
    static func label(
        text: String?,
        label: InAppLabel
    ) throws -> InAppLabelView.Configuration {
        return InAppLabelView.Configuration(
            content: InAppLabelView.Configuration.Content(
                text: try InAppMessageChecker.text(
                    for: text,
                    mandatory: .false(""),
                    source: \String.self,
                    component: .identifiable(label)
                )
            ),
            fontStyle: InAppLabelView.Configuration.FontStyle(
                fontSize: try InAppMessageChecker.fontSize(
                    for: label.fontSize,
                    mandatory: .false(12),
                    source: \InAppLabel.fontSize,
                    component: .identifiable(label)
                ),
                fontDecoration: label.fontDecoration
            ),
            style: InAppLabelView.Configuration.Style(
                textAlign: try InAppMessageChecker.horizontalAlignment(
                    for: label.textAlign,
                    mandatory: .false(.center),
                    source: \InAppLabel.textAlign,
                    component: .identifiable(label)
                ),
                color: try InAppMessageChecker.colors(
                    for: label.color,
                    mandatory: .false(fallbackColor),
                    source: \InAppButton.backgroundColor,
                    component: .identifiable(label)
                ),
                maxLines: try InAppMessageChecker.maxLines(
                    for: label.maxLines,
                    mandatory: .false(0),
                    source: \InAppButton.maxLines,
                    component: .identifiable(label)
                )
            ),
            placement: InAppLabelView.Configuration.Placement(
                margins: try InAppMessageChecker.margins(
                    for: label.margin,
                    mandatory: .false(0),
                    source: \InAppLabel.margin,
                    component: .identifiable(label)
                )
            )
        )
    }

    // MARK: -

    /// Create configuration struct for columns
    /// - Parameters:
    ///   - urls: Urls' content
    ///   - texts: Texts' content
    ///   - codable: Columns' codable
    /// - Returns: The configuration
    @MainActor
    static func columns(
        urls: [String: String],
        texts: [String: String],
        actions: [String: InAppAction],
        columns: InAppColumns
    ) throws -> InAppColumnsView.Configuration {
        let component: InAppMessageChecker.Component = .identifier("Columns")

        return InAppColumnsView.Configuration(
            builders: InAppAnyObjectTypeBuilder.build(
                urls: urls,
                texts: texts,
                actions: actions,
                componentTypes: columns.children
            ),
            ratios: InAppMessageChecker.ratio(
                for: columns.ratios,
                count: columns.children.count,
                mandatory: .true,
                source: \InAppColumns.ratios,
                component: component
            ),
            style: InAppColumnsView.Configuration.Style(
                spacing: try InAppMessageChecker.integer(
                    for: columns.spacing,
                    mandatory: .false(0),
                    acceptNegativeValue: false,
                    source: \InAppColumns.spacing,
                    component: component
                ),
                verticalAlignment: try InAppMessageChecker.verticalAlignment(
                    for: columns.contentAlign,
                    mandatory: .false(.center),
                    source: \InAppColumns.contentAlign,
                    component: component
                )
            ),
            placement: InAppColumnsView.Configuration.Placement(
                margins: try InAppMessageChecker.margins(
                    for: columns.margin,
                    mandatory: .false(0),
                    source: \InAppColumns.margin,
                    component: component
                )
            )
        )
    }
}
