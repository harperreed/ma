// ABOUTME: Artist model representing a music artist from Music Assistant library
// ABOUTME: Contains artist metadata including name, artwork, and album count

import Foundation

struct Artist: Identifiable, Equatable {
    let id: String
    let name: String
    let artworkURL: URL?
    let albumCount: Int
}
