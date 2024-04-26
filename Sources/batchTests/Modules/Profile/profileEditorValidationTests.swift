//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import XCTest

final class profileEditorValidationTests: XCTestCase {
    func testEmailPatterns() {
        XCTAssertTrue(BATProfileDataValidators.isValidEmail("foo@batch.com"))
        XCTAssertTrue(BATProfileDataValidators.isValidEmail("bar@foo.batch.com"))
        XCTAssertTrue(BATProfileDataValidators.isValidEmail("bar+foo@batch.com"))
        XCTAssertTrue(BATProfileDataValidators.isValidEmail("FOObar@Test.Batch.COM"))

        XCTAssertFalse(BATProfileDataValidators.isValidEmail("@gmail.com"))
        XCTAssertFalse(BATProfileDataValidators.isValidEmail("invalid@gmail"))
        XCTAssertFalse(BATProfileDataValidators.isValidEmail("invalid@gmail .com"))
        XCTAssertFalse(BATProfileDataValidators.isValidEmail("in valid@gmail .com"))
        XCTAssertFalse(BATProfileDataValidators.isValidEmail("invalid@inva lid.gmail.com"))
        XCTAssertFalse(BATProfileDataValidators.isValidEmail("inva\nlid@invalid.gmail.com"))
        XCTAssertFalse(BATProfileDataValidators.isValidEmail("in+va\nlid@invalid.gmail.com"))
        XCTAssertFalse(BATProfileDataValidators.isValidEmail("invalid@inv\nalid.gmail.com"))
        XCTAssertFalse(BATProfileDataValidators.isValidEmail("invalid@invalid.gmail.com\n"))
        XCTAssertFalse(BATProfileDataValidators.isValidEmail("\ninvalid@invalid.gmail.com"))
        XCTAssertFalse(BATProfileDataValidators.isValidEmail("inval\rid@invalid.gmail.com\n"))
    }

    func testEmailIsTooLong() {
        XCTAssertTrue(BATProfileDataValidators.isEmailTooLong("testastringtestastringtoolongtobeanemailtestastringtoolongtestastringtoolongtobeanemailtestastringtoolongtestastringtoolongtobeanemailtestastringtoolongtestastringtoolongtobeanemailtestastringtoolongtestastringtoolongtobeanemailtestastringtoolongtoolongtobeanemailtestastringtoolongtobeanemailtestastringtoolongtobeanemailtestastringtoolongtobeanemailtestastringtoo@batch.com"))
        XCTAssertFalse(BATProfileDataValidators.isEmailTooLong("bar@foo.batch.com"))
    }

    func testEditorEmailErrors() {
        let editor = TestProfileEditor()
        editor.test_canSetEmail = true
        XCTAssertNoThrow(try editor.setEmail("test@batch.com"))
        XCTAssertThrowsError(try editor.setEmail("invalid@inva lid.gmail.com"))
        let longEmailPart = String(repeating: "test_too_long", count: 100)
        XCTAssertThrowsError(try editor.setEmail("\(longEmailPart)@batch.com)"))
    }

    func testCustomUserIDValidity() {
        XCTAssertFalse(BATProfileDataValidators.isCustomIDTooLong("customId"))
        XCTAssertTrue(BATProfileDataValidators.isCustomIDTooLong("my_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_idmy_test_id_1111"))
    }
}
