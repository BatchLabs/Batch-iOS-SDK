//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import UIKit

/// Protocol defining the requirements for a view that includes a countdown timer for auto-closing.
protocol InAppViewCountdownClose {
    /// The countdown view to be displayed.
    var countdownView: BAMSGCountdownView { get }

    /// A flag indicating whether the view has been dismissed.
    var isDismissed: Bool { get }

    /// The timestamp when the auto-closing countdown started.
    var autoclosingStartTime: TimeInterval { get set }

    /// The total duration of the auto-closing countdown.
    var autoclosingDuration: TimeInterval { get set }

    /// Sets up the countdown view's layout constraints if needed.
    /// - Parameters:
    ///   - view: The superview in which to set up the countdown view.
    ///   - withSafeArea: A boolean indicating whether to respect safe area layout guides.
    func setupCountdownViewIfNeeded(in view: UIView, withSafeArea: Bool)

    /// A method called when the auto-closing timer finishes.
    func autoclosingDidFire()
}

/// Provides a default implementation of the countdown logic for any `InAppViewController` that conforms to `InAppViewCountdown`.
extension InAppViewCountdownClose where Self: InAppViewController {
    /// Calculates the remaining time for the auto-closing countdown.
    var autoclosingRemainingTime: TimeInterval {
        return autoclosingDuration - (BAUptimeProvider.uptime() - autoclosingStartTime)
    }

    /// Configures and adds the countdown view to the specified superview with appropriate layout constraints.
    /// - Parameters:
    ///   - view: The view to which the countdown view will be added.
    ///   - withSafeArea: Determines if the constraints should be relative to the safe area.
    func setupCountdownViewIfNeeded(in view: UIView, withSafeArea: Bool) {
        // Only proceed if an auto-close delay is configured.
        guard let delay = configuration.closeConfiguration.delay else { return }

        // Set the color of the countdown bar.
        countdownView.setColor(delay.color ?? .clear)

        // Add the countdown view to the hierarchy.
        view.addSubview(countdownView)

        // Basic height constraint for the countdown bar.
        var constraints = [
            countdownView.heightAnchor.constraint(equalToConstant: 2),
        ]

        // Adjust horizontal constraints based on whether the safe area should be respected.
        if withSafeArea {
            constraints += [
                countdownView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: countdownView.trailingAnchor),
            ]
        } else {
            constraints += [
                countdownView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ]
        }

        // Adjust for border width to prevent the countdown bar from overlapping it.
        let additionnalBorderWidth: CGFloat = (configuration.style.borderWidth ?? 0) / 2

        // Determine the vertical constraint (top or bottom anchor) based on the message format and position.
        let anchorConstraint: NSLayoutConstraint
        if configuration.format == .modal {
            switch configuration.placement.position {
                case .top:
                    // For top-aligned modals, the countdown is at the bottom of the view.
                    let bottomAnchor = withSafeArea ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor
                    anchorConstraint = countdownView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -additionnalBorderWidth)
                case .center, .bottom:
                    // For center and bottom-aligned modals, the countdown is at the top.
                    let topAnchor = withSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor
                    anchorConstraint = countdownView.topAnchor.constraint(equalTo: topAnchor, constant: additionnalBorderWidth)
                @unknown default:
                    let topAnchor = withSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor
                    anchorConstraint = countdownView.topAnchor.constraint(equalTo: topAnchor, constant: additionnalBorderWidth)
            }
        } else {
            // For non-modal formats (like banners and webview), the countdown is always at the top.
            let topAnchor = withSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor
            anchorConstraint = countdownView.topAnchor.constraint(equalTo: topAnchor, constant: additionnalBorderWidth)
        }

        // Activate all the determined constraints.
        NSLayoutConstraint.activate(constraints + [anchorConstraint])
    }

    // MARK: - Autoclosing Logic

    /// Starts the auto-closing process if a delay is configured.
    /// - Parameter configuration: The view controller's configuration containing the delay info.
    func startAutoclosingCountdownIfNeeded(configuration: InAppViewController.Configuration) {
        // Ensure there is a delay value to proceed.
        guard let delay = configuration.closeConfiguration.delay else { return }

        // Set the duration and start time for the countdown.
        autoclosingDuration = TimeInterval(delay.value)
        autoclosingStartTime = BAUptimeProvider.uptime()

        // Schedule the dismissal to occur after the specified delay.
        let autoCloseTime = DispatchTime.now().advanced(by: .seconds(delay.value))
        DispatchQueue.main.asyncAfter(deadline: autoCloseTime) { [weak self] in
            self?.internalAutoclosingDidFire()
        }

        // Start the visual animation of the countdown bar.
        doAnimateAutoclosing()
    }

    /// Internal method that is called when the timer fires. It checks if the view has already been dismissed.
    func internalAutoclosingDidFire() {
        guard !isDismissed else { return }
        autoclosingDidFire()
    }

    /// Manages the visual animation of the countdown bar.
    func doAnimateAutoclosing() {
        // Ensure the countdown has a positive duration.
        guard autoclosingDuration > 0 else { return }

        // Set the initial state of the countdown bar based on the remaining time.
        let timeLeft = autoclosingRemainingTime
        countdownView.setPercentage(Float(timeLeft) / Float(autoclosingDuration))

        // Ensure the view's layout is up-to-date before starting the animation.
        countdownView.layoutIfNeeded()

        // Animate the countdown bar from its current state to zero over the remaining time.
        UIView.animate(withDuration: timeLeft, delay: 0, options: .curveLinear, animations: { [weak countdownView] in
            countdownView?.setPercentage(0)
        })
    }
}
