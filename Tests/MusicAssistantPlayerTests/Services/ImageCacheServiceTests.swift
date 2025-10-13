// ABOUTME: Tests for image and color caching service
// ABOUTME: Verifies NSCache-based storage and retrieval of artwork and colors

import XCTest
@testable import MusicAssistantPlayer
#if canImport(AppKit)
import AppKit
import SwiftUI
#endif

@MainActor
final class ImageCacheServiceTests: XCTestCase {
    var cacheService: ImageCacheService!

    override func setUp() async throws {
        cacheService = ImageCacheService()
    }

    func testCacheImageAndRetrieve() {
        let url = URL(string: "https://example.com/image.jpg")!
        let testImage = NSImage(size: NSSize(width: 100, height: 100))

        // Cache image
        cacheService.cacheImage(testImage, for: url)

        // Retrieve image
        let cachedImage = cacheService.getImage(for: url)

        XCTAssertNotNil(cachedImage)
        XCTAssertEqual(cachedImage?.size, testImage.size)
    }

    func testCacheColorAndRetrieve() {
        let url = URL(string: "https://example.com/image.jpg")!
        let testColor = Color.red

        // Cache color
        cacheService.cacheColor(testColor, for: url)

        // Retrieve color
        let cachedColor = cacheService.getColor(for: url)

        XCTAssertNotNil(cachedColor)
    }

    func testCacheMissReturnsNil() {
        let url = URL(string: "https://example.com/nonexistent.jpg")!

        XCTAssertNil(cacheService.getImage(for: url))
        XCTAssertNil(cacheService.getColor(for: url))
    }

    func testClearCache() {
        let url = URL(string: "https://example.com/image.jpg")!
        let testImage = NSImage(size: NSSize(width: 100, height: 100))

        cacheService.cacheImage(testImage, for: url)
        XCTAssertNotNil(cacheService.getImage(for: url))

        cacheService.clearCache()
        XCTAssertNil(cacheService.getImage(for: url))
    }
}
