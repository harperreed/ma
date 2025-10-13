// ABOUTME: Domain-specific errors for library operations
// ABOUTME: Provides detailed error context for library browsing and search failures

import Foundation

enum LibraryError: Error, LocalizedError {
    case networkError(String)
    case parseError(String)
    case searchFailed(String)
    case categoryNotImplemented(LibraryCategory)
    case noClientAvailable

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .parseError(let message):
            return "Failed to parse library data: \(message)"
        case .searchFailed(let query):
            return "Search failed for query: \(query)"
        case .categoryNotImplemented(let category):
            return "Category not yet implemented: \(category.displayName)"
        case .noClientAvailable:
            return "Music Assistant client not available"
        }
    }
}
