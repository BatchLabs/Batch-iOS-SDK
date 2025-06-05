//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

extension InAppViewController {
    struct Configuration {
        // MARK: -

        let style: Style
        let placement: Placement
        let builder: Builder
        let closeConfiguration: CloseConfiguration

        func shouldOverleapSafeArea(size: UIUserInterfaceSizeClass) -> Bool {
            shouldOverleapBottomSafeArea(size: size)
                || shouldOverleapTopSafeArea(size: size)
        }

        private func shouldOverleapSafeArea(margins: UIEdgeInsets, position: InAppVerticalAlignment, size: UIUserInterfaceSizeClass) -> Bool { margins == .zero && placement.position == position && style.isModal && size == .compact }

        func shouldOverleapBottomSafeArea(size: UIUserInterfaceSizeClass) -> Bool { shouldOverleapSafeArea(margins: placement.margins, position: .bottom, size: size) }
        func shouldOverleapTopSafeArea(size: UIUserInterfaceSizeClass) -> Bool { shouldOverleapSafeArea(margins: placement.margins, position: .top, size: size) }
    }
}

extension InAppViewController.Configuration {
    struct Style: InAppRoundableCorners, InAppBorderable {
        // MARK: -

        let isModal: Bool
        let backgroundColor: UIColor?
        let radius: [CGFloat]
        let borderWidth: CGFloat?
        let borderColor: UIColor?

        // MARK: -

        init(isModal: Bool, backgroundColor: UIColor?, radius: [Int], borderWidth: Int?, borderColor: UIColor?) {
            self.isModal = isModal
            self.backgroundColor = backgroundColor
            self.radius = radius.map(CGFloat.init)
            self.borderWidth = borderWidth.map(CGFloat.init)
            self.borderColor = borderColor
        }
    }

    struct CloseConfiguration {
        // MARK: -

        let cross: Cross?
        let delay: Delay?

        // MARK: -

        init(cross: Cross?, delay: Delay?) {
            self.cross = cross
            self.delay = delay
        }
    }

    struct Placement: InAppContainerizable {
        // MARK: -

        let position: InAppVerticalAlignment
        let margins: UIEdgeInsets
        let horizontalAlignment: InAppHorizontalAlignment? = .left
        let verticalAlignment: InAppVerticalAlignment? = .top
    }

    struct Builder {
        // MARK: -

        var isOnlyOneImage: Bool { viewsBuilder.contains(where: { $0.component.type == .image }) && viewsBuilder.count == 1 }

        let viewsBuilder: [InAppViewBuilder]
    }
}
