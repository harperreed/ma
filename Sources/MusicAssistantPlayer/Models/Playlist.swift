// ABOUTME: Playlist model representing a music playlist from Music Assistant library
// ABOUTME: Contains playlist metadata including name, artwork, track count, and owner

import Foundation

struct Playlist: Identifiable, Equatable {
    let id: String
    let name: String
    let artworkURL: URL?
    let trackCount: Int
    let duration: Double
    let owner: String?
}
