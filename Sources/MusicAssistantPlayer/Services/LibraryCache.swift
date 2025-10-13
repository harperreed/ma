// ABOUTME: In-memory cache for library items to reduce API calls
// ABOUTME: Provides per-category caching with configurable TTL and cache invalidation

import Foundation

@MainActor
class LibraryCache {
    private var cache: [String: CacheEntry] = [:]
    private let ttl: TimeInterval // Time to live in seconds

    init(ttl: TimeInterval = 300) { // 5 minutes default
        self.ttl = ttl
    }

    func set<T>(_ value: T, forKey key: String) {
        let entry = CacheEntry(
            value: value,
            timestamp: Date()
        )
        cache[key] = entry
    }

    func get<T>(forKey key: String) -> T? {
        guard let entry = cache[key] else {
            return nil
        }

        // Check if expired
        if Date().timeIntervalSince(entry.timestamp) > ttl {
            cache.removeValue(forKey: key)
            return nil
        }

        return entry.value as? T
    }

    func clear() {
        cache.removeAll()
    }

    func remove(forKey key: String) {
        cache.removeValue(forKey: key)
    }

    private struct CacheEntry {
        let value: Any
        let timestamp: Date
    }
}
