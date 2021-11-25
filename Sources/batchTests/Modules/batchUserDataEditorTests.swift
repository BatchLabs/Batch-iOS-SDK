import Foundation
import XCTest
import InstantMock
import Batch
import Batch.Batch_Private

fileprivate let invalidKeys = [
    "KEY_THAT_IS_WAY_TOO_LONG_LOREM_IPSUM_DOLOR",
    "i$nvalid_chars1$",
    "⛷"
]

class UserDataEditorTests: XCTestCase {
    
    func testModernAttributeMethods() throws {
        let datasource = MockUserDatasource()
        let url = URL(string:"https://batch.com")
        
        let _ = BAInjection.overlayProtocol(BAUserDatasourceProtocol.self, returnedInstance: datasource)
        
        datasource.expect().call(
            datasource.setBoolAttribute(Arg.eq(true), forKey: Arg.eq("boolattr"))
        )
        datasource.expect().call(
            datasource.setLongLongAttribute(Arg.eq(20), forKey: Arg.eq("intattr"))
        )
        datasource.expect().call(
            datasource.setLongLongAttribute(Arg.eq(20), forKey: Arg.eq("longlongattr"))
        )
        datasource.expect().call(
            datasource.setDateAttribute(Arg.eq(Date(timeIntervalSince1970: 12345)), forKey: Arg.eq("dateattr"))
        )
        datasource.expect().call(
            datasource.setDoubleAttribute(Arg.eq(1.234), forKey: Arg.eq("doubleattr"))
        )
        datasource.expect().call(
            datasource.setDoubleAttribute(Arg.eq(Double(1.234 as Float)), forKey: Arg.eq("floatattr"))
        )
        datasource.expect().call(
            datasource.setStringAttribute(Arg.eq("foo"), forKey: Arg.eq("stringattr"))
        )
        datasource.expect().call(
            datasource.setURLAttribute(Arg.eq(url!), forKey: Arg.eq("urlattr"))
        )
        
        let editor = BAUserDataEditor()
        try editor.setAttribute(true, forKey: "boolattr")
        try editor.setAttribute(20 as Int, forKey: "intattr")
        try editor.setAttribute(20 as Int64, forKey: "longlongattr")
        try editor.setAttribute(Date(timeIntervalSince1970: 12345), forKey: "dateattr")
        try editor.setAttribute(1.234 as Double, forKey: "doubleattr")
        try editor.setAttribute(1.234 as Float, forKey: "floatattr")
        try editor.setAttribute("foo", forKey: "stringattr")
        try editor.setAttribute(url!, forKey: "urlattr")

        editor.writeToDatasource(changes: editor.operationQueue(), changeset: 1)
        
        datasource.verify()
    }
    
    func testNSNumbers() throws {
        let datasource = MockUserDatasource()
        let _ = BAInjection.overlayProtocol(BAUserDatasourceProtocol.self, returnedInstance: datasource)
        
        
        datasource.expect().call(
            datasource.setLongLongAttribute(Arg.eq(21), forKey: Arg.eq("numberattr"))
        )
        datasource.expect().call(
            datasource.setLongLongAttribute(Arg.eq(Int64.max), forKey: Arg.eq("numberlongattr"))
        )
        datasource.expect().call(
            datasource.setBoolAttribute(Arg.eq(true), forKey: Arg.eq("boolattr"))
        )
        datasource.expect().call(
            datasource.setDoubleAttribute(Arg.eq(1.234), forKey: Arg.eq("doubleattr"))
        )
        datasource.expect().call(
            datasource.setDoubleAttribute(Arg.eq(Double(1.234 as Float)), forKey: Arg.eq("floatattr"))
        )
        
        let editor = BAUserDataEditor()
        try editor.setAttribute(NSNumber(value: 21), forKey: "numberattr")
        try editor.setAttribute(NSNumber(value: Int64.max), forKey: "numberlongattr")
        try editor.setAttribute(NSNumber(value: true), forKey: "boolattr")
        try editor.setAttribute(NSNumber(value: 1.234), forKey: "doubleattr")
        try editor.setAttribute(NSNumber(value: 1.234 as Float), forKey: "floatattr")
        editor.writeToDatasource(changes: editor.operationQueue(), changeset: 1)
        
        datasource.verify()
    }
    
    func testDeletion() throws {
        let datasource = MockUserDatasource()
        let _ = BAInjection.overlayProtocol(BAUserDatasourceProtocol.self, returnedInstance: datasource)
        
        
        datasource.expect().call(
            datasource.removeTag(Arg.eq("f0o"), fromCollection: Arg.eq("bar"))
        )
        datasource.expect().call(
            datasource.removeAttributeNamed(Arg.eq("f0obar"))
        )
        // Make sure that the methods are called only once
        // Note that the Any match is matched by the first expectations
        datasource.expect().call(
            datasource.removeTag(Arg.any(), fromCollection: Arg.any()),
            count: 1
        )
        datasource.expect().call(
            datasource.removeAttributeNamed(Arg.any()),
            count: 1
        )
        
        let editor = BAUserDataEditor()
        editor.removeTag("f0o", fromCollection: "bar")
        editor.removeAttribute(forKey: "f0obar")
        
        // Ensure that bad keys are rejected
        for key in invalidKeys {
            editor.removeAttribute(forKey: key);
            editor.removeTag("foo", fromCollection: key);
        }
        
        editor.writeToDatasource(changes: editor.operationQueue(), changeset: 1)
        
        datasource.verify()
    }
    
    func testModernAttributeMethodErrors() {
        
        let url = URL(string:"https://batch.com")
        
        let datasource = MockUserDatasource()
        let _ = BAInjection.overlayProtocol(BAUserDatasourceProtocol.self, returnedInstance: datasource)
        
        datasource.expect().call(
            datasource.setBoolAttribute(Arg.any(), forKey: Arg.any()),
            count: 0
        )
        datasource.expect().call(
            datasource.setLongLongAttribute(Arg.any(), forKey: Arg.any()),
            count: 0
        )
        datasource.expect().call(
            datasource.setLongLongAttribute(Arg.any(), forKey: Arg.any()),
            count: 0
        )
        datasource.expect().call(
            datasource.setDateAttribute(Arg.eq(Date(timeIntervalSince1970: 12345)), forKey: Arg.any()),
            count: 0
        )
        datasource.expect().call(
            datasource.setDoubleAttribute(Arg.any(), forKey: Arg.any()),
            count: 0
        )
        datasource.expect().call(
            datasource.setDoubleAttribute(Arg.any(), forKey: Arg.any()),
            count: 0
        )
        datasource.expect().call(
            datasource.setStringAttribute(Arg.any(), forKey: Arg.any()),
            count: 0
        )
        datasource.expect().call(
            datasource.setURLAttribute(Arg.eq(url!), forKey: Arg.any()),
            count: 0
        )
        
        let editor = BAUserDataEditor()
        for key in invalidKeys {
            assertThrowsError(code: .invalidKey, try editor.setAttribute(true, forKey: key))
            assertThrowsError(code: .invalidKey, try editor.setAttribute(20 as Int, forKey: key))
            assertThrowsError(code: .invalidKey, try editor.setAttribute(20 as Int64, forKey: key))
            assertThrowsError(code: .invalidKey, try editor.setAttribute(Date(timeIntervalSince1970: 12345), forKey: key))
            assertThrowsError(code: .invalidKey, try editor.setAttribute(1.234 as Double, forKey: key))
            assertThrowsError(code: .invalidKey, try editor.setAttribute(1.234 as Float, forKey: key))
            assertThrowsError(code: .invalidKey, try editor.setAttribute("foo", forKey: key))
            assertThrowsError(code: .invalidKey, try editor.setAttribute(url!, forKey: key))
            
        }
        assertThrowsError(code: .invalidValue, try editor.setAttribute("lorem ipsum dolor blalblablalbalblalbalbalb alblalbalbla lbal bla blablalbalblalbalbla balba", forKey: "stringattr"))

        editor.writeToDatasource(changes: editor.operationQueue(), changeset: 1)

        datasource.verify()
    }
    
    func testErrors() {
        let datasource = MockUserDatasource()
        let _ = BAInjection.overlayProtocol(BAUserDatasourceProtocol.self, returnedInstance: datasource)
        
        datasource.expect().call(
            datasource.addTag(Arg.any(), toCollection: Arg.any()),
            count: 0
        )
        datasource.expect().call(
            datasource.setStringAttribute(Arg.any(), forKey: Arg.any()),
            count: 0
        )
        
        let editor = BAUserDataEditor()
        for key in invalidKeys {
            editor.addTag("foo", inCollection: key)
            editor.setAttribute("2" as NSString, forKey: key)
        }
        editor.addTag("lorem ipsum dolor this is a way too long string blabla qsdqdsqdsdqsdqsdqsd", inCollection: "bar")

        editor.writeToDatasource(changes: editor.operationQueue(), changeset: 1)

        datasource.verify()
    }
    
    func testClear() {
        let datasource = MockUserDatasource()
        let _ = BAInjection.overlayProtocol(BAUserDatasourceProtocol.self, returnedInstance: datasource)
        
        datasource.expect().call(
            datasource.clearAttributes()
        )
        datasource.expect().call(
            datasource.clearTags()
        )
        datasource.expect().call(
            datasource.clearTags(fromCollection: Arg.eq("foo"))
        )
        datasource.expect().call(
            datasource.removeAttributeNamed(Arg.eq("foo"))
        )
        
        let editor = BAUserDataEditor()
        editor.clearAttributes()
        editor.clearTags()
        editor.clearTagCollection("foo")
        editor.removeAttribute(forKey: "foo")
        
        editor.writeToDatasource(changes: editor.operationQueue(), changeset: 1)

        datasource.verify()
    }
    
    func assertThrowsError(code: BatchUserDataEditorError.Code, _ expression: @escaping @autoclosure () throws -> Void, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { err in
            if let err = err as? BatchUserDataEditorError {
                XCTAssertEqual(err.code, code, file: file, line: line)
            } else {
                XCTFail("Error should be a BatchUserDataEditorError", file: file, line: line)
            }
        }
    }
}

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
