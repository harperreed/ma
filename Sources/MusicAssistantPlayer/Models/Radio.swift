// ABOUTME: Radio station model
// ABOUTME: Represents a streaming radio station with metadata

import Foundation

struct Radio: Identifiable, Hashable {
    let id: String
    let name: String
    let artworkURL: URL?
    let provider: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
