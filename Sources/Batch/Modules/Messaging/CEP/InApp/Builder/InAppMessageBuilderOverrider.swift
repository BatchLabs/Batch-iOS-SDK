//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

// According the format, some properties should be ignored on root container
// Example: margins, radius, border
struct InAppMessageBuilderOverrider {
    static func values<T>(format: InAppFormat, values: T?) -> T? {
        guard format == .modal else { return nil }

        return values
    }
}
