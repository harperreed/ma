// ABOUTME: Network address validation for server configuration
// ABOUTME: Validates IP addresses, hostnames, and port numbers

import Foundation

struct NetworkValidator {
    /// Validate if string is a valid IPv4 address or hostname
    static func isValidHost(_ host: String) -> Bool {
        if host.isEmpty {
            return false
        }

        // Try IPv4 validation first
        if looksLikeIPv4(host) {
            return isValidIPv4(host)
        }

        // Try hostname validation
        return isValidHostname(host)
    }

    /// Validate if port is in valid range (1-65535)
    static func isValidPort(_ port: Int) -> Bool {
        return port >= 1 && port <= 65535
    }

    /// Validate server configuration, returns error message if invalid
    static func validateServerConfig(host: String, port: Int) -> String? {
        if !isValidHost(host) {
            return "Invalid host address. Please enter a valid IP address or hostname."
        }

        if !isValidPort(port) {
            return "Invalid port number. Must be between 1 and 65535."
        }

        return nil // Valid
    }

    // MARK: - Private Helpers

    private static func looksLikeIPv4(_ address: String) -> Bool {
        // Check if the string looks like an IP address (contains only digits, dots)
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.-")
        return address.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }

    private static func isValidIPv4(_ address: String) -> Bool {
        let components = address.split(separator: ".")

        guard components.count == 4 else {
            return false
        }

        for component in components {
            guard let value = Int(component),
                  value >= 0,
                  value <= 255,
                  String(value) == component else {
                return false
            }
        }

        return true
    }

    private static func isValidHostname(_ hostname: String) -> Bool {
        // Basic hostname validation
        // - Must start and end with alphanumeric
        // - Can contain hyphens and dots
        // - Labels must not start or end with hyphen
        // - No consecutive dots

        // Check for consecutive dots
        if hostname.contains("..") {
            return false
        }

        // Check if starts or ends with dot or hyphen
        if hostname.hasPrefix(".") || hostname.hasPrefix("-") ||
           hostname.hasSuffix(".") || hostname.hasSuffix("-") {
            return false
        }

        // Split by dots and validate each label
        let labels = hostname.split(separator: ".")

        for label in labels {
            // Label cannot be empty
            if label.isEmpty {
                return false
            }

            // Label cannot start or end with hyphen
            if label.hasPrefix("-") || label.hasSuffix("-") {
                return false
            }

            // Label must contain only alphanumeric and hyphen
            for char in label {
                if !char.isLetter && !char.isNumber && char != "-" {
                    return false
                }
            }
        }

        return true
    }
}
