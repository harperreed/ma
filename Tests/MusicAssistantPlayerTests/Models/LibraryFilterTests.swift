// ABOUTME: Tests for LibraryFilter struct
// ABOUTME: Validates filter options for library browsing

import XCTest
@testable import MusicAssistantPlayer

final class LibraryFilterTests: XCTestCase {
    func testEmptyFilter() {
        let filter = LibraryFilter()
        XCTAssertTrue(filter.isEmpty)
        XCTAssertNil(filter.provider)
        XCTAssertNil(filter.genre)
        XCTAssertNil(filter.yearRange)
        XCTAssertFalse(filter.favoriteOnly)
    }

    func testFilterWithProvider() {
        var filter = LibraryFilter()
        filter.provider = "spotify"
        XCTAssertFalse(filter.isEmpty)
    }

    func testFilterWithFavoriteOnly() {
        var filter = LibraryFilter()
        filter.favoriteOnly = true
        XCTAssertFalse(filter.isEmpty)
    }

    func testFilterWithYearRange() {
        var filter = LibraryFilter()
        filter.yearRange = 2000...2020
        XCTAssertFalse(filter.isEmpty)
    }

    func testFilterWithGenre() {
        var filter = LibraryFilter()
        filter.genre = "Rock"
        XCTAssertFalse(filter.isEmpty)
    }

    func testToAPIArgsEmpty() {
        let filter = LibraryFilter()
        let args = filter.toAPIArgs()
        XCTAssertTrue(args.isEmpty)
    }

    func testToAPIArgsWithProvider() {
        var filter = LibraryFilter()
        filter.provider = "spotify"
        let args = filter.toAPIArgs()
        XCTAssertEqual(args["provider"] as? String, "spotify")
    }

    func testToAPIArgsWithGenre() {
        var filter = LibraryFilter()
        filter.genre = "Rock"
        let args = filter.toAPIArgs()
        XCTAssertEqual(args["genre"] as? String, "Rock")
    }

    func testToAPIArgsWithYearRange() {
        var filter = LibraryFilter()
        filter.yearRange = 2000...2020
        let args = filter.toAPIArgs()
        XCTAssertEqual(args["year_min"] as? Int, 2000)
        XCTAssertEqual(args["year_max"] as? Int, 2020)
    }

    func testToAPIArgsWithFavoriteOnly() {
        var filter = LibraryFilter()
        filter.favoriteOnly = true
        let args = filter.toAPIArgs()
        XCTAssertEqual(args["favorite"] as? Bool, true)
    }

    func testToAPIArgsWithAllFilters() {
        var filter = LibraryFilter()
        filter.provider = "spotify"
        filter.genre = "Rock"
        filter.yearRange = 2000...2020
        filter.favoriteOnly = true

        let args = filter.toAPIArgs()
        XCTAssertEqual(args["provider"] as? String, "spotify")
        XCTAssertEqual(args["genre"] as? String, "Rock")
        XCTAssertEqual(args["year_min"] as? Int, 2000)
        XCTAssertEqual(args["year_max"] as? Int, 2020)
        XCTAssertEqual(args["favorite"] as? Bool, true)
    }
}
