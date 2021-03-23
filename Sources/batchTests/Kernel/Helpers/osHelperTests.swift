//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import XCTest
import Batch.Batch_Private

class osHelperTests: XCTestCase {

    func testIntegerOSVersion() {
        func parse(version: Int) throws -> OperatingSystemVersion {
            var parsedVersion = OperatingSystemVersion(majorVersion: 0, minorVersion: 0, patchVersion: 0)
            if !BAOSHelper.parseIntegerSystemVersion(version, out: &parsedVersion) {
                throw osHelperTestsError.parseError
            }
            return parsedVersion
        }
        
        XCTAssertThrowsError(try parse(version: -1))
        XCTAssertThrowsError(try parse(version: -014000000))
        XCTAssertThrowsError(try parse(version: 0))
        XCTAssertThrowsError(try parse(version: 10))
        XCTAssertThrowsError(try parse(version: 999999))
        
        XCTAssertEqual(OperatingSystemVersion(majorVersion: 1, minorVersion: 0, patchVersion: 0), try parse(version: 001000000))
        XCTAssertEqual(OperatingSystemVersion(majorVersion: 14, minorVersion: 0, patchVersion: 0), try parse(version: 014000000))
        XCTAssertEqual(OperatingSystemVersion(majorVersion: 13, minorVersion: 2, patchVersion: 0), try parse(version: 013002000))
        XCTAssertEqual(OperatingSystemVersion(majorVersion: 10, minorVersion: 12, patchVersion: 04), try parse(version: 010012004))
        XCTAssertEqual(OperatingSystemVersion(majorVersion: 999, minorVersion: 999, patchVersion: 999), try parse(version: 999999999))
        XCTAssertEqual(OperatingSystemVersion(majorVersion: 147, minorVersion: 483, patchVersion: 647), try parse(version: Int(Int32.max)))
    }

}

fileprivate enum osHelperTestsError: Error {
    case parseError
}
