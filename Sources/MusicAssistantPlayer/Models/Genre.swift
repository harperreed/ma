// ABOUTME: Genre model
// ABOUTME: Represents a music genre with item count

import Foundation

struct Genre: Identifiable, Hashable {
    let id: String
    let name: String
    let itemCount: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
