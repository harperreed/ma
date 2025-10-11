// ABOUTME: Unit tests for Player model
// ABOUTME: Validates player identity and active state properties

import XCTest
@testable import MusicAssistantPlayer

final class PlayerTests: XCTestCase {
    func testPlayerInitialization() {
        let player = Player(
            id: "player_kitchen",
            name: "Kitchen Speaker",
            isActive: true
        )

        XCTAssertEqual(player.id, "player_kitchen")
        XCTAssertEqual(player.name, "Kitchen Speaker")
        XCTAssertTrue(player.isActive)
    }
}
