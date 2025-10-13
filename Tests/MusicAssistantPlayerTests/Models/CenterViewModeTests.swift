import XCTest
@testable import MusicAssistantPlayer

final class CenterViewModeTests: XCTestCase {
    func testCenterViewModeCases() {
        let library = CenterViewMode.library
        let expanded = CenterViewMode.expandedNowPlaying

        XCTAssertNotEqual(library, expanded)
    }
}
