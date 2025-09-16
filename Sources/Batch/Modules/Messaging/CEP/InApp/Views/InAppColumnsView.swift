//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Represents an in-app columns view
public class InAppColumnsView: UIStackView, InAppContainerizable, InAppClosureDelegate, InAppExpandableView {
    // MARK: -

    let configuration: InAppColumnsView.Configuration
    let onClosureTap: InAppClosureDelegate.Closure
    let onError: InAppErrorDelegate.Closure

    var isExpandable: Bool {
        configuration.placement.isExpandable
    }

    // MARK: -

    init(
        configuration: InAppColumnsView.Configuration,
        onClosureTap: @escaping Closure,
        onError: @escaping InAppErrorDelegate.Closure
    ) {
        self.configuration = configuration
        self.onClosureTap = onClosureTap
        self.onError = onError

        super.init(frame: .zero)

        configure()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    func configure() {
        axis = .horizontal
        distribution = Set(configuration.ratios).count == 1 ? .fillEqually : .fillProportionally
        spacing = CGFloat(configuration.style.spacing)
        alignment = switch configuration.style.verticalAlignment {
            case .top: .top
            case .center: .center
            case .bottom: .bottom
        }

        // Add views
        configuration.builders.enumerated().forEach { index, builder in
            let ratio = CGFloat(configuration.ratios[index])
            let child = InAppPercentedView(percent: ratio)
            child.translatesAutoresizingMaskIntoConstraints = false

            let subchild = (try? builder?.content(onClosureTap, onError)) ?? UIView()

            subchild.translatesAutoresizingMaskIntoConstraints = false

            child.addSubview(subchild)

            var constraints = [
                subchild.leadingAnchor.constraint(equalTo: child.leadingAnchor),
                subchild.trailingAnchor.constraint(equalTo: child.trailingAnchor),
            ]

            if builder?.expandable.isExpandable == true {
                constraints += [
                    subchild.heightAnchor.constraint(equalTo: child.heightAnchor),
                    heightAnchor.constraint(equalTo: child.heightAnchor),
                ]
            } else {
                constraints += [
                    subchild.heightAnchor.constraint(lessThanOrEqualTo: child.heightAnchor),
                ]
            }
            addArrangedSubview(child)

            NSLayoutConstraint.activate(constraints)
        }
    }
}

extension InAppColumnsView {
    struct Configuration {
        // MARK: -

        let builders: [InAppViewBuilder?]
        let ratios: [Int]
        let style: Style
        let placement: Placement
    }
}

extension InAppColumnsView.Configuration {
    struct Style {
        // MARK: -

        let spacing: Int
        let verticalAlignment: InAppVerticalAlignment
    }

    struct Placement: InAppContainerizable {
        // MARK: -

        let margins: UIEdgeInsets
        let heightType: InAppHeightType?
    }
}
