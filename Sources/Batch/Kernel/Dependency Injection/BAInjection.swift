//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation

public extension BAInjection {
    // Inject a Class or Protocol. Structs are not supported.
    static func inject<T>(_ requestedType: T.Type) -> T? {
        // We have a single inject method as "T" matches Protocols in swift
        // The only way to get "is" to work on a protocol is to force downcast it as AnyObject first
        // as T.Type is actually an union. For example, calling `inject(EventTrackerProtocol)` makes
        // requestedType a `EventTrackerProtocol & AnyObject` so we have to narrow it down first.
        // Fortunately AnyObject can be casted as a Protocol so we can then give it to the appropriate
        // Objective-C method!
        if let requestedProtocol = requestedType as AnyObject as? Protocol {
            return __inject(requestedProtocol) as? T
        }
        // Restricting the generic using `where T: AnyObject` or `<T: AnyObject>`
        // should make it so we do not need to do this dangerous cast and
        // would prevent developers from injecting a Struct in this method.
        // BUT, with Xcode 15.3 or lower it results in EXC_BAD_ACCESS for
        // some reason, so we can't use that. Yay!
        return __injectClass(requestedType as! AnyClass) as? T
    }
}
