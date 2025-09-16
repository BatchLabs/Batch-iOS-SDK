//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// A factory struct responsible for building all necessary `Configuration` objects from a raw `InAppMessage` model.
/// It acts as the central translator between the data layer (`InAppMessage`) and the view layer configurations.
struct InAppMessageBuilder {
    /// A stable identifier for the root container component, used for error reporting.
    static let rootContainerComponent: InAppMessageChecker.Component = .identifier("Root container")

    /// Default fallback color: Black for light mode, White for dark mode.
    static let fallbackColor: (light: String, dark: String) = ("#000000FF", "#FFFFFFFF")

    /// Default transparent color for both light and dark modes.
    static let transparentColor: (light: String, dark: String) = ("#00000000", "#00000000")

    /// Creates the configuration for the root container view (`InAppRootContainerView`).
    /// - Parameter inAppMessage: The raw in-app message data.
    /// - Returns: The configuration for the root container.
    static func rootContainer(
        inAppMessage: InAppMessage
    ) throws -> InAppRootContainerView.Configuration {
        return InAppRootContainerView.Configuration(
            builder: InAppRootContainerView.Configuration.Builder(
                viewsBuilder: try viewBuilders(for: inAppMessage)
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

    /// Assembles an array of `InAppViewBuilder` for each child component in the message.
    /// It also handles special layout logic, such as adding spacers for fullscreen messages to control vertical alignment.
    /// - Parameter inAppMessage: The raw in-app message data.
    /// - Returns: An array of configured `InAppViewBuilder`s.
    static func viewBuilders(for inAppMessage: InAppMessage) throws -> [InAppViewBuilder] {
        var contentViewBuilders = try InAppAnyObjectTypeBuilder.build(
            urls: inAppMessage.urls ?? [:],
            texts: inAppMessage.texts ?? [:],
            actions: inAppMessage.actions ?? [:],
            componentTypes: inAppMessage.root.children,
            format: inAppMessage.format
        ).compactMap { $0 }

        // For fullscreen messages, if no component is expandable, add spacers to correctly
        // position the content (top, center, or bottom).
        if inAppMessage.format == .fullscreen,
           let position = inAppMessage.position,
           contentViewBuilders.allSatisfy({ $0.expandable.isExpandable == false }),
           let component = InAppAnyTypedComponent(InAppSpacer(height: InAppHeightType.fill.rawValue)).component,
           let spacer = try component.uiBuilder(format: inAppMessage.format, urls: [:], texts: [:], actions: [:])
        {
            switch position {
                case .top: // Add a spacer at the bottom to push content up.
                    contentViewBuilders.append(spacer)
                case .bottom: // Add a spacer at the top to push content down.
                    contentViewBuilders.insert(spacer, at: 0)
                case .center: // Add spacers on both sides to center the content.
                    contentViewBuilders.append(spacer)
                    contentViewBuilders.insert(spacer, at: 0)
            }
        }

        return contentViewBuilders
    }

    /// Creates the style configuration for the main view controller.
    /// This includes background color, corner radius, and border styles.
    /// - Parameter inAppMessage: The raw in-app message data.
    /// - Returns: The style configuration.
    static func configurationStyle(inAppMessage: InAppMessage) throws -> InAppViewController.Configuration.Style {
        return InAppViewController.Configuration.Style(
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

    /// The main entry point for creating the complete view controller configuration.
    /// It orchestrates the building of all sub-configurations (style, placement, content, etc.).
    /// - Parameter inAppMessage: The raw in-app message data.
    /// - Returns: The complete configuration for the `InAppViewController`.
    static func configuration(for inAppMessage: InAppMessage, message: BAMSGCEPMessage) throws -> InAppViewController.Configuration {
        let rootContainerConfiguration = try rootContainer(
            inAppMessage: inAppMessage
        )
        return InAppViewController.Configuration(
            format: inAppMessage.format,
            style: try configurationStyle(inAppMessage: inAppMessage),
            placement: InAppViewController.Configuration.Placement(
                position: try InAppMessageChecker.verticalAlignment(
                    for: inAppMessage.position,
                    mandatory: inAppMessage.format == .webview ? .false(.top) : .true,
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
            content: InAppViewController.Configuration.Content(
                message: message
            ),
            builder: InAppViewController.Configuration.Builder(
                viewsBuilder: rootContainerConfiguration.builder.viewsBuilder
            ),
            closeConfiguration: InAppViewController.Configuration.CloseConfiguration(
                // Apply cross sanitization to ensure webview messages have default close button styling
                cross: try InAppMessageChecker.Sanitizer.cross(format: inAppMessage.format, cross: try inAppMessage.closeOptions.button.map(closeCross), source: \InAppMessage.closeOptions.button, component: rootContainerComponent),
                delay: try inAppMessage.closeOptions.auto.map(closeDelay)
            )
        )
    }
}

extension InAppTypedComponent {
    /// Factory method that creates a UI builder (`InAppViewBuilder`) for a given component type.
    /// This method switches on the component's type and delegates the creation of the detailed
    /// configuration to the appropriate static method in `InAppMessageBuilder`.
    /// - Parameters:
    ///   - format: The message format (e.g., modal, fullscreen).
    ///   - urls: A dictionary of all URLs for the message.
    ///   - texts: A dictionary of all text content for the message.
    ///   - actions: A dictionary of all actions for the message.
    /// - Returns: An optional `InAppViewBuilder` instance.
    func uiBuilder(format: InAppFormat, urls: [String: String], texts: [String: String], actions: [String: InAppAction]) throws -> InAppViewBuilder? {
        switch type {
            // Build a button
            case .button:
                guard let button = self as? InAppButton else { return nil }

                let configuration = try InAppMessageBuilder.button(text: texts[button.id], action: actions[button.id], button: button)

                return InAppViewBuilder(component: self, expandable: configuration.placement) { onClosureTap, _ in
                    try InAppContainer(configuration: configuration.placement) {
                        InAppButtonView(configuration: configuration, onClosureTap: onClosureTap)
                    }
                }
            // Build a divider
            case .divider:
                guard let divider = self as? InAppDivider else { return nil }

                let configuration = try InAppMessageBuilder.divider(divider: divider)

                return InAppViewBuilder(component: self, expandable: configuration.placement) { _, _ in
                    try InAppContainer(configuration: configuration.placement) {
                        InAppDividerView(configuration: configuration)
                    }
                }
            // Build a spacer
            case .spacer:
                guard let spacer = self as? InAppSpacer else { return nil }

                let configuration = try InAppMessageBuilder.spacer(spacer: spacer, format: format)

                return InAppViewBuilder(component: self, expandable: configuration.placement) { _, _ in
                    try InAppContainer(configuration: configuration.placement) {
                        InAppSpacerView(configuration: configuration)
                    }
                }
            // Build an image
            case .image:
                guard let image = self as? InAppImage, let urlString = urls[image.id] else { return nil }

                let url = URL(string: urlString) ?? URL(fileURLWithPath: urlString)
                let configuration = try InAppMessageBuilder.image(url: url, action: actions[image.id], image: image, contentDescription: texts[image.id], format: format)

                return InAppViewBuilder(component: self, expandable: configuration.placement) { onClosureTap, onError in
                    try InAppContainer(configuration: configuration.placement) {
                        InAppImageView(configuration: configuration, onClosureTap: onClosureTap, onError: onError)
                    }
                }
            // Build a text label
            case .text:
                guard let label = self as? InAppLabel else { return nil }

                let configuration = try InAppMessageBuilder.label(text: texts[label.id], label: label)

                return InAppViewBuilder(component: self, expandable: configuration.placement) { _, _ in
                    try InAppContainer(configuration: configuration.placement) {
                        InAppLabelView(configuration: configuration)
                    }
                }
            // Build a columns container
            case .columns:
                guard let columns = self as? InAppColumns else { return nil }

                let configuration = try InAppMessageBuilder.columns(urls: urls, texts: texts, actions: actions, columns: columns, format: format)

                return InAppViewBuilder(component: self, expandable: configuration.placement) { onClosureTap, onError in
                    try InAppContainer(configuration: configuration.placement) {
                        InAppColumnsView(configuration: configuration, onClosureTap: onClosureTap, onError: onError)
                    }
                }
            case .webview:
                guard let webview = self as? InAppWebview else { return nil }
                let configuration = try InAppMessageBuilder.webview(
                    webview: webview,
                    urls: urls
                )

                return InAppViewBuilder(component: self, expandable: configuration.placement) { _, onError in
                    try InAppContainer(configuration: configuration.placement) {
                        InAppWebviewView(configuration: configuration, onError: onError)
                    }
                }
        }
    }
}

// MARK: - Component Builders

extension InAppMessageBuilder {
    // MARK: - Close Button Configuration

    /// Creates the configuration for the close button's cross icon.
    /// - Parameter cross: The raw close button cross data.
    /// - Returns: A configured `Cross` object.
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

    /// Creates the configuration for the auto-close delay and countdown timer.
    /// - Parameter delay: The raw delay data.
    /// - Returns: A configured `Delay` object.
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

    // MARK: - Divider Builder

    /// Creates the configuration for a divider view.
    /// - Parameter divider: The raw divider data.
    /// - Returns: A configured `InAppDividerView.Configuration`.
    static func divider(divider: InAppDivider) throws -> InAppDividerView.Configuration {
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

    // MARK: - Spacer Builder

    /// Creates the configuration for a spacer view.
    /// - Parameters:
    ///   - spacer: The raw spacer data.
    ///   - format: The message format.
    /// - Returns: A configured `InAppSpacerView.Configuration`.
    static func spacer(spacer: InAppSpacer, format: InAppFormat) throws -> InAppSpacerView.Configuration {
        let component: InAppMessageChecker.Component = .identifier("Spacer")
        let spacer = InAppMessageBuilderOverrider.expandableComponent(format: format, value: spacer)
        return InAppSpacerView.Configuration(
            placement: InAppSpacerView.Configuration.Placement(
                heightType: try InAppMessageChecker.heightType(
                    for: spacer.flatMap { InAppHeightType(stringValue: $0.height) },
                    mandatory: .false(.fixed(value: 0)),
                    source: \InAppSpacer.height,
                    component: component
                )
            )
        )
    }

    // MARK: - Image Builder

    /// Creates the configuration for an image view.
    /// - Parameters:
    ///   - url: The URL of the image.
    ///   - action: An optional action to perform when the image is tapped.
    ///   - image: The raw image data.
    ///   - contentDescription: The accessibility label for the image.
    /// - Returns: A configured `InAppImageView.Configuration`.
    static func image(url: URL, action: InAppAction?, image: InAppImage, contentDescription: String?, format: InAppFormat) throws -> InAppImageView.Configuration {
        let component: InAppMessageChecker.Component = .identifiable(image)
        let expandable = InAppMessageBuilderOverrider.expandableComponent(format: format, value: image)

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
                heightType: try InAppMessageChecker.heightType(
                    for: expandable.flatMap { InAppHeightType(stringValue: $0.height) },
                    mandatory: .false(.auto),
                    source: \InAppSpacer.height,
                    component: component
                ),
                margins: try InAppMessageChecker.margins(
                    for: image.margin,
                    mandatory: .false(0),
                    source: \InAppImage.margin,
                    component: component
                ),
                estimateHeight: try InAppMessageChecker.estimateHeight(
                    for: url,
                    acceptNegativeValue: false,
                    source: \URL.pathComponents,
                    component: component
                ),

                estimateWidth: try InAppMessageChecker.estimateWidth(
                    for: url,
                    acceptNegativeValue: false,
                    source: \URL.pathComponents,
                    component: component
                )
            ),
            action: InAppImageView.Configuration.Action(
                analyticsIdentifier: image.id,
                action: action.flatMap { try? InAppMessageChecker.action(action: $0, source: \InAppAction.params, component: component) }
            ),
            accessibility: InAppImageView.Configuration.Accessibility(
                label: contentDescription
            )
        )
    }

    // MARK: - Button Builder

    /// Creates the configuration for a button view.
    /// - Parameters:
    ///   - text: The text content of the button.
    ///   - action: An optional action to perform when the button is tapped.
    ///   - button: The raw button data.
    /// - Returns: A configured `InAppButtonView.Configuration`.
    static func button(text: String?, action: InAppAction?, button: InAppButton) throws -> InAppButtonView.Configuration {
        let component: InAppMessageChecker.Component = .identifiable(button)
        return InAppButtonView.Configuration(
            content: InAppButtonView.Configuration.Content(text: try InAppMessageChecker.text(
                for: text,
                mandatory: .false(""),
                source: \String.self,
                component: component
            )),
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
                action: action.flatMap { try? InAppMessageChecker.action(action: $0, source: \InAppAction.params, component: component) }
            )
        )
    }

    // MARK: - Label Builder

    /// Creates the configuration for a text label view.
    /// - Parameters:
    ///   - text: The text content of the label.
    ///   - label: The raw label data.
    /// - Returns: A configured `InAppLabelView.Configuration`.
    static func label(text: String?, label: InAppLabel) throws -> InAppLabelView.Configuration {
        let component: InAppMessageChecker.Component = .identifiable(label)
        return InAppLabelView.Configuration(
            content: InAppLabelView.Configuration.Content(text: try InAppMessageChecker.text(
                for: text, mandatory: .false(""),
                source: \String.self,
                component: component
            )),
            fontStyle: InAppLabelView.Configuration.FontStyle(
                fontSize: try InAppMessageChecker.fontSize(
                    for: label.fontSize,
                    mandatory: .false(12),
                    source: \InAppLabel.fontSize,
                    component: component
                ),
                fontDecoration: label.fontDecoration
            ),

            style: InAppLabelView.Configuration.Style(
                textAlign: try InAppMessageChecker.horizontalAlignment(
                    for: label.textAlign,
                    mandatory: .false(.center),
                    source: \InAppLabel.textAlign,
                    component: component
                ),
                color: try InAppMessageChecker.colors(
                    for: label.color,
                    mandatory: .false(fallbackColor),
                    source: \InAppButton.backgroundColor,
                    component: component
                ),
                maxLines: try InAppMessageChecker.maxLines(
                    for: label.maxLines,
                    mandatory: .false(0),
                    source: \InAppButton.maxLines,
                    component: component
                )
            ),
            placement: InAppLabelView.Configuration.Placement(margins: try InAppMessageChecker.margins(
                for: label.margin,
                mandatory: .false(0),
                source: \InAppLabel.margin,
                component: component
            ))
        )
    }

    // MARK: - Webview Builder

    /// Creates the configuration for a web view.
    /// - Parameters:
    ///   - url: The url.
    /// - Returns: A configured `InAppVebviewView.Configuration`.
    static func webview(webview: InAppWebview, urls: [String: String]) throws -> InAppWebviewView.Configuration {
        let component: InAppMessageChecker.Component = .identifiable(webview)
        return InAppWebviewView.Configuration(
            content: InAppWebviewView.Configuration.Content(
                url: try InAppMessageChecker.url(
                    for: urls[webview.id].flatMap(URL.init(string:)),
                    mandatory: .true,
                    source: \InAppMessage.urls,
                    component: component
                )
            ),
            inAppDeeplinks: webview.inAppDeeplinks,
            devMode: webview.devMode,
            timeout: webview.timeout
        )
    }

    // MARK: - Columns Builder

    /// Creates the configuration for a columns container view.
    /// - Parameters:
    ///   - urls: A dictionary of all URLs for the message.
    ///   - texts: A dictionary of all text content for the message.
    ///   - actions: A dictionary of all actions for the message.
    ///   - columns: The raw columns data.
    ///   - format: The message format.
    /// - Returns: A configured `InAppColumnsView.Configuration`.
    static func columns(urls: [String: String], texts: [String: String], actions: [String: InAppAction], columns: InAppColumns, format: InAppFormat) throws -> InAppColumnsView.Configuration {
        let component: InAppMessageChecker.Component = .identifier("Columns")
        let builders = try InAppAnyObjectTypeBuilder.build(
            urls: urls,
            texts: texts,
            actions: actions,
            componentTypes: columns.children,
            format: format
        )
        return InAppColumnsView.Configuration(
            builders: builders,
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
                    component: component,
                ),
                heightType: builders.contains(where: { $0?.expandable.isExpandable == true }) ? .fill : nil
            )
        )
    }
}
