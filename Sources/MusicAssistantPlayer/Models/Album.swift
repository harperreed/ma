// ABOUTME: Album model representing a music album from Music Assistant library
// ABOUTME: Contains album metadata including title, artist, artwork, track count, and release year

import Foundation

struct Album: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let artworkURL: URL?
    let trackCount: Int
    let year: Int?
    let duration: Double
}
