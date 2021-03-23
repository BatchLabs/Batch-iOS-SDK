import Foundation
import Darwin

public struct CommandLine {
    static func run() throws {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.count < 2 {
            print("Usage: bridgy <path to configuration file.json>")
            throw GeneratorError.configurationError
        }

        guard let configPath = arguments[1].realpath else {
            print("Could not make absolute config file path")
            throw GeneratorError.configurationError
        }
        
        print("Using configuration file \(configPath)")
        
        guard let configData = readConfigAtPath(path: configPath) else {
            print("Could not read config file at path: \"\(configPath)\"")
            throw GeneratorError.configurationError
        }
        
        guard let config = try? JSONDecoder().decode(Config.self, from: configData) else {
            print("Could not decode the json file at path: \"\(configPath)\"")
            throw GeneratorError.configurationError
        }

        let basePath = (configPath as NSString).deletingLastPathComponent
        
        // We want to crash on error, so use try!
        try Generator(basePath: basePath, config: config).generate()
    }
}