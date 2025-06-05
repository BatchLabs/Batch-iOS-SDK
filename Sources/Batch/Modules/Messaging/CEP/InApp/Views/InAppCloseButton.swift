//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Represents an in-app close button
public class InAppCloseButton: UIButton, InAppClosureDelegate, InAppAnalyticDelegate {
    // MARK: -

    let baConfiguration: InAppCloseButton.Configuration
    let onClosureTap: InAppClosureDelegate.Closure
    let analyticTrigger: InAppAnalyticDelegate.Trigger

    // MARK: -

    init(configuration: InAppCloseButton.Configuration, onClosureTap: @escaping InAppClosureDelegate.Closure, analyticTrigger: @escaping InAppAnalyticDelegate.Trigger) {
        self.baConfiguration = configuration
        self.onClosureTap = onClosureTap
        self.analyticTrigger = analyticTrigger

        super.init(frame: .zero)

        baConfiguration.apply(on: self)

        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    @objc func onTap() {
        onClosureTap(nil, nil)
        analyticTrigger(.closed)
    }
}

extension InAppCloseButton {
    struct Configuration {
        // MARK: -

        let style: Style
        let accessibility: Accessibility = Accessibility()

        // MARK: -

        func apply(on button: InAppCloseButton) {
            style.apply(on: button)
            accessibility.apply(on: button)
        }
    }
}

extension InAppCloseButton.Configuration {
    struct Accessibility {
        // MARK: -

        func apply(on button: InAppCloseButton) {
            button.accessibilityLabel = "Close"
        }
    }

    struct Style {
        // MARK: -

        let color: UIColor
        let backgroundColor: UIColor?

        // MARK: -

        func apply(on button: InAppCloseButton) {
            button.configuration = .filled()
            button.configuration?.cornerStyle = .capsule
            button.configuration?.baseBackgroundColor = backgroundColor
            button.configuration?.baseForegroundColor = color
            button.configuration?.image = UIImage(systemName: "xmark")?
                .applyingSymbolConfiguration(.init(pointSize: 10, weight: .bold))

            button.updateConfiguration()
        }
    }
}
