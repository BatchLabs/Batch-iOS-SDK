//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Represents an in-app root container view
public class InAppRootContainerView: UIStackView, InAppClosureDelegate {
    // MARK: -

    let configuration: InAppRootContainerView.Configuration
    let onClosureTap: InAppClosureDelegate.Closure
    let onError: InAppErrorDelegate.Closure

    // MARK: -

    init(
        configuration: InAppRootContainerView.Configuration,
        onClosureTap: @escaping InAppClosureDelegate.Closure,
        onError: @escaping InAppErrorDelegate.Closure
    ) {
        self.onClosureTap = onClosureTap
        self.configuration = configuration
        self.onError = onError

        super.init(frame: .zero)

        axis = .vertical
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    public func configure() throws {
        try configuration.apply(to: self, onClosureTap: onClosureTap, onError: onError)
    }
}

extension InAppRootContainerView {
    // MARK: -

    struct Configuration {
        // MARK: -

        let builder: Builder
        let placement: Placement

        // MARK: -

        @MainActor
        func apply(
            to container: InAppRootContainerView,
            onClosureTap: @escaping InAppClosureDelegate.Closure,
            onError: @escaping InAppErrorDelegate.Closure
        ) throws {
            try builder.apply(on: container, onClosureTap: onClosureTap, onError: onError)
        }
    }
}

extension InAppRootContainerView.Configuration {
    struct Placement {
        // MARK: -

        let margins: UIEdgeInsets
    }

    struct Builder {
        // MARK: -

        let viewsBuilder: [InAppViewBuilder]

        // MARK: -

        @MainActor
        func apply(
            on view: InAppRootContainerView,
            onClosureTap: @escaping InAppClosureDelegate.Closure,
            onError: @escaping InAppErrorDelegate.Closure
        ) throws {
            try viewsBuilder.forEach { builder in
                let contentView = try builder.content(onClosureTap, onError)

                view.addArrangedSubview(contentView)
            }
        }
    }
}
