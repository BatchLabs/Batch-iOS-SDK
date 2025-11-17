import UIKit

/// Rewrite of ``BAMSGPannableAlertContainerView`` in Swift to not impact MEP code
/// Handle gesture of scrollview and pan
class PannableAlertContainerView: BAMSGBaseContainerView, BAMSGPannableContainerView {
    private static let animationDuration: TimeInterval = 0.5
    private static let animationDurationFast: TimeInterval = 0.2
    private static let translationPanMultiplier: CGFloat = 0.4
    private static let scalePanMultiplier: CGFloat = 0.0002
    private static let dismissableTargetAlpha: CGFloat = 0.6
    private static let dismissThresholdMinimumVelocity: CGFloat = 1000
    private static let smallestScaleRatio: CGFloat = 0.85
    private static let scaleRatioDismissThreshold: CGFloat = 0.96

    weak var delegate: BAMSGPannableContainerViewDelegate?

    /**
     Lock interaction vertically if true. Allowed in all directions if false.
     Default to YES.
     */
    var lockVertically: Bool = true

    /**
     If true, snap the view back in default position when dismissing.
     Default to YES.
     */
    var resetPositionOnDismiss: Bool = false

    weak var scrollableContentView: UIScrollView?

    private var panGesture: UIPanGestureRecognizer!

    private weak var linkedView: UIView?

    //  Gesture recognizer state dependent variable
    private var shouldDismiss: Bool = false
    private var hapticFeedbackGenerator: BATImpactFeedbackGenerator?
    private var linkedViewInitialOffset: CGPoint = .zero
    private var initialAlpha: CGFloat = 0.0
    private var linkedViewInitialAlpha: CGFloat = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestureRecognizer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestureRecognizer()
    }

    private func setupGestureRecognizer() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewDragged(_:)))
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
    }

    //  MARK: - Gesture Handling Logic

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    )
        -> Bool
    {
        //  Allow the pan gesture and the scroll view's gestures to work together.
        //  This is crucial for proper scrolling while also allowing the view to be dragged.
        if gestureRecognizer == panGesture, let otherView = otherGestureRecognizer.view, otherView is UIScrollView {
            return true
        }
        return false
    }

    @objc private func viewDragged(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .changed, let scrollableContentView {
            let isAtBeginning = scrollableContentView.contentOffset.y == 0
            let isAtEnd = scrollableContentView.contentOffset.y + scrollableContentView.bounds.size.height == scrollableContentView.contentSize.height

            if lockVertically {
                if !isAtBeginning, !isAtEnd {
                    recognizer.isEnabled = false  //  Temporarily disable the gesture
                    recognizer.isEnabled = true  //  Re-enable for future attempts
                    return  //  Exit, don't process the pan
                }
            } else {
                if scrollableContentView.contentOffset.x != 0 || (!isAtBeginning && !isAtEnd) {
                    recognizer.isEnabled = false
                    recognizer.isEnabled = true
                    return
                }
            }
        }

        configureHapticFeedback(for: recognizer.state)

        switch recognizer.state {
        case .began:
            initialAlpha = self.alpha
            linkedViewInitialAlpha = linkedView?.alpha ?? 1.0  //  Default to 1.0 if nil
            if let linkedView {
                linkedViewInitialOffset = CGPoint(
                    x: self.center.x - linkedView.center.x,
                    y: self.center.y - linkedView.center.y
                )
            }
            shouldDismiss = false
        case .changed:
            applyTransformForPanChange(recognizer)
        case .ended:
            panEnded(recognizer)
        case .failed, .cancelled:
            shouldDismiss = false
        default:
            break
        }
    }

    private func configureHapticFeedback(for state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            hapticFeedbackGenerator = BATImpactFeedbackGenerator(style: .medium)
            hapticFeedbackGenerator?.prepare()
        case .cancelled, .failed, .ended:
            hapticFeedbackGenerator = nil
        default:
            break
        }
    }

    private func applyTransformForPanChange(_ recognizer: UIPanGestureRecognizer) {
        guard let superview else { return }

        let translation = recognizer.translation(in: superview)
        let scaleRatioVertical = min(1, max(Self.smallestScaleRatio, 1 + (-1 * abs(translation.y) * Self.scalePanMultiplier)))
        let scaleRatioHorizontal = min(1, max(Self.smallestScaleRatio, 1 + (-1 * abs(translation.x) * Self.scalePanMultiplier)))

        let scaleRatio = min(scaleRatioVertical, scaleRatioHorizontal)

        // Use panStartOffsetY to a better transform
        let translationTransform = CGAffineTransform(
            translationX: lockVertically ? 0 : translation.x * Self.translationPanMultiplier,
            y: translation.y * Self.translationPanMultiplier
        )
        self.transform = translationTransform.scaledBy(x: scaleRatio, y: scaleRatio)
        if let linkedView {
            linkedView.transform = self.transform.translatedBy(
                x: linkedViewInitialOffset.x - (linkedViewInitialOffset.x * scaleRatio),
                y: linkedViewInitialOffset.y - (linkedViewInitialOffset.y * scaleRatio)
            )
        }

        if scaleRatio <= Self.scaleRatioDismissThreshold {
            if !shouldDismiss {
                shouldDismiss = true
                shouldDismissChanged()
            }
        } else {
            if shouldDismiss {
                shouldDismiss = false
                shouldDismissChanged()
            }
        }
    }

    private func shouldDismissChanged() {
        hapticFeedbackGenerator?.impactOccurred()
        hapticFeedbackGenerator?.prepare()

        //  Copy to make sure we get the state when the animation is triggered
        let shouldDismiss = self.shouldDismiss
        UIView.animate(withDuration: Self.animationDurationFast) {
            self.alpha = shouldDismiss ? Self.dismissableTargetAlpha : self.initialAlpha
            self.linkedView?.alpha = shouldDismiss ? Self.dismissableTargetAlpha : self.linkedViewInitialAlpha
        }
    }

    private func panEnded(_ recognizer: UIPanGestureRecognizer) {
        var willDismiss = false
        let velocity = recognizer.velocity(in: superview)
        let dismissY = abs(velocity.y) >= Self.dismissThresholdMinimumVelocity
        let dismissX = (abs(velocity.x) >= Self.dismissThresholdMinimumVelocity) && !lockVertically
        if shouldDismiss || dismissY || dismissX {
            delegate?.pannableContainerWasDismissed(self)
            willDismiss = true
        }
        shouldDismiss = false

        if !willDismiss || (resetPositionOnDismiss && !UIAccessibility.isReduceMotionEnabled) {
            resetAnimated()
        }
    }

    private func resetAnimated() {
        UIView.animate(
            withDuration: Self.animationDurationFast,
            delay: 0,
            options: .allowUserInteraction
        ) {
            self.alpha = self.initialAlpha
            self.linkedView?.alpha = self.linkedViewInitialAlpha
        } completion: { _ in
        }

        if UIAccessibility.isReduceMotionEnabled {
            //  Put back view with a simple translation
            UIView.animate(withDuration: Self.animationDuration) {
                self.transform = .identity
                self.linkedView?.transform = .identity
            }
        } else {
            //  Spring animation
            UIView.animate(
                withDuration: Self.animationDuration,
                delay: 0,
                usingSpringWithDamping: 0.5,
                initialSpringVelocity: 0,
                options: [.curveEaseInOut, .allowUserInteraction]
            ) {
                self.transform = .identity
                self.linkedView?.transform = .identity
            } completion: { _ in
            }
        }
    }

    //  MARK: - View linking

    func setLinkedView(_ linkedView: UIView) {
        self.linkedView = linkedView
    }
}

//  MARK: - UIGestureRecognizerDelegate (extension for clarity)

extension PannableAlertContainerView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture, let scrollableContentView {
            let isAtBeginning = scrollableContentView.contentOffset.y == 0
            let isAtEnd = scrollableContentView.contentOffset.y + scrollableContentView.bounds.size.height == scrollableContentView.contentSize.height

            //  Check if the scroll view is scrolled
            if !isAtBeginning, !isAtEnd {
                return false  //  Don't begin pan if scrolled vertically
            }
            if !lockVertically, scrollableContentView.contentOffset.x > 0 {
                return false  // Don't begin pan if scrolled horizontally
            }
        }
        return true  //  Allow other gestures or pan if not the condition
    }
}
