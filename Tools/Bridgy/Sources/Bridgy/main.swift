import Darwin

do {
    try CommandLine.run()
} catch {
    print("Failed: \(error)")
    exit(EXIT_FAILURE)
}