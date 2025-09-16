//
//  BATGIFFileTests.swift
//  batchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Foundation
import Testing

struct BATGIFFileTests {
    // MARK: - BATGIFFile

    static let kBATGIFFrameMinimumDuration = 0.02
    static let kBATGIFFrameFallbackThreshold = 0.05
    static let kBATGIFFrameDefaultDuration = 0.1

    // MARK: - Frame Duration Processing Tests

    @Test("Improved duration logic should work correctly")
    func testImprovedDurationLogic() async throws {
        // Test the improved if-else logic for frame duration processing
        let testCases: [(input: TimeInterval, expected: TimeInterval, description: String)] = [
            (0.01, 0.1, "Very fast frame (10ms) should fallback to 100ms"),
            (0.03, 0.1, "Fast frame (30ms) should fallback to 100ms"),
            (0.049, 0.1, "Just under threshold (49ms) should fallback to 100ms"),
            (0.05, 0.05, "Exactly at threshold (50ms) should be preserved"),
            (0.06, 0.06, "Above threshold (60ms) should be preserved"),
            (0.08, 0.08, "Normal frame (80ms) should be preserved"),
            (0.15, 0.15, "Slow frame (150ms) should be preserved"),
            (0.01, 0.1, "Edge case: very fast should still fallback"),
        ]

        for testCase in testCases {
            let testData = try #require(createTestGIFData(frameDurations: [testCase.input]), "Could not create test GIF data")
            let gifFile = try #require(try? BATGIFFile(data: testData), "Could not create BATGIFFile")

            if gifFile.frameCount > 0 {
                let frame = gifFile.frame(at: 0)
                let tolerance: TimeInterval = 0.005

                #expect(abs(frame.duration - testCase.expected) <= tolerance,
                        "\(testCase.description): input \(testCase.input)s should result in \(testCase.expected)s, got \(frame.duration)s")
            }
        }
    }

    @Test("Created GIF should have correct frame durations")
    func testCreatedGIFFrameDurations() async throws {
        let durations: [TimeInterval] = [0.01, BATGIFFileTests.kBATGIFFrameFallbackThreshold, BATGIFFileTests.kBATGIFFrameDefaultDuration, BATGIFFileTests.kBATGIFFrameMinimumDuration]
        // Expected durations with your improved logic:
        // 0.01 (< 50ms) → 100ms (fallback)
        // 0.05 (= 50ms) → max(20ms, 50ms) = 50ms (preserved)
        // 0.1 (= 100ms) → max(20ms, 100ms) = 100ms (preserved)
        // 0.02 (< 50ms) → 100ms (fallback)
        let expectedDurations: [TimeInterval] = [BATGIFFileTests.kBATGIFFrameDefaultDuration, BATGIFFileTests.kBATGIFFrameFallbackThreshold, BATGIFFileTests.kBATGIFFrameDefaultDuration, BATGIFFileTests.kBATGIFFrameDefaultDuration]
        let testData = try #require(createTestGIFData(frameDurations: durations), "Could not create test GIF data")
        let gifFile = try #require(try? BATGIFFile(data: testData), "Could not create BATGIFFile from test data")

        // Verify we have the expected number of frames
        #expect(gifFile.frameCount == expectedDurations.count, "Should have \(expectedDurations.count) frames")

        // Verify each frame has the correct duration (after minimum duration clamping)
        for i in 0 ..< min(Int(gifFile.frameCount), expectedDurations.count) {
            let frame = gifFile.frame(at: UInt(i))

            // Allow small tolerance for timing precision
            let actualDuration = frame.duration
            let expectedDuration = expectedDurations[i]

            #expect(actualDuration == expectedDuration,
                    "Frame \(i): expected duration \(expectedDuration)s, got \(actualDuration)s")
        }
    }

    @Test("BATGIFFile should apply minimum duration correctly")
    func testFrameDurationProcessing() async throws {
        // Skip if we can't create test data
        let testData = try #require(createTestGIFData(frameDurations: [0.01, BATGIFFileTests.kBATGIFFrameFallbackThreshold, BATGIFFileTests.kBATGIFFrameMinimumDuration]), "Could not create test GIF data")
        let gifFile = try #require(try? BATGIFFile(data: testData), "Could not create BATGIFFile - may need real GIF data")

        // Verify that frames exist
        #expect(gifFile.frameCount > 0, "GIF file should have at least one frame")

        // Test that minimum duration is enforced
        for i in 0 ..< gifFile.frameCount {
            let frame = gifFile.frame(at: i)
            #expect(frame.duration >= BATGIFFileTests.kBATGIFFrameMinimumDuration,
                    "Frame \(i) duration \(frame.duration) should be at least 20ms")
        }
    }

    @Test("BATGIFFile should handle invalid data gracefully")
    func testInvalidGIFData() throws {
        let invalidData = Data([0x00, 0x01, 0x02, 0x03]) // Not a GIF

        _ = try #require(throws: NSError.self, "Should provide error for invalid data") { try BATGIFFile(data: invalidData) }
    }

    @Test("BATGIFFile should detect potential GIFs correctly")
    func testPotentialGIFDetection() {
        // Valid GIF87a header
        let gif87aData = Data("GIF87a".utf8) + Data([0x00, 0x00])
        #expect(BATGIFFile.isPotentiallyAGif(gif87aData), "Should detect GIF87a")

        // Valid GIF89a header
        let gif89aData = Data("GIF89a".utf8) + Data([0x00, 0x00])
        #expect(BATGIFFile.isPotentiallyAGif(gif89aData), "Should detect GIF89a")

        // Invalid data
        let invalidData = Data("NOTGIF".utf8)
        #expect(!BATGIFFile.isPotentiallyAGif(invalidData), "Should reject non-GIF data")

        // Too short data
        let shortData = Data("GIF".utf8)
        #expect(!BATGIFFile.isPotentiallyAGif(shortData), "Should reject too short data")
    }

    // MARK: - Edge Cases

    @Test("Empty GIF data should be handled safely")
    func testEmptyGIFData() throws {
        let emptyData = Data()

        #expect(!BATGIFFile.isPotentiallyAGif(emptyData), "Empty data should not be detected as GIF")

        _ = try #require(throws: NSError.self, "Should provide error for empty data") { try BATGIFFile(data: emptyData) }
    }

    @Test("Single frame GIF should work correctly")
    func testSingleFrameGIF() async throws {
        let testData = try #require(createTestGIFData(frameDurations: [BATGIFFileTests.kBATGIFFrameDefaultDuration]), "Could not create test GIF data")
        let gifFile = try #require(try? BATGIFFile(data: testData), "Could not create single frame GIF")

        if gifFile.frameCount > 0 {
            let frame = gifFile.frame(at: 0)
            #expect(frame.duration >= BATGIFFileTests.kBATGIFFrameMinimumDuration, "Single frame should respect minimum duration")
        }
    }
}

extension BATGIFFileTests {
    // MARK: - Test Data Creation Helpers

    /// Creates a simple test GIF data with specified frame durations
    private func createTestGIFData(frameDurations: [TimeInterval]) -> Data? {
        guard !frameDurations.isEmpty else { return nil }

        var gifData = Data()

        // GIF89a header (needed for multiple frames and timing)
        gifData.append(contentsOf: [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]) // "GIF89a"

        // Logical screen descriptor
        gifData.append(contentsOf: [
            0x01, 0x00, // Width: 1
            0x01, 0x00, // Height: 1
            0xF0, // Global color table flag, color resolution, sort flag, global color table size
            0x00, // Background color index
            0x00, // Pixel aspect ratio
        ])

        // Global color table (2 colors: black and white)
        gifData.append(contentsOf: [
            0x00, 0x00, 0x00, // Black
            0xFF, 0xFF, 0xFF, // White
        ])

        // Create each frame with its specified duration
        for (index, duration) in frameDurations.enumerated() {
            // Convert duration (seconds) to centiseconds (GIF format)
            let delayInCentiseconds = max(1, Int(duration * 100))
            let delayLow = UInt8(delayInCentiseconds & 0xFF)
            let delayHigh = UInt8((delayInCentiseconds >> 8) & 0xFF)

            // Graphic control extension
            gifData.append(contentsOf: [
                0x21, // Extension introducer
                0xF9, // Graphic control label
                0x04, // Block size
                0x00, // Disposal method, user input flag, transparent color flag
                delayLow, // Delay time low byte
                delayHigh, // Delay time high byte
                0x00, // Transparent color index
                0x00, // Block terminator
            ])

            // Image descriptor
            gifData.append(contentsOf: [
                0x2C, // Image separator
                0x00, 0x00, // Left position
                0x00, 0x00, // Top position
                0x01, 0x00, // Width: 1
                0x01, 0x00, // Height: 1
                0x00, // Local color table flag, interlace flag, sort flag, local color table size
            ])

            // Image data (minimal LZW compressed data for 1x1 pixel)
            let colorIndex = index % 2 // Alternate between black and white
            gifData.append(contentsOf: [
                0x02, // LZW minimum code size
                0x02, // Data sub-block size
                0x44, // LZW data for single pixel
                UInt8(colorIndex), // Color index (0 or 1)
                0x00, // Data sub-block terminator
            ])
        }

        // Application extension for looping (optional but good for multi-frame GIFs)
        if frameDurations.count > 1 {
            gifData.append(contentsOf: [
                0x21, // Extension introducer
                0xFF, // Application extension label
                0x0B, // Block size
                // "NETSCAPE2.0"
                0x4E, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2E, 0x30,
                0x03, // Data sub-block size
                0x01, // Loop indicator
                0x00, 0x00, // Loop count (0 = infinite)
                0x00, // Data sub-block terminator
            ])
        }

        // GIF trailer
        gifData.append(0x3B)

        return gifData
    }
}
