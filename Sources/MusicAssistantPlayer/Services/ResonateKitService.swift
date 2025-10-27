// ABOUTME: Service wrapper for ResonateKit synchronized audio playback
// ABOUTME: Manages ResonateClient lifecycle, discovery, and playback commands

import Foundation
import ResonateKit
import Combine

@MainActor
class ResonateKitService: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var isConnected: Bool = false
    @Published var discoveredServers: [String] = []
    @Published var currentServer: String?
    @Published var lastError: String?

    private var client: ResonateClient?
    private var discovery: ServerDiscovery?
    private var discoveryTask: Task<Void, Never>?

    // MARK: - Initialization

    func initialize() {
        guard isEnabled else { return }

        AppLogger.network.info("🎵 Initializing ResonateKit client")

        // Create ResonateClient with player role
        let deviceName = Host.current().localizedName ?? "Music Assistant Player"
        let deviceId = getDeviceId()

        client = ResonateClient(
            clientId: deviceId,
            name: deviceName,
            roles: [.player, .metadata],
            playerConfig: PlayerConfiguration(
                bufferCapacity: 1_048_576, // 1MB buffer
                supportedFormats: [
                    AudioFormatSpec(codec: .pcm, channels: 2, sampleRate: 48000, bitDepth: 16),
                    AudioFormatSpec(codec: .opus, channels: 2, sampleRate: 48000, bitDepth: 16),
                    AudioFormatSpec(codec: .flac, channels: 2, sampleRate: 48000, bitDepth: 16),
                ]
            )
        )

        AppLogger.network.info("✅ ResonateKit client initialized")
    }

    // MARK: - Discovery

    func startDiscovery() async {
        guard isEnabled else { return }

        AppLogger.network.info("🔍 Starting Resonate server discovery")

        discovery = ServerDiscovery()

        discoveryTask = Task {
            guard let discovery = discovery else { return }

            await discovery.startDiscovery()

            for await serverList in await discovery.servers {
                await MainActor.run {
                    discoveredServers = serverList.map { server in
                        "\(server.name) (\(server.hostname):\(server.port))"
                    }
                    AppLogger.network.info("📡 Discovered \(serverList.count) Resonate servers")
                }

                // Auto-connect to first discovered server if not already connected
                if currentServer == nil, let firstServer = serverList.first {
                    await connectToServer(firstServer)
                }
            }
        }
    }

    func stopDiscovery() {
        AppLogger.network.info("⏹️ Stopping Resonate server discovery")
        discoveryTask?.cancel()
        discoveryTask = nil
        discovery = nil
    }

    // MARK: - Connection

    func connectToServer(_ server: DiscoveredServer) async {
        guard let client = client else {
            lastError = "ResonateKit not initialized"
            AppLogger.errors.error("Cannot connect: ResonateKit not initialized")
            return
        }

        do {
            AppLogger.network.info("🔌 Connecting to Resonate server: \(server.name) at \(server.url)")

            try await client.connect(to: server.url)

            currentServer = server.name
            isConnected = true
            lastError = nil

            AppLogger.network.info("✅ Connected to Resonate server: \(server.name)")
        } catch {
            lastError = "Connection failed: \(error.localizedDescription)"
            AppLogger.errors.logError(error, context: "ResonateKit connection failed")
            isConnected = false
            currentServer = nil
        }
    }

    func disconnect() async {
        guard let client = client else { return }

        AppLogger.network.info("🔌 Disconnecting from Resonate server")

        await client.disconnect()
        isConnected = false
        currentServer = nil

        AppLogger.network.info("✅ Disconnected from Resonate server")
    }

    // MARK: - Playback Control
    // Note: ResonateKit is primarily a synchronized audio delivery protocol
    // Playback control (play/pause/skip) is typically handled by the controller role
    // or the Music Assistant server itself. These methods are placeholders for
    // future integration when we map MA commands to Resonate groups.

    func play() async throws {
        guard isConnected else {
            throw ResonateKitError.notConnected
        }
        // TODO: Implement play via controller role or MA integration
        AppLogger.ui.info("▶️ ResonateKit play requested (not yet implemented)")
    }

    func pause() async throws {
        guard isConnected else {
            throw ResonateKitError.notConnected
        }
        // TODO: Implement pause via controller role or MA integration
        AppLogger.ui.info("⏸️ ResonateKit pause requested (not yet implemented)")
    }

    func stop() async throws {
        guard isConnected else {
            throw ResonateKitError.notConnected
        }
        // TODO: Implement stop via controller role or MA integration
        AppLogger.ui.info("⏹️ ResonateKit stop requested (not yet implemented)")
    }

    func setVolume(_ volume: Double) async throws {
        guard isConnected else {
            throw ResonateKitError.notConnected
        }
        // TODO: Implement volume control via controller role or MA integration
        AppLogger.ui.info("🔊 ResonateKit volume requested: \(volume) (not yet implemented)")
    }

    // MARK: - Lifecycle

    func enable() async {
        isEnabled = true
        initialize()
        await startDiscovery()
    }

    func disable() async {
        isEnabled = false
        stopDiscovery()
        await disconnect()
        client = nil
    }

    // MARK: - Helpers

    private func getDeviceId() -> String {
        // Try to get a stable device identifier
        if let uuid = UserDefaults.standard.string(forKey: "resonatekit.deviceId") {
            return uuid
        }

        let newUUID = UUID().uuidString
        UserDefaults.standard.set(newUUID, forKey: "resonatekit.deviceId")
        return newUUID
    }
}

// MARK: - Errors

enum ResonateKitError: LocalizedError {
    case notConnected
    case notInitialized
    case discoveryFailed
    case connectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to Resonate server"
        case .notInitialized:
            return "ResonateKit client not initialized"
        case .discoveryFailed:
            return "Failed to discover Resonate servers"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        }
    }
}
