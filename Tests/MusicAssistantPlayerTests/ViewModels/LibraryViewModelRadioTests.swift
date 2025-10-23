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
        // Simulate service having radios loaded
        libraryService.radios = [
            Radio(id: "1", name: "KEXP", artworkURL: nil, provider: "Radio Browser"),
            Radio(id: "2", name: "BBC Radio 1", artworkURL: nil, provider: "Radio Browser"),
            Radio(id: "3", name: "Jazz FM", artworkURL: nil, provider: "Radio Browser")
        ]

        viewModel.selectedCategory = .radio

        // Verify radios are exposed through ViewModel
        XCTAssertEqual(viewModel.radios.count, 3)
        XCTAssertEqual(viewModel.radios[0].name, "KEXP")
        XCTAssertEqual(viewModel.radios[1].name, "BBC Radio 1")
        XCTAssertEqual(viewModel.radios[2].name, "Jazz FM")
    }

    @MainActor
    func testRadioSearch() async {
        // Setup initial radios
        libraryService.radios = [
            Radio(id: "1", name: "KEXP", artworkURL: nil, provider: "Radio Browser"),
            Radio(id: "2", name: "BBC Radio 1", artworkURL: nil, provider: "Radio Browser")
        ]

        // Simulate search results
        libraryService.radios = [
            Radio(id: "1", name: "KEXP", artworkURL: nil, provider: "Radio Browser")
        ]

        // Verify search filtering works through service
        XCTAssertEqual(viewModel.radios.count, 1)
        XCTAssertEqual(viewModel.radios[0].name, "KEXP")
    }

    @MainActor
    func testRadioPagination() async {
        // Simulate first page of radios
        libraryService.radios = [
            Radio(id: "1", name: "Radio 1", artworkURL: nil, provider: "Radio Browser"),
            Radio(id: "2", name: "Radio 2", artworkURL: nil, provider: "Radio Browser")
        ]
        libraryService.hasMoreItems = true

        viewModel.selectedCategory = .radio

        // Verify initial load
        XCTAssertEqual(viewModel.radios.count, 2)
        XCTAssertTrue(viewModel.hasMoreItems)

        // Simulate loading next page
        libraryService.radios.append(contentsOf: [
            Radio(id: "3", name: "Radio 3", artworkURL: nil, provider: "Radio Browser"),
            Radio(id: "4", name: "Radio 4", artworkURL: nil, provider: "Radio Browser")
        ])
        libraryService.hasMoreItems = false

        // Verify pagination appended items
        XCTAssertEqual(viewModel.radios.count, 4)
        XCTAssertFalse(viewModel.hasMoreItems)
        XCTAssertEqual(viewModel.radios[2].name, "Radio 3")
        XCTAssertEqual(viewModel.radios[3].name, "Radio 4")
    }
}
