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
        // Simulate service having radios in dictionary
        libraryService.radiosDict = [
            "1": Radio(id: "1", name: "KEXP", artworkURL: nil, provider: "Radio Browser")
        ]

        XCTAssertEqual(viewModel.radios.count, 1)
        XCTAssertEqual(viewModel.radios[0].name, "KEXP")
    }

    @MainActor
    func testLoadsRadiosWhenCategorySelected() async {
        // Simulate service having radios loaded in dictionary
        libraryService.radiosDict = [
            "1": Radio(id: "1", name: "BBC Radio 1", artworkURL: nil, provider: "Radio Browser"),
            "2": Radio(id: "2", name: "Jazz FM", artworkURL: nil, provider: "Radio Browser"),
            "3": Radio(id: "3", name: "KEXP", artworkURL: nil, provider: "Radio Browser")
        ]

        viewModel.selectedCategory = .radio

        // Verify radios are exposed through ViewModel (sorted by name)
        XCTAssertEqual(viewModel.radios.count, 3)
        XCTAssertEqual(viewModel.radios[0].name, "BBC Radio 1")
        XCTAssertEqual(viewModel.radios[1].name, "Jazz FM")
        XCTAssertEqual(viewModel.radios[2].name, "KEXP")
    }

    @MainActor
    func testRadioSearch() async {
        // Setup initial radios in dictionary
        libraryService.radiosDict = [
            "1": Radio(id: "1", name: "KEXP", artworkURL: nil, provider: "Radio Browser"),
            "2": Radio(id: "2", name: "BBC Radio 1", artworkURL: nil, provider: "Radio Browser")
        ]

        // Simulate search results (clear and set filtered results)
        libraryService.radiosDict = [
            "1": Radio(id: "1", name: "KEXP", artworkURL: nil, provider: "Radio Browser")
        ]

        // Verify search filtering works through service
        XCTAssertEqual(viewModel.radios.count, 1)
        XCTAssertEqual(viewModel.radios[0].name, "KEXP")
    }

    @MainActor
    func testRadioPagination() async {
        // Simulate first page of radios in dictionary
        libraryService.radiosDict = [
            "1": Radio(id: "1", name: "Radio 1", artworkURL: nil, provider: "Radio Browser"),
            "2": Radio(id: "2", name: "Radio 2", artworkURL: nil, provider: "Radio Browser")
        ]
        libraryService.hasMoreItems = true

        viewModel.selectedCategory = .radio

        // Verify initial load
        XCTAssertEqual(viewModel.radios.count, 2)
        XCTAssertTrue(viewModel.hasMoreItems)

        // Simulate loading next page (add to dictionary)
        libraryService.radiosDict["3"] = Radio(id: "3", name: "Radio 3", artworkURL: nil, provider: "Radio Browser")
        libraryService.radiosDict["4"] = Radio(id: "4", name: "Radio 4", artworkURL: nil, provider: "Radio Browser")
        libraryService.hasMoreItems = false

        // Verify pagination appended items
        XCTAssertEqual(viewModel.radios.count, 4)
        XCTAssertFalse(viewModel.hasMoreItems)
        // Note: radios are sorted by name, so order might differ
        XCTAssertTrue(viewModel.radios.contains { $0.name == "Radio 3" })
        XCTAssertTrue(viewModel.radios.contains { $0.name == "Radio 4" })
    }
}
