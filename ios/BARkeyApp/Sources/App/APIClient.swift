import Foundation

/// Minimal API client for BARkey shortlink service.
enum BARkeyAPI {
    // Will be updated after Cloud Run deploy
    static var baseURL = "https://barkey-api-988719556625.us-east1.run.app"

    /// Upload a prompt and get a shortlink back.
    static func uploadPrompt(_ promptText: String, slug: String? = nil) async throws -> ShortlinkResponse {
        let url = URL(string: "\(baseURL)/v1/prompts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: String] = [
            "device_id": deviceId(),
            "prompt_text": promptText,
        ]
        if let slug { body["slug"] = slug }

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.uploadFailed
        }

        return try JSONDecoder().decode(ShortlinkResponse.self, from: data)
    }

    /// Get a stable device ID (persisted in UserDefaults).
    private static func deviceId() -> String {
        let key = "barkey_device_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }

    struct ShortlinkResponse: Codable {
        let slug: String
        let url: String
    }

    enum APIError: Error {
        case uploadFailed
    }
}
