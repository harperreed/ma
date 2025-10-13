import XCTest
@testable import MusicAssistantPlayer

final class LibraryErrorTests: XCTestCase {
    func testLibraryErrorLocalizedDescription() {
        let error = LibraryError.networkError("connection timeout")
        XCTAssertTrue(error.localizedDescription.contains("connection timeout"))
    }

    func testCategoryNotImplemented() {
        let error = LibraryError.categoryNotImplemented(.radio)
        XCTAssertTrue(error.localizedDescription.contains("Radio"))
    }
}
