import Foundation

extension Data {
    init(hexString: String) {
        self.init()
        var startIndex = hexString.startIndex
        if hexString.hasPrefix("0x") {
            startIndex = hexString.index(startIndex, offsetBy: 2)
        }

        while startIndex < hexString.endIndex {
            let endIndex = hexString.index(startIndex, offsetBy: 2, limitedBy: hexString.endIndex) ?? hexString.endIndex
            var substr = hexString[startIndex ..< endIndex] // 1 or 2 bytes
            if substr.count == 1 {
                // Assume 0 for the 2nd char
                substr += "0"
            }
            append(UInt8(substr, radix: 16)!) // This is only for unit tests, force uwrap is ok
            startIndex = endIndex
        }
    }

    var hexString: String {
        reduce("") { $0 + String(format: "%02x", $1) }
    }
}
