import Foundation

struct AppConfig {
    let url: String?

    /// Flexible parser — tries common key names used for a URL in a JSON config.
    init(data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            url = nil
            return
        }
        let keys = ["url", "link", "web_url", "site", "href", "webUrl", "website", "URL"]
        url = keys.compactMap { json[$0] as? String }.first
    }
}
