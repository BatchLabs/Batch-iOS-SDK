//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Must only be used in ``InAppMessageChecker``
extension InAppMessageChecker {
    /// UI edge insets helper
    struct InAppUIEdgeInsetsBuilder {
        /// Build ``UIEdgeInsets`` from array
        /// - Parameter array: Insets
        /// - Returns: UIEdgeInsets
        static func build(from array: [Int]?) -> UIEdgeInsets {
            return array.map { UIEdgeInsets(
                top: $0[edge: .top],
                left: $0[edge: .left],
                bottom: $0[edge: .bottom],
                right: $0[edge: .right]
            ) } ?? .zero
        }
    }
}
