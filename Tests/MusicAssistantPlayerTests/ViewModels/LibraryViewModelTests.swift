import XCTest
@testable import MusicAssistantPlayer

final class LibraryViewModelTests: XCTestCase {
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
    func testInitialization() {
        XCTAssertEqual(viewModel.selectedCategory, .artists)
        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testCategorySelection() async {
        viewModel.selectedCategory = .albums
        XCTAssertEqual(viewModel.selectedCategory, .albums)
    }
}
