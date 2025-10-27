// ABOUTME: Application-wide settings and preferences storage
// ABOUTME: Manages user preferences including ResonateKit configuration

import Foundation

struct AppSettings: Codable, Equatable {
    var resonateKitEnabled: Bool = false
    var resonateKitServerName: String?

    // MARK: - Persistence

    private static let key = "musicassistant.appSettings"

    func save(to defaults: UserDefaults = .standard) {
        if let encoded = try? JSONEncoder().encode(self) {
            defaults.set(encoded, forKey: Self.key)
            AppLogger.ui.info("💾 App settings saved")
        }
    }

    static func load(from defaults: UserDefaults = .standard) -> AppSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            AppLogger.ui.info("📂 No saved settings found, using defaults")
            return AppSettings()
        }

        AppLogger.ui.info("📂 App settings loaded")
        return settings
    }

    static func clear(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
        AppLogger.ui.info("🗑️ App settings cleared")
    }
}
