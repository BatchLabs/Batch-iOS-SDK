//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Helper to centralize index logic
enum InAppEdgeIndexHelper: Int {
    case top = 0
    case right, bottom, left
}

/// Ease the get of edge inset
extension Collection<Int> {
    subscript(edge value: InAppEdgeIndexHelper) -> CGFloat {
        self.map(CGFloat.init)[edge: value]
    }
}

/// Ease the get of edge inset
extension Collection<CGFloat> {
    subscript(edge value: InAppEdgeIndexHelper) -> CGFloat {
        let index = index(startIndex, offsetBy: value.rawValue)
        return indices.contains(index) ? self[index] : 0
    }
}
