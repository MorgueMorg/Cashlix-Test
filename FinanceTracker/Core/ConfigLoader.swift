import Foundation

enum ConfigError: Error {
    case invalidSourceURL
    case networkError(Error)
    case parseError
    case invalidWebURL
}

struct ConfigLoader {
    private static let jsonURLString = "https://drive.google.com/uc?export=download&id=13935lF1Cs8cRQOYRp6pnkK-TalBW5EyU"
    /// test link =https://drive.google.com/uc?export=download&id=1uT4Tt6krFAPgBC4tegqb16Pl32vJz42u

    /// Downloads and parses the remote JSON config.
    /// - Returns: A valid HTTP/HTTPS URL string from the config.
    /// - Throws: `ConfigError` on any failure.
    static func load() async throws -> String {
        guard let sourceURL = URL(string: jsonURLString) else {
            throw ConfigError.invalidSourceURL
        }

        let session: URLSession = {
            let cfg = URLSessionConfiguration.default
            cfg.timeoutIntervalForRequest = 10
            cfg.timeoutIntervalForResource = 15
            return URLSession(configuration: cfg)
        }()

        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await session.data(from: sourceURL)
        } catch {
            throw ConfigError.networkError(error)
        }

        let config: AppConfig
        do {
            config = try AppConfig(data: data)
        } catch {
            throw ConfigError.parseError
        }

        guard
            let urlString = config.url,
            !urlString.isEmpty,
            let parsed = URL(string: urlString),
            parsed.scheme == "http" || parsed.scheme == "https"
        else {
            throw ConfigError.invalidWebURL
        }

        return urlString
    }
}
