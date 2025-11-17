//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

extension InAppViewController {
    struct Configuration {
        // MARK: -

        let format: InAppFormat
        let style: Style
        let placement: Placement
        let content: Content
        let builder: Builder
        let closeConfiguration: CloseConfiguration

        func shouldOverleapSafeArea(size: UIUserInterfaceSizeClass) -> Bool {
            shouldOverleapBottomSafeArea(size: size)
                || shouldOverleapTopSafeArea(size: size)
        }

        private func shouldOverleapSafeArea(margins: UIEdgeInsets, position: InAppVerticalAlignment, size: UIUserInterfaceSizeClass) -> Bool {
            margins == .zero && placement.position == position && format == .modal && size == .compact
        }

        func shouldOverleapBottomSafeArea(size: UIUserInterfaceSizeClass) -> Bool { shouldOverleapSafeArea(margins: placement.margins, position: .bottom, size: size) }
        func shouldOverleapTopSafeArea(size: UIUserInterfaceSizeClass) -> Bool { shouldOverleapSafeArea(margins: placement.margins, position: .top, size: size) }
    }
}

extension InAppViewController.Configuration {
    struct Style: InAppRoundableCorners, InAppBorderable {
        // MARK: -

        let backgroundColor: UIColor?
        let radius: [CGFloat]
        let borderWidth: CGFloat?
        let borderColor: UIColor?

        // MARK: -

        init(backgroundColor: UIColor?, radius: [Int], borderWidth: Int?, borderColor: UIColor?) {
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

    struct Content {
        let message: BAMSGCEPMessage
    }
}
