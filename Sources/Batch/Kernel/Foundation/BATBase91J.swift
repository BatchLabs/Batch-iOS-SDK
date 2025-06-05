//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/// Base91J encoder/decoder.
/// Base91J is a format based on Base91, but JSON safe. This implementation is based on the Base91 Java library.
@objcMembers
public class BATBase91J: NSObject {
    private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~'"
    private var encodingMap: [UInt8] = Array(repeating: 0, count: 91)
    private var decodingMap: [UInt8] = Array(repeating: 0xFF, count: 256)

    public struct CorruptedInputError: Error {}

    override public init() {
        super.init()

        prepareMaps()
    }

    public func encode(_ input: Data) -> Data {
        var queue: UInt = 0
        var numBits: UInt = 0
        var n = 0

        // Output working array, it allocates an estimation of what space we will need
        // but the actual used space might be lower. We will account for that when allocating
        // the final NSData with the accurate size.
        // See the Java implementation for why we do this math.
        var output: [UInt8] = Array(repeating: 0, count: Int(ceil(Float64(input.count) * 16.0 / 13.0)))

        for byte in input {
            queue |= UInt(byte) << numBits
            numBits += 8
            if numBits > 13 {
                var v: UInt = queue & 8191

                if v > 88 {
                    queue >>= 13
                    numBits -= 13
                } else {
                    v = queue & 16383
                    queue >>= 14
                    numBits -= 14
                }
                output[n] = encodingMap[Int(v % 91)]
                n += 1
                output[n] = encodingMap[Int(v / 91)]
                n += 1
            }
        }

        if numBits > 0 {
            output[n] = encodingMap[Int(queue % 91)]
            n += 1

            if numBits > 7 || queue > 90 {
                output[n] = encodingMap[Int(queue / 91)]
                n += 1
            }
        }

        return Data(output[0 ..< n])
    }

    public func decode(_ input: Data) throws -> Data {
        var queue: UInt = 0
        var numBits: UInt = 0
        var v: Int = -1
        var n = 0

        // Output working array, it allocates an estimation of what space we will need
        // but the actual used space might be lower. We will account for that when allocating
        // the final NSData with the accurate size.
        // See the Java implementation for why we do this math.
        var output: [UInt8] = Array(repeating: 0, count: Int(ceil(Float64(input.count) * 14.0 / 16.0)))

        for byte in input {
            if decodingMap[Int(byte)] == 0xFF {
                throw CorruptedInputError()
            }

            if v == -1 {
                v = Int(decodingMap[Int(byte)])
            } else {
                v += Int(decodingMap[Int(byte)]) * 91
                queue |= UInt(v) << numBits

                if (v & 8191) > 88 {
                    numBits += 13
                } else {
                    numBits += 14
                }

                while numBits > 7 {
                    output[n] = UInt8(truncatingIfNeeded: queue)
                    n += 1

                    queue >>= 8
                    numBits -= 8
                }

                v = -1
            }
        }

        if v != -1 {
            output[n] = UInt8(queue | UInt(v) << numBits)
            n += 1
        }

        return Data(output[0 ..< n])
    }

    private func prepareMaps() {
        for (index, char) in BATBase91J.alphabet.utf8.enumerated() {
            encodingMap[index] = char
            decodingMap[Int(char)] = UInt8(index)
        }
    }
}
