import Batch.Batch_Private
import Foundation
import XCTest

// swiftlint:disable force_cast

final class MessagePackWriterTests: XCTestCase {

    func testNil() {
        assertPack("C0") { $0.writeNil() }
    }

    func testWriteBoolean() throws {
        assertPack("C2") { $0.write(false) }

        assertPack("C3") { $0.write(true) }

        try assertPack("C2") { try $0.write(false as NSNumber) }

        try assertPack("C3") { try $0.write(true as NSNumber) }
    }

    func testWriteUInt() throws {
        try assertPack("00") { try $0.write(0 as NSNumber) }

        try assertPack("01") { try $0.write(1 as NSNumber) }

        try assertPack("7F") { try $0.write(127 as NSNumber) }

        try assertPack("CC80") { try $0.write(128 as NSNumber) }

        try assertPack("CCFF") { try $0.write(255 as NSNumber) }
        try assertPack("CD0100") { try $0.write(256 as NSNumber) }

        try assertPack("CD7FFF") { try $0.write(32767 as NSNumber) }
        try assertPack("CD8000") { try $0.write(32768 as NSNumber) }

        try assertPack("CE80000000") { try $0.write(2_147_483_648 as NSNumber) }

        try assertPack("CF7FFFFFFFFFFFFFFF") { try $0.write(9_223_372_036_854_775_807 as NSNumber) }  // Max Int
        try assertPack("CF8000000000000000") { try $0.write(UInt(9_223_372_036_854_775_808) as NSNumber) }

        try assertPack("CFFFFFFFFFFFFFFFFF") { try $0.write(UInt(18_446_744_073_709_551_615) as NSNumber) }  // Max UInt

        // Extra pack tests that use different codepaths
        assertPack("7F") { $0.writeUnsignedInt(127) }

        // Creating a NSNumber with a NSInteger type isn't as straightforward as you might think in Swift
        var integerValue: NSInteger = 127
        let integerNumber = CFNumberCreate(nil, CFNumberType.nsIntegerType, &integerValue)
        try assertPack("7F") { try $0.write(integerNumber) }
    }

    func testWriteInt() throws {
        try assertPack("FF") { try $0.write(-1 as NSNumber) }

        try assertPack("E0") { try $0.write(-32 as NSNumber) }
        assertPack("E0") { $0.writeInt(-32) }

        try assertPack("D080") { try $0.write(-128 as NSNumber) }
        try assertPack("D1FF7F") { try $0.write(-129 as NSNumber) }

        try assertPack("D18000") { try $0.write(-32768 as NSNumber) }
        try assertPack("D2FFFF7FFF") { try $0.write(-32769 as NSNumber) }

        try assertPack("D280000000") { try $0.write(-2_147_483_648 as NSNumber) }
        try assertPack("D3FFFFFFFF7FFFFFFF") { try $0.write(-2_147_483_649 as NSNumber) }

        try assertPack("D38000000000000000") { try $0.write(-9_223_372_036_854_775_808 as NSNumber) }
    }

    func testFloat() throws {
        assertPack("CA00000000") { $0.write(Float(0.0)) }
        assertPack("CA3DCCCCCD") { $0.write(Float(0.1)) }
        assertPack("CB3FB999999999999A") { $0.write(Double(0.1)) }
        assertPack("CABDCCCCCD") { $0.write(Float(-0.1)) }
        assertPack("CA42F6E979") { $0.write(Float(123.456)) }
        assertPack("CB405EDD2F1A9FBE77") { $0.write(Double(123.456)) }

        // Also test the NSNumber float endoding
        try assertPack("CA42F6E979") { try $0.write(Float(123.456) as NSNumber) }
        try assertPack("CB405EDD2F1A9FBE77") { try $0.write(Double(123.456) as NSNumber) }
    }

    func testWriteArray() throws {
        try assertPack("C0") {
            let array: [String]? = nil
            try $0.write(array)
        }
        try assertPack("90") { try $0.write([]) }
        try assertPack("91C0") { try $0.write([NSNull()]) }
        try assertPack("9102") { try $0.write([2]) }
        try assertPack("91810203") { try $0.write([[2: 3]]) }
        try assertPack("919102") { try $0.write([[2]]) }
        try assertPack("920202") { try $0.write([2, 2]) }
        try assertPack("91A3666F6F") { try $0.write(["foo"]) }
    }

    func testWriteData() throws {
        var data = Data()
        data.append(contentsOf: [0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF])
        try assertPack("C406FAFBFCFDFEFF") { try $0.writeData(data) }
    }

    func testWriteMap() throws {
        try assertPack("C0") {
            let dict: [String: String]? = nil
            try $0.write(dict)
        }
        try assertPack("80") { try $0.write([:]) }
        try assertPack("81A3666F6FA3626172") { try $0.write(["foo": "bar"]) }
        try assertPack("81A3666F6FC0") { try $0.write(["foo": NSNull()]) }
        try assertPack("810203") { try $0.write([2: 3]) }
        try assertPack("8102810203") { try $0.write([2: [2: 3]]) }
        try assertPack("81029103") { try $0.write([2: [3]]) }
        // We can't test dicts with multiple keys easily as the order is not guaranteed in swift
    }

    func testWriteString() throws {
        try assertPack("A6666F6F626172") { try $0.write("foobar") }
        try assertPack("A6464F4F626172") { try $0.write("FOObar") }
        try assertPack("AA666F6FF09F988A626172") { try $0.write("foo😊bar") }
    }

    func assertPack(
        _ expected: String, _ writer: BATMessagePackWriter, file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual(
            Data(hexString: expected), writer.data,
            "Expected \(expected.uppercased()) Packed \(writer.data.hexString.uppercased())",
            file: file, line: line)
    }

    func assertPack(
        _ expected: String, file: StaticString = #filePath, line: UInt = #line,
        _ writerClosure: (inout BATMessagePackWriter) throws -> Void
    ) rethrows {
        var writer = BATMessagePackWriter()
        try writerClosure(&writer)
        let data = writer.data
        XCTAssertEqual(
            Data(hexString: expected), data,
            "Expected \(expected.uppercased()) Packed \(data.hexString.uppercased())",
            file: file, line: line)
    }
}
