import XCTest
@testable import MusicAssistantPlayer

final class PlayerErrorTests: XCTestCase {
    func testErrorDescriptions() {
        let networkError = PlayerError.networkError("Connection failed")
        XCTAssertEqual(networkError.userMessage, "Unable to connect to the server. Please check your connection.")

        let commandError = PlayerError.commandFailed("play", reason: "Player offline")
        XCTAssertEqual(commandError.userMessage, "Unable to play. The player may be offline.")

        let invalidConfig = PlayerError.invalidConfiguration("Invalid host")
        XCTAssertEqual(invalidConfig.userMessage, "Server configuration is invalid. Please check your settings.")
    }

    func testErrorEquality() {
        let error1 = PlayerError.networkError("test")
        let error2 = PlayerError.networkError("test")
        XCTAssertEqual(error1, error2)

        let error3 = PlayerError.commandFailed("play", reason: "test")
        XCTAssertNotEqual(error1, error3)
    }
}
