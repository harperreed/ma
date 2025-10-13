// ABOUTME: Caching service for album artwork images and extracted colors
// ABOUTME: Uses NSCache for automatic memory management and eviction policies

#if canImport(AppKit)
import AppKit
import SwiftUI

@MainActor
class ImageCacheService: ObservableObject {
    private let imageCache = NSCache<NSURL, NSImage>()
    private let colorCache = NSCache<NSURL, ColorWrapper>()

    init() {
        // Configure cache limits
        imageCache.countLimit = 50 // Max 50 images
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB

        colorCache.countLimit = 100 // Colors are small, cache more
    }

    // MARK: - Image Caching

    func cacheImage(_ image: NSImage, for url: URL) {
        imageCache.setObject(image, forKey: url as NSURL)
    }

    func getImage(for url: URL) -> NSImage? {
        return imageCache.object(forKey: url as NSURL)
    }

    // MARK: - Color Caching

    func cacheColor(_ color: Color, for url: URL) {
        let wrapper = ColorWrapper(color: color)
        colorCache.setObject(wrapper, forKey: url as NSURL)
    }

    func getColor(for url: URL) -> Color? {
        return colorCache.object(forKey: url as NSURL)?.color
    }

    // MARK: - Cache Management

    func clearCache() {
        imageCache.removeAllObjects()
        colorCache.removeAllObjects()
    }
}

// NSCache requires reference types, so wrap Color in a class
private class ColorWrapper {
    let color: Color

    init(color: Color) {
        self.color = color
    }
}
#endif
