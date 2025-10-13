// Tests/MusicAssistantPlayerTests/Models/LibraryCategoryTests.swift
import XCTest
@testable import MusicAssistantPlayer

final class LibraryCategoryTests: XCTestCase {
    func testLibraryCategoryDisplayNames() {
        XCTAssertEqual(LibraryCategory.artists.displayName, "Artists")
        XCTAssertEqual(LibraryCategory.albums.displayName, "Albums")
        XCTAssertEqual(LibraryCategory.tracks.displayName, "Tracks")
        XCTAssertEqual(LibraryCategory.playlists.displayName, "Playlists")
        XCTAssertEqual(LibraryCategory.radio.displayName, "Radio")
        XCTAssertEqual(LibraryCategory.genres.displayName, "Genres")
    }

    func testLibraryCategoryIcons() {
        XCTAssertEqual(LibraryCategory.artists.iconName, "person.2")
        XCTAssertEqual(LibraryCategory.albums.iconName, "square.stack")
        XCTAssertEqual(LibraryCategory.tracks.iconName, "music.note")
        XCTAssertEqual(LibraryCategory.playlists.iconName, "music.note.list")
        XCTAssertEqual(LibraryCategory.radio.iconName, "dot.radiowaves.left.and.right")
        XCTAssertEqual(LibraryCategory.genres.iconName, "guitars")
    }

    func testAllCasesContainsAllCategories() {
        XCTAssertEqual(LibraryCategory.allCases.count, 6)
        XCTAssertTrue(LibraryCategory.allCases.contains(.artists))
        XCTAssertTrue(LibraryCategory.allCases.contains(.albums))
    }
}
