//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import XCTest

final class emailTests: XCTestCase {
    func testEmailPatterns() {
        XCTAssertTrue(BAEmailUtils.isValidEmail("foo@batch.com"))
        XCTAssertTrue(BAEmailUtils.isValidEmail("bar@foo.batch.com"))
        XCTAssertTrue(BAEmailUtils.isValidEmail("bar+foo@batch.com"))
        XCTAssertTrue(BAEmailUtils.isValidEmail("FOObar@Test.Batch.COM"))

        XCTAssertFalse(BAEmailUtils.isValidEmail("@gmail.com"))
        XCTAssertFalse(BAEmailUtils.isValidEmail("invalid@gmail"))
        XCTAssertFalse(BAEmailUtils.isValidEmail("inva lid@gmail.com"))
        XCTAssertFalse(BAEmailUtils.isValidEmail("invalid@gmail .com"))
        XCTAssertFalse(BAEmailUtils.isValidEmail("invalid@inva lid.gmail.com"))
    }

    func testEmailIsTooLong() {
        XCTAssertTrue(BAEmailUtils.isEmailTooLong("testastringtoolongtobeanemailtestastringtoolongtobeanemailtestastringtoolongtobeanemailtestastringtoolongtobeanemailtestastringtoo@batch.com"))
        XCTAssertFalse(BAEmailUtils.isEmailTooLong("bar@foo.batch.com"))
    }
}
