// ABOUTME: Tests for RadiosListView component
// ABOUTME: Verifies radio station display, empty states, and interactions

import XCTest
@testable import MusicAssistantPlayer

final class RadiosListViewTests: XCTestCase {

    func testDisplaysRadioStations() {
        let radios = [
            Radio(id: "1", name: "KEXP", artworkURL: nil, provider: "Radio Browser"),
            Radio(id: "2", name: "BBC Radio 6", artworkURL: nil, provider: "TuneIn")
        ]

        let view = RadiosListView(
            radios: radios,
            onPlayNow: { _ in },
            onAddToQueue: { _ in },
            onLoadMore: nil
        )

        XCTAssertEqual(view.radios.count, 2)
        XCTAssertEqual(view.radios[0].name, "KEXP")
        XCTAssertEqual(view.radios[1].name, "BBC Radio 6")
    }

    func testShowsEmptyState() {
        let view = RadiosListView(
            radios: [],
            onPlayNow: { _ in },
            onAddToQueue: { _ in },
            onLoadMore: nil
        )

        XCTAssertTrue(view.radios.isEmpty)
    }

    func testCallsPlayNowCallback() {
        let radio = Radio(id: "1", name: "Test", artworkURL: nil, provider: nil)
        var playedRadio: Radio?

        let view = RadiosListView(
            radios: [radio],
            onPlayNow: { playedRadio = $0 },
            onAddToQueue: { _ in },
            onLoadMore: nil
        )

        view.onPlayNow(radio)
        XCTAssertEqual(playedRadio?.id, "1")
    }

    func testCallsAddToQueueCallback() {
        let radio = Radio(id: "1", name: "Test", artworkURL: nil, provider: nil)
        var queuedRadio: Radio?

        let view = RadiosListView(
            radios: [radio],
            onPlayNow: { _ in },
            onAddToQueue: { queuedRadio = $0 },
            onLoadMore: nil
        )

        view.onAddToQueue(radio)
        XCTAssertEqual(queuedRadio?.id, "1")
    }
}
