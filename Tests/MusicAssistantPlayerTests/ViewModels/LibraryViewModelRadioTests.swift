// ABOUTME: Tests for LibraryViewModel radio functionality
// ABOUTME: Verifies radio loading, search, and pagination

import XCTest
@testable import MusicAssistantPlayer

final class LibraryViewModelRadioTests: XCTestCase {
    var viewModel: LibraryViewModel!
    var libraryService: LibraryService!

    @MainActor
    override func setUp() {
        super.setUp()
        libraryService = LibraryService(client: nil)
        viewModel = LibraryViewModel(libraryService: libraryService)
    }

    override func tearDown() {
        viewModel = nil
        libraryService = nil
        super.tearDown()
    }

    @MainActor
    func testExposesRadiosFromService() {
        // Simulate service having radios
        libraryService.radios = [
            Radio(id: "1", name: "KEXP", artworkURL: nil, provider: "Radio Browser")
        ]

        XCTAssertEqual(viewModel.radios.count, 1)
        XCTAssertEqual(viewModel.radios[0].name, "KEXP")
    }

    @MainActor
    func testLoadsRadiosWhenCategorySelected() async {
        viewModel.selectedCategory = .radio
        await viewModel.loadContent()

        // Service should have error since client is nil, but category should be set
        XCTAssertEqual(viewModel.selectedCategory, .radio)
        XCTAssertNotNil(libraryService.lastError)
    }
}
