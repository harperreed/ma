// ABOUTME: Caching service for album artwork images and extracted colors
// ABOUTME: Uses NSCache for automatic memory management and eviction policies

#if canImport(AppKit)
import AppKit
import SwiftUI
import os.log

@MainActor
class ImageCacheService: ObservableObject {
    private let imageCache = NSCache<NSURL, NSImage>()
    private let colorCache = NSCache<NSURL, ColorWrapper>()
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    private var originalCacheLimit: Int = 0

    init() {
        configureCacheForDevice()
        setupMemoryPressureHandling()
    }

    deinit {
        memoryPressureSource?.cancel()
    }

    private func configureCacheForDevice() {
        // Get system memory info
        let physicalMemory = ProcessInfo.processInfo.physicalMemory

        // Calculate cache size: 10% of physical RAM, capped between 50MB and 200MB
        let tenPercentOfRAM = physicalMemory / 10
        let maxCacheMemory = min(max(tenPercentOfRAM, 50 * 1024 * 1024), 200 * 1024 * 1024)

        // Configure image cache with dynamic limits
        originalCacheLimit = Int(maxCacheMemory)
        imageCache.totalCostLimit = originalCacheLimit
        imageCache.countLimit = 100 // Reasonable default for count

        // Color cache is small, use fixed limits
        colorCache.countLimit = 200

        AppLogger.cache.info("Configured image cache: \(maxCacheMemory / 1024 / 1024)MB limit")
    }

    private func setupMemoryPressureHandling() {
        // Create dispatch source for memory pressure monitoring
        // Use .main queue since class is @MainActor
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical, .normal], queue: .main)

        source.setEventHandler { [weak self] in
            guard let self = self else { return }

            let event = source.data

            if event.contains(.critical) {
                AppLogger.cache.warning("Critical memory pressure detected - clearing caches completely")
                self.imageCache.removeAllObjects()
                self.colorCache.removeAllObjects()
                self.imageCache.totalCostLimit = self.originalCacheLimit / 4 // Reduce to 25%
            } else if event.contains(.warning) {
                AppLogger.cache.warning("Memory pressure warning - reducing cache size by 50%")
                self.imageCache.totalCostLimit = self.originalCacheLimit / 2
                // Clear cache and let it rebuild with new smaller limit
                self.imageCache.removeAllObjects()
            } else if event.contains(.normal) {
                AppLogger.cache.info("Memory pressure normalized - restoring cache size")
                self.restoreCacheSize()
            }
        }

        source.resume()
        memoryPressureSource = source

        AppLogger.cache.info("Memory pressure monitoring enabled with DispatchSource")
    }

    private func restoreCacheSize() {
        // Restore original cache limit when memory pressure subsides
        imageCache.totalCostLimit = originalCacheLimit
        AppLogger.cache.info("Cache size restored to \(self.originalCacheLimit / 1024 / 1024)MB")
    }

    // MARK: - Image Caching

    func cacheImage(_ image: NSImage, for url: URL) {
        imageCache.setObject(image, forKey: url as NSURL)
        AppLogger.cache.debug("Cached image for URL: \(url.absoluteString)")
    }

    func getImage(for url: URL) -> NSImage? {
        let image = imageCache.object(forKey: url as NSURL)
        if image != nil {
            AppLogger.cache.debug("Cache hit for image: \(url.absoluteString)")
        }
        return image
    }

    // MARK: - Color Caching

    func cacheColor(_ color: Color, for url: URL) {
        let wrapper = ColorWrapper(color: color)
        colorCache.setObject(wrapper, forKey: url as NSURL)
        AppLogger.cache.debug("Cached color for URL: \(url.absoluteString)")
    }

    func getColor(for url: URL) -> Color? {
        let color = colorCache.object(forKey: url as NSURL)?.color
        if color != nil {
            AppLogger.cache.debug("Cache hit for color: \(url.absoluteString)")
        }
        return color
    }

    // MARK: - Cache Management

    func clearCache() {
        AppLogger.cache.info("Clearing all caches")
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
