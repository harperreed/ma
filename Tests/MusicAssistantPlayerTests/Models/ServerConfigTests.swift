// ABOUTME: Unit tests for ServerConfig model
// ABOUTME: Validates server configuration storage and retrieval from UserDefaults

import XCTest
@testable import MusicAssistantPlayer

final class ServerConfigTests: XCTestCase {
    let testDefaults = UserDefaults(suiteName: "test.musicassistant")!

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "test.musicassistant")
        super.tearDown()
    }

    func testInitialization() {
        let config = ServerConfig(host: "192.168.200.113", port: 8095)

        XCTAssertEqual(config.host, "192.168.200.113")
        XCTAssertEqual(config.port, 8095)
    }

    func testDefaultPort() {
        let config = ServerConfig(host: "192.168.1.100")

        XCTAssertEqual(config.port, 8095)
    }

    func testSaveToUserDefaults() {
        let config = ServerConfig(host: "192.168.200.113", port: 8095)
        config.save(to: testDefaults)

        let loaded = ServerConfig.load(from: testDefaults)
        XCTAssertEqual(loaded?.host, "192.168.200.113")
        XCTAssertEqual(loaded?.port, 8095)
    }

    func testLoadReturnsNilWhenNotSaved() {
        let loaded = ServerConfig.load(from: testDefaults)
        XCTAssertNil(loaded)
    }
}
