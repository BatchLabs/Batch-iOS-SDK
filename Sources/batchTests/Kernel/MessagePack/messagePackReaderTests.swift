import Batch.Batch_Private
import Foundation
import XCTest

// swiftlint:disable force_cast

final class MessagePackReaderTests: XCTestCase {
    func testNil() throws {
        assertUnpack("C0", nil as Bool?) {
            try $0.readNil()
            return nil
        }
    }

    func testBoolean() throws {
        assertUnpack("C2", false) { try $0.readBoolAllowingNil(false) }
        assertUnpack("C3", true) { try $0.readBoolAllowingNil(false) }
    }

    func testUInt() {
        assertUnpack("00", 0) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("01", 1) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("7F", 127) { try $0.readIntegerAllowingNil(false) }
        assertUnpack("CC80", 128) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("CCFF", 255) { try $0.readIntegerAllowingNil(false) }
        assertUnpack("CD0100", 256) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("CD7FFF", 32767) { try $0.readIntegerAllowingNil(false) }
        assertUnpack("CD8000", 32768) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("CE80000000", 2_147_483_648) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("CF7FFFFFFFFFFFFFFF", 9_223_372_036_854_775_807) { try $0.readIntegerAllowingNil(false) }  // Max Int
        assertUnpack("CF8000000000000000", UInt(9_223_372_036_854_775_808)) {
            UInt(truncating: try $0.readIntegerAllowingNil(false))
        }

        assertUnpack("CFFFFFFFFFFFFFFFFF", UInt64(18_446_744_073_709_551_615)) {
            UInt64(truncating: try $0.readIntegerAllowingNil(false))
        }  // Max UInt
    }

    func testInt() {
        assertUnpack("7F", 127) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("FF", -1) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("E0", -32) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("D080", -128) { try $0.readIntegerAllowingNil(false) }
        assertUnpack("D1FF7F", -129) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("D18000", -32768) { try $0.readIntegerAllowingNil(false) }
        assertUnpack("D2FFFF7FFF", -32769) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("D280000000", -2_147_483_648) { try $0.readIntegerAllowingNil(false) }
        assertUnpack("D3FFFFFFFF7FFFFFFF", -2_147_483_649) { try $0.readIntegerAllowingNil(false) }

        assertUnpack("D38000000000000000", Int64(-9_223_372_036_854_775_808)) {
            try Int64(truncating: $0.readIntegerAllowingNil(false))
        }
    }

    func testFloat() {
        assertUnpack("CA00000000", Float(0.0)) { Float(truncating: try $0.readDecimalAllowingNil(false)) }
        assertUnpack("CA3DCCCCCD", Float(0.1)) { Float(truncating: try $0.readDecimalAllowingNil(false)) }
        assertUnpack("CB3FB999999999999A", Double(0.1)) { Double(truncating: try $0.readDecimalAllowingNil(false)) }
        assertUnpack("CABDCCCCCD", Float(-0.1)) { Float(truncating: try $0.readDecimalAllowingNil(false)) }
        assertUnpack("CA42F6E979", Float(123.456)) { Float(truncating: try $0.readDecimalAllowingNil(false)) }
        assertUnpack("CB405EDD2F1A9FBE77", Double(123.456)) { Double(truncating: try $0.readDecimalAllowingNil(false)) }
    }

    func testArray() throws {
        assertUnpack("90", [] as NSArray) { try $0.readArrayAllowingNil(false) as NSArray }
        assertUnpack("91C3", [true] as NSArray) { try $0.readArrayAllowingNil(false) as NSArray }
        assertUnpack("91C0", [nil] as NSArray) { try $0.readArrayAllowingNil(false) as NSArray }
        assertUnpack("92C002", [nil, 2] as NSArray) { try $0.readArrayAllowingNil(false) as NSArray }
        assertUnpack("9102", [2] as NSArray) { try $0.readArrayAllowingNil(false) as NSArray }
        assertUnpack("91810203", [[2: 3]] as NSArray) { try $0.readArrayAllowingNil(false) as NSArray }
        assertUnpack("919102", [[2]] as NSArray) { try $0.readArrayAllowingNil(false) as NSArray }
        assertUnpack("920202", [2, 2] as NSArray) { try $0.readArrayAllowingNil(false) as NSArray }
        assertUnpack("91A3666F6F", ["foo"] as NSArray) { try $0.readArrayAllowingNil(false) as NSArray }
    }

    func testData() throws {
        var data = Data()
        data.append(contentsOf: [0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF])
        assertUnpack("C406FAFBFCFDFEFF", data) { try $0.readDataAllowingNil(false) }
    }

    func testDictionary() throws {
        assertUnpack("80", [:] as NSDictionary) { try $0.readDictionaryAllowingNil(false) as NSDictionary }
        assertUnpack("81A3666F6FA3626172", ["foo": "bar"] as NSDictionary) {
            try $0.readDictionaryAllowingNil(false) as NSDictionary
        }
        assertUnpack("81A3666F6FC0", ["foo": nil] as NSDictionary) {
            try $0.readDictionaryAllowingNil(false) as NSDictionary
        }
        assertUnpack("810203", [2: 3] as NSDictionary) { try $0.readDictionaryAllowingNil(false) as NSDictionary }
        assertUnpack("8102810203", [2: [2: 3]] as NSDictionary) {
            try $0.readDictionaryAllowingNil(false) as NSDictionary
        }
        assertUnpack("81029103", [2: [3]] as NSDictionary) { try $0.readDictionaryAllowingNil(false) as NSDictionary }
        // We can't test dicts with multiple keys easily as the order is not guaranteed in swift
    }

    func testString() throws {
        assertUnpack("A6666F6F626172", "foobar") { try $0.readStringAllowingNil(false) }
        assertUnpack("A6464F4F626172", "FOObar") { try $0.readStringAllowingNil(false) }
        assertUnpack("AA666F6FF09F988A626172", "foo😊bar") { try $0.readStringAllowingNil(false) }
    }

    func assertUnpack<T: Equatable>(
        _ hexData: String, _ expected: T, file: StaticString = #filePath, line: UInt = #line,
        _ readerClosure: (inout BATMessagePackReader) throws -> T
    ) {
        var reader = BATMessagePackReader(data: Data(hexString: hexData))
        let value: T
        do {
            value = try readerClosure(&reader)
            XCTAssertEqual(
                expected, value,
                "Expected \(expected), got \(value)",
                file: file, line: line)
        } catch let err {
            XCTFail("Unpacking \(hexData) threw error '\(err)'", file: file, line: line)
        }
    }
}
