// ABOUTME: Enumeration of library browsing categories for sidebar navigation
// ABOUTME: Each category has a display name and SF Symbol icon

import Foundation

enum LibraryCategory: String, CaseIterable, Identifiable {
    case artists
    case albums
    case tracks
    case playlists
    case radio
    case genres

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .artists: return "Artists"
        case .albums: return "Albums"
        case .tracks: return "Tracks"
        case .playlists: return "Playlists"
        case .radio: return "Radio"
        case .genres: return "Genres"
        }
    }

    var iconName: String {
        switch self {
        case .artists: return "person.2"
        case .albums: return "square.stack"
        case .tracks: return "music.note"
        case .playlists: return "music.note.list"
        case .radio: return "dot.radiowaves.left.and.right"
        case .genres: return "guitars"
        }
    }

    var apiMediaType: String {
        switch self {
        case .artists:
            return "artist"
        case .albums:
            return "album"
        case .tracks:
            return "track"
        case .playlists:
            return "playlist"
        case .radio:
            return "radio"
        case .genres:
            return "genre"
        }
    }
}
