// ABOUTME: Server configuration model for Music Assistant connection settings
// ABOUTME: Handles persistence to UserDefaults and provides default port value

import Foundation

struct ServerConfig: Codable, Equatable {
    let host: String
    let port: Int

    init(host: String, port: Int = 8095) {
        self.host = host
        self.port = port
    }

    private static let key = "musicassistant.serverConfig"

    func save(to defaults: UserDefaults = .standard) {
        if let encoded = try? JSONEncoder().encode(self) {
            defaults.set(encoded, forKey: Self.key)
        }
    }

    static func load(from defaults: UserDefaults = .standard) -> ServerConfig? {
        guard let data = defaults.data(forKey: key),
              let config = try? JSONDecoder().decode(ServerConfig.self, from: data)
        else {
            return nil
        }
        return config
    }
}
