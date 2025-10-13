import XCTest
@testable import MusicAssistantPlayer

final class ArtistTests: XCTestCase {
    func testArtistInitialization() {
        let artist = Artist(
            id: "artist-123",
            name: "Test Artist",
            artworkURL: URL(string: "https://example.com/art.jpg"),
            albumCount: 5
        )

        XCTAssertEqual(artist.id, "artist-123")
        XCTAssertEqual(artist.name, "Test Artist")
        XCTAssertEqual(artist.artworkURL?.absoluteString, "https://example.com/art.jpg")
        XCTAssertEqual(artist.albumCount, 5)
    }

    func testArtistWithoutArtwork() {
        let artist = Artist(
            id: "artist-456",
            name: "Another Artist",
            artworkURL: nil,
            albumCount: 0
        )

        XCTAssertNil(artist.artworkURL)
        XCTAssertEqual(artist.albumCount, 0)
    }
}
