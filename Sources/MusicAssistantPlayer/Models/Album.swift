// ABOUTME: Album model representing a music album from Music Assistant library
// ABOUTME: Contains album metadata including title, artist, artwork, track count, and release year

import Foundation

enum AlbumType: String, Codable, CaseIterable {
    case album = "album"
    case single = "single"
    case compilation = "compilation"
    case ep = "ep"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .album: return "Albums"
        case .single: return "Singles"
        case .compilation: return "Compilations"
        case .ep: return "EPs"
        case .unknown: return "Other"
        }
    }

    var sortOrder: Int {
        switch self {
        case .album: return 0
        case .ep: return 1
        case .single: return 2
        case .compilation: return 3
        case .unknown: return 4
        }
    }
}

struct Album: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let artworkURL: URL?
    let trackCount: Int
    let year: Int?
    let duration: Double
    let albumType: AlbumType
}
