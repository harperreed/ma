// ABOUTME: Filter options for library browsing
// ABOUTME: Defines available filters for narrowing library results

import Foundation

struct LibraryFilter: Hashable {
    var provider: String?
    var genre: String?
    var yearRange: ClosedRange<Int>?
    var favoriteOnly: Bool = false

    var isEmpty: Bool {
        provider == nil && genre == nil && yearRange == nil && !favoriteOnly
    }

    var cacheKey: String {
        var components: [String] = []
        if let provider = provider { components.append("p:\(provider)") }
        if let genre = genre { components.append("g:\(genre)") }
        if let yearRange = yearRange {
            components.append("y:\(yearRange.lowerBound)-\(yearRange.upperBound)")
        }
        if favoriteOnly { components.append("fav") }
        return components.isEmpty ? "default" : components.joined(separator: "_")
    }

    func toAPIArgs() -> [String: Any] {
        var args: [String: Any] = [:]

        if let provider = provider {
            args["provider"] = provider
        }

        if let genre = genre {
            args["genre"] = genre
        }

        if let yearRange = yearRange {
            args["year_min"] = yearRange.lowerBound
            args["year_max"] = yearRange.upperBound
        }

        if favoriteOnly {
            args["favorite"] = true
        }

        return args
    }
}
