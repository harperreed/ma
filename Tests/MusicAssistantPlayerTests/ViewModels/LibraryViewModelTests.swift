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

    // MARK: - Task 16: Search Tests

    @MainActor
    func testSearchQueryProperty() {
        viewModel.searchQuery = "test query"
        XCTAssertEqual(viewModel.searchQuery, "test query")
    }

    @MainActor
    func testPerformSearchCallsService() async {
        let query = "test"
        await viewModel.performSearch(query: query)
        // Service should have error since client is nil
        XCTAssertNotNil(libraryService.lastError)
    }

    // MARK: - Task 16: Sort Tests

    @MainActor
    func testSelectedSortProperty() {
        XCTAssertEqual(viewModel.selectedSort, .nameAsc)
        viewModel.selectedSort = .recentlyAdded
        XCTAssertEqual(viewModel.selectedSort, .recentlyAdded)
    }

    @MainActor
    func testUpdateSortChangesProperty() async {
        await viewModel.updateSort(.playCount)
        XCTAssertEqual(viewModel.selectedSort, .playCount)
        XCTAssertEqual(libraryService.currentSort, .playCount)
    }

    // MARK: - Task 16: Filter Tests

    @MainActor
    func testSelectedFilterProperty() {
        XCTAssertTrue(viewModel.selectedFilter.isEmpty)
        var filter = LibraryFilter()
        filter.favoriteOnly = true
        viewModel.selectedFilter = filter
        XCTAssertTrue(viewModel.selectedFilter.favoriteOnly)
    }

    @MainActor
    func testUpdateFilterChangesProperty() async {
        var filter = LibraryFilter()
        filter.favoriteOnly = true
        await viewModel.updateFilter(filter)
        XCTAssertTrue(viewModel.selectedFilter.favoriteOnly)
        XCTAssertTrue(libraryService.currentFilter.favoriteOnly)
    }

    // MARK: - Task 16: Pagination Tests

    @MainActor
    func testLoadMoreCallsService() async {
        // Set hasMoreItems to simulate pagination state
        libraryService.hasMoreItems = true
        await viewModel.loadMore()
        // Should have attempted to load next page (and failed due to nil client)
        XCTAssertNotNil(libraryService.lastError)
    }

    @MainActor
    func testHasMoreItemsExposesServiceState() {
        libraryService.hasMoreItems = true
        XCTAssertTrue(viewModel.hasMoreItems)
        libraryService.hasMoreItems = false
        XCTAssertFalse(viewModel.hasMoreItems)
    }
}
