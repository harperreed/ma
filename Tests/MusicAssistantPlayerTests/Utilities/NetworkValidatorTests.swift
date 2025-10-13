// ABOUTME: Test suite for NetworkValidator utility
// ABOUTME: Tests IPv4 address, hostname, and port validation logic

import XCTest
@testable import MusicAssistantPlayer

final class NetworkValidatorTests: XCTestCase {
    func testValidIPv4Addresses() {
        XCTAssertTrue(NetworkValidator.isValidHost("192.168.1.1"))
        XCTAssertTrue(NetworkValidator.isValidHost("10.0.0.1"))
        XCTAssertTrue(NetworkValidator.isValidHost("127.0.0.1"))
        XCTAssertTrue(NetworkValidator.isValidHost("0.0.0.0"))
        XCTAssertTrue(NetworkValidator.isValidHost("255.255.255.255"))
    }

    func testInvalidIPv4Addresses() {
        XCTAssertFalse(NetworkValidator.isValidHost("256.1.1.1"))
        XCTAssertFalse(NetworkValidator.isValidHost("192.168.1"))
        XCTAssertFalse(NetworkValidator.isValidHost("192.168.1.1.1"))
        XCTAssertFalse(NetworkValidator.isValidHost("192.168.-1.1"))
        XCTAssertFalse(NetworkValidator.isValidHost("192.168.1.256"))
    }

    func testValidHostnames() {
        XCTAssertTrue(NetworkValidator.isValidHost("localhost"))
        XCTAssertTrue(NetworkValidator.isValidHost("music.local"))
        XCTAssertTrue(NetworkValidator.isValidHost("my-server.example.com"))
        XCTAssertTrue(NetworkValidator.isValidHost("server01"))
        XCTAssertTrue(NetworkValidator.isValidHost("music-assistant.home"))
    }

    func testInvalidHostnames() {
        XCTAssertFalse(NetworkValidator.isValidHost("-invalid"))
        XCTAssertFalse(NetworkValidator.isValidHost("invalid-.com"))
        XCTAssertFalse(NetworkValidator.isValidHost("inv alid.com"))
        XCTAssertFalse(NetworkValidator.isValidHost(""))
        XCTAssertFalse(NetworkValidator.isValidHost(".invalid"))
        XCTAssertFalse(NetworkValidator.isValidHost("invalid..com"))
    }

    func testValidPorts() {
        XCTAssertTrue(NetworkValidator.isValidPort(80))
        XCTAssertTrue(NetworkValidator.isValidPort(8095))
        XCTAssertTrue(NetworkValidator.isValidPort(65535))
        XCTAssertTrue(NetworkValidator.isValidPort(1))
        XCTAssertTrue(NetworkValidator.isValidPort(443))
        XCTAssertTrue(NetworkValidator.isValidPort(3000))
    }

    func testInvalidPorts() {
        XCTAssertFalse(NetworkValidator.isValidPort(0))
        XCTAssertFalse(NetworkValidator.isValidPort(-1))
        XCTAssertFalse(NetworkValidator.isValidPort(65536))
        XCTAssertFalse(NetworkValidator.isValidPort(100000))
        XCTAssertFalse(NetworkValidator.isValidPort(-8095))
    }

    func testValidateServerConfigSuccess() {
        let validIPAndPort = NetworkValidator.validateServerConfig(host: "192.168.1.1", port: 8095)
        XCTAssertNil(validIPAndPort) // nil means no error

        let validHostnameAndPort = NetworkValidator.validateServerConfig(host: "music.local", port: 8095)
        XCTAssertNil(validHostnameAndPort)

        let validLocalhostAndPort = NetworkValidator.validateServerConfig(host: "localhost", port: 80)
        XCTAssertNil(validLocalhostAndPort)
    }

    func testValidateServerConfigInvalidHost() {
        let invalidHost = NetworkValidator.validateServerConfig(host: "256.1.1.1", port: 8095)
        XCTAssertNotNil(invalidHost)
        XCTAssertTrue(invalidHost!.contains("host"))

        let emptyHost = NetworkValidator.validateServerConfig(host: "", port: 8095)
        XCTAssertNotNil(emptyHost)
        XCTAssertTrue(emptyHost!.contains("host"))

        let invalidHostname = NetworkValidator.validateServerConfig(host: "-invalid", port: 8095)
        XCTAssertNotNil(invalidHostname)
        XCTAssertTrue(invalidHostname!.contains("host"))
    }

    func testValidateServerConfigInvalidPort() {
        let invalidPort = NetworkValidator.validateServerConfig(host: "192.168.1.1", port: 99999)
        XCTAssertNotNil(invalidPort)
        XCTAssertTrue(invalidPort!.contains("port"))

        let zeroPort = NetworkValidator.validateServerConfig(host: "192.168.1.1", port: 0)
        XCTAssertNotNil(zeroPort)
        XCTAssertTrue(zeroPort!.contains("port"))

        let negativePort = NetworkValidator.validateServerConfig(host: "localhost", port: -1)
        XCTAssertNotNil(negativePort)
        XCTAssertTrue(negativePort!.contains("port"))
    }
}
