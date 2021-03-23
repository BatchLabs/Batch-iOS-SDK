//
//  queryTestHelpers.swift
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation

public func makeBasicQueryResponseDictionary() -> [AnyHashable: Any] {
    return ["id": UUID().uuidString]
}
