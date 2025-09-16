//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Represents the root container view for an in-app message.
/// It is a `UIStackView` that arranges all message components vertically.
public class InAppRootContainerView: UIStackView, InAppClosureDelegate {
    // MARK: - Properties

    let configuration: InAppRootContainerView.Configuration
    let onClosureTap: InAppClosureDelegate.Closure
    let onError: InAppErrorDelegate.Closure

    // MARK: - Initialization

    init(
        configuration: InAppRootContainerView.Configuration,
        onClosureTap: @escaping InAppClosureDelegate.Closure,
        onError: @escaping InAppErrorDelegate.Closure
    ) {
        self.onClosureTap = onClosureTap
        self.configuration = configuration
        self.onError = onError

        super.init(frame: .zero)

        // Arrange all child views vertically.
        axis = .vertical
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    /// Configures the view by building and adding all subviews from the configuration.
    public func configure() throws {
        try configuration.apply(to: self, onClosureTap: onClosureTap, onError: onError)
        configuration.updateExpandables(to: self)
    }
}

// MARK: - Nested Configuration Structs

extension InAppRootContainerView {
    struct Configuration {
        let builder: Builder
        let placement: Placement

        /// Applies the builder configuration to populate the container with views.
        @MainActor
        func apply(
            to container: InAppRootContainerView,
            onClosureTap: @escaping InAppClosureDelegate.Closure,
            onError: @escaping InAppErrorDelegate.Closure
        ) throws {
            try builder.apply(on: container, onClosureTap: onClosureTap, onError: onError)
        }

        /// Post-layout logic to handle expandable "fill" spacers.
        /// This method finds all expandable spacers and constrains their heights to be equal,
        /// which creates a "space-between" or "space-around" distribution effect.
        @MainActor
        public func updateExpandables(
            to container: InAppRootContainerView
        ) {
            var previousExpandableFillView: UIView?
            // Filter for expandable containers and get their immediate subview.
            for expandableView in container.arrangedSubviews.filter({ ($0 as? InAppContainer)?.isExpandable == true }).compactMap(\.subviews.first) {
                if let previousExpandableFillView {
                    // Make the current expandable view's height equal to the previous one.
                    expandableView.heightAnchor.constraint(equalTo: previousExpandableFillView.heightAnchor).isActive = true
                }
                previousExpandableFillView = expandableView
            }
        }
    }
}

extension InAppRootContainerView.Configuration {
    /// Defines placement properties for the root container.
    struct Placement {
        /// Margins to apply around the stack view.
        let margins: UIEdgeInsets
    }

    /// Defines the builder logic for populating the root container.
    struct Builder {
        /// An array of view "blueprints" to be built.
        let viewsBuilder: [InAppViewBuilder]

        /// Iterates through the view builders, creates the views, and adds them to the stack view.
        @MainActor
        func apply(
            on view: InAppRootContainerView,
            onClosureTap: @escaping InAppClosureDelegate.Closure,
            onError: @escaping InAppErrorDelegate.Closure
        ) throws {
            for builder in viewsBuilder {
                let contentView = try builder.content(onClosureTap, onError)
                view.addArrangedSubview(contentView)
            }
        }
    }
}
