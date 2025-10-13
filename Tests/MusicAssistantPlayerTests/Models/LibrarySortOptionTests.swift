// ABOUTME: Tests for LibrarySortOption enum
// ABOUTME: Validates sort options for library browsing

import XCTest
@testable import MusicAssistantPlayer

final class LibrarySortOptionTests: XCTestCase {
    func testSortOptionRawValues() {
        XCTAssertEqual(LibrarySortOption.nameAsc.rawValue, "name")
        XCTAssertEqual(LibrarySortOption.nameDesc.rawValue, "name_desc")
        XCTAssertEqual(LibrarySortOption.recentlyAdded.rawValue, "timestamp_added")
        XCTAssertEqual(LibrarySortOption.recentlyPlayed.rawValue, "timestamp_played")
        XCTAssertEqual(LibrarySortOption.playCount.rawValue, "play_count")
        XCTAssertEqual(LibrarySortOption.albumCount.rawValue, "album_count")
        XCTAssertEqual(LibrarySortOption.year.rawValue, "year")
        XCTAssertEqual(LibrarySortOption.duration.rawValue, "duration")
    }

    func testDisplayNames() {
        XCTAssertEqual(LibrarySortOption.nameAsc.displayName, "Name (A-Z)")
        XCTAssertEqual(LibrarySortOption.nameDesc.displayName, "Name (Z-A)")
        XCTAssertEqual(LibrarySortOption.recentlyAdded.displayName, "Recently Added")
        XCTAssertEqual(LibrarySortOption.recentlyPlayed.displayName, "Recently Played")
        XCTAssertEqual(LibrarySortOption.playCount.displayName, "Most Played")
        XCTAssertEqual(LibrarySortOption.albumCount.displayName, "Album Count")
        XCTAssertEqual(LibrarySortOption.year.displayName, "Year")
        XCTAssertEqual(LibrarySortOption.duration.displayName, "Duration")
    }

    func testOptionsForArtists() {
        let options = LibrarySortOption.options(for: .artists)
        XCTAssertTrue(options.contains(.nameAsc))
        XCTAssertTrue(options.contains(.nameDesc))
        XCTAssertTrue(options.contains(.recentlyAdded))
        XCTAssertTrue(options.contains(.playCount))
        XCTAssertTrue(options.contains(.albumCount))
        XCTAssertFalse(options.contains(.year))
    }

    func testOptionsForAlbums() {
        let options = LibrarySortOption.options(for: .albums)
        XCTAssertTrue(options.contains(.nameAsc))
        XCTAssertTrue(options.contains(.nameDesc))
        XCTAssertTrue(options.contains(.recentlyAdded))
        XCTAssertTrue(options.contains(.year))
        XCTAssertTrue(options.contains(.recentlyPlayed))
        XCTAssertFalse(options.contains(.albumCount))
    }

    func testOptionsForTracks() {
        let options = LibrarySortOption.options(for: .tracks)
        XCTAssertTrue(options.contains(.nameAsc))
        XCTAssertTrue(options.contains(.nameDesc))
        XCTAssertTrue(options.contains(.recentlyAdded))
        XCTAssertTrue(options.contains(.recentlyPlayed))
        XCTAssertTrue(options.contains(.playCount))
    }

    func testOptionsForPlaylists() {
        let options = LibrarySortOption.options(for: .playlists)
        XCTAssertTrue(options.contains(.nameAsc))
        XCTAssertTrue(options.contains(.nameDesc))
        XCTAssertTrue(options.contains(.recentlyAdded))
        XCTAssertTrue(options.contains(.duration))
    }
}
