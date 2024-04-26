//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import Foundation
import InstantMock

class MockUserDatasource: Mock, BAUserDatasourceProtocol {
    func close() {
        super.call()
    }

    func clear() {
        super.call()
    }

    func acquireTransactionLock(withChangeset changeset: Int64) -> Bool {
        super.call(changeset)
        return true
    }

    func commitTransaction() -> Bool {
        super.call()
        return true
    }

    func rollbackTransaction() -> Bool {
        super.call()
        return true
    }

    func setLongLongAttribute(_ attribute: Int64, forKey key: String) -> Bool {
        super.call(attribute, key)
        return true
    }

    func setDoubleAttribute(_ attribute: Double, forKey key: String) -> Bool {
        super.call(attribute, key)
        return true
    }

    func setBoolAttribute(_ attribute: Bool, forKey key: String) -> Bool {
        super.call(attribute, key)
        return true
    }

    func setStringAttribute(_ attribute: String, forKey key: String) -> Bool {
        super.call(attribute, key)
        return true
    }

    func setDateAttribute(_ attribute: Date, forKey key: String) -> Bool {
        super.call(attribute, key)
        return true
    }

    func setURLAttribute(_ attribute: URL, forKey key: String) -> Bool {
        super.call(attribute, key)
        return true
    }

    func removeAttributeNamed(_ attribute: String) -> Bool {
        super.call(attribute)
        return true
    }

    func addTag(_ tag: String, toCollection collection: String) -> Bool {
        super.call(tag, collection)
        return true
    }

    func removeTag(_ tag: String, fromCollection collection: String) -> Bool {
        super.call(tag, collection)
        return true
    }

    func clearTags() -> Bool {
        super.call()
        return true
    }

    func clearTags(fromCollection collection: String) -> Bool {
        super.call(collection)
        return true
    }

    func clearAttributes() -> Bool {
        super.call()
        return true
    }

    func attributes() -> [String: BAUserAttribute] {
        super.call()
        return [:]
    }

    func tagCollections() -> [String: Set<String>] {
        super.call()
        return [:]
    }

    func printDebugDump() -> String {
        super.call()
        return "mock"
    }
}
