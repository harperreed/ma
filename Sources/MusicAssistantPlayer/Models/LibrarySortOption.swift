// ABOUTME: Sort options for library browsing
// ABOUTME: Defines available sort criteria for each library category

import Foundation

enum LibrarySortOption: String, CaseIterable {
    case nameAsc = "name"
    case nameDesc = "name_desc"
    case recentlyAdded = "timestamp_added"
    case recentlyPlayed = "timestamp_played"
    case playCount = "play_count"
    case albumCount = "album_count" // Artists only
    case year = "year" // Albums only
    case duration = "duration"

    var displayName: String {
        switch self {
        case .nameAsc: return "Name (A-Z)"
        case .nameDesc: return "Name (Z-A)"
        case .recentlyAdded: return "Recently Added"
        case .recentlyPlayed: return "Recently Played"
        case .playCount: return "Most Played"
        case .albumCount: return "Album Count"
        case .year: return "Year"
        case .duration: return "Duration"
        }
    }

    static func options(for category: LibraryCategory) -> [LibrarySortOption] {
        switch category {
        case .artists:
            return [.nameAsc, .nameDesc, .recentlyAdded, .playCount, .albumCount]
        case .albums:
            return [.nameAsc, .nameDesc, .recentlyAdded, .year, .recentlyPlayed]
        case .tracks:
            return [.nameAsc, .nameDesc, .recentlyAdded, .recentlyPlayed, .playCount]
        case .playlists:
            return [.nameAsc, .nameDesc, .recentlyAdded, .duration]
        case .radio, .genres:
            return [.nameAsc, .nameDesc]
        }
    }
}
