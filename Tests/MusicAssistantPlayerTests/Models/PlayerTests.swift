// ABOUTME: Unit tests for Player model
// ABOUTME: Validates player identity, active state, and grouping properties

import XCTest
@testable import MusicAssistantPlayer

final class PlayerTests: XCTestCase {
    func testPlayerInitialization() {
        let player = Player(
            id: "player_kitchen",
            name: "Kitchen Speaker",
            isActive: true,
            type: .player,
            groupChildIds: [],
            syncedTo: nil,
            activeGroup: nil
        )

        XCTAssertEqual(player.id, "player_kitchen")
        XCTAssertEqual(player.name, "Kitchen Speaker")
        XCTAssertTrue(player.isActive)
        XCTAssertEqual(player.type, .player)
        XCTAssertFalse(player.isGroup)
        XCTAssertFalse(player.isSynced)
    }

    func testGroupPlayer() {
        let group = Player(
            id: "group_first_floor",
            name: "First Floor",
            isActive: true,
            type: .group,
            groupChildIds: ["player_kitchen", "player_living", "player_dining"],
            syncedTo: nil,
            activeGroup: nil
        )

        XCTAssertTrue(group.isGroup)
        XCTAssertEqual(group.groupChildIds.count, 3)
        XCTAssertFalse(group.isSynced)
    }

    func testSyncedPlayer() {
        let player = Player(
            id: "player_kitchen",
            name: "Kitchen Speaker",
            isActive: true,
            type: .player,
            groupChildIds: [],
            syncedTo: "group_first_floor",
            activeGroup: nil
        )

        XCTAssertFalse(player.isGroup)
        XCTAssertTrue(player.isSynced)
        XCTAssertEqual(player.syncedTo, "group_first_floor")
    }
}
