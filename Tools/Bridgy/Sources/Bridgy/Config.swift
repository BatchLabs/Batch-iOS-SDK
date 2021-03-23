import Foundation

public struct Config : Codable {
    let outputDir: String
    let basePath: String
    let headers: [String: HeaderConfig]

    enum CodingKeys: String, CodingKey {
        case outputDir = "output_directory"
        case basePath = "base_search_path"
        case headers
    }
}

public struct HeaderConfig : Codable {
    let path: String
    let recursive: Bool
    let ignoredNames: String?
    let frameworkName: String?
}

internal func readConfigAtPath(path: String) -> Data? {
    let fm = FileManager.default
    if fm.fileExists(atPath: path) {
        return fm.contents(atPath: path)
    }
    return nil
}
