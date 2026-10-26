import Foundation
import CryptoKit
import Security

/// Your voice, online for your assistants, without the prompt ever being readable by the server.
///
/// The prompt is encrypted here with AES-256-GCM. The server stores the ciphertext under a random id. The key
/// lives only in the link you hand to your assistant (and in this iPhone's keychain). Burn deletes the ciphertext.
@MainActor
final class VoiceLink: ObservableObject {
    struct Credentials: Codable, Equatable {
        var id: String
        var key: Data
        var owner: String
    }

    static let defaultServer = URL(string: "https://barkey.polyfeeds.dev")!

    @Published private(set) var credentials: Credentials?
    @Published private(set) var publishedAt: Date?
    @Published private(set) var publishedMessageCount = 0
    @Published var isWorking = false
    @Published var lastError: String?

    var server: URL {
        if let custom = UserDefaults.standard.string(forKey: "voice_server"), let url = URL(string: custom) { return url }
        return Self.defaultServer
    }

    var isPublished: Bool { credentials != nil && publishedAt != nil }

    init() {
        credentials = Keychain.load()
        publishedAt = UserDefaults.standard.object(forKey: "voice_published_at") as? Date
        publishedMessageCount = UserDefaults.standard.integer(forKey: "voice_published_count")
    }

    // MARK: Links

    private func keyString(_ c: Credentials) -> String { Self.base64url(c.key) }

    var mcpURL: URL? { credentials.map { server.appendingPathComponent("mcp/\($0.id)/\(keyString($0))") } }
    var restURL: URL? { credentials.map { server.appendingPathComponent("v1/voices/\($0.id)/\(keyString($0))") } }
    var pageURL: URL? { credentials.map { server.appendingPathComponent("v/\($0.id)/\(keyString($0))") } }

    // MARK: Publish / burn

    /// Encrypts and uploads the prompt. Reuses the same link if one exists, so assistants keep working.
    func publish(prompt: String, messageCount: Int) async {
        isWorking = true; lastError = nil
        defer { isWorking = false }
        let creds = credentials ?? Credentials(id: Self.base64url(Self.random(16)), key: Self.random(32), owner: Self.base64url(Self.random(32)))
        do {
            let key = SymmetricKey(data: creds.key)
            let nonce = AES.GCM.Nonce()
            let sealed = try AES.GCM.seal(Data(prompt.utf8), using: key, nonce: nonce)
            let body: [String: String] = [
                "ciphertext": Self.base64url(sealed.ciphertext + sealed.tag),
                "nonce": Self.base64url(Data(nonce)),
            ]
            var request = URLRequest(url: server.appendingPathComponent("v1/voices/\(creds.id)"))
            request.httpMethod = "PUT"
            request.setValue("Bearer \(creds.owner)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let text = String(data: data, encoding: .utf8) ?? ""
                throw VoiceLinkError.server("The voice server said no (\((response as? HTTPURLResponse)?.statusCode ?? 0)). \(text)")
            }
            if credentials == nil { Keychain.save(creds); credentials = creds }
            publishedAt = Date()
            publishedMessageCount = messageCount
            UserDefaults.standard.set(publishedAt, forKey: "voice_published_at")
            UserDefaults.standard.set(messageCount, forKey: "voice_published_count")
        } catch {
            lastError = (error as? VoiceLinkError)?.message ?? "Couldn't reach the voice server. Check your connection and try again."
        }
    }

    /// Deletes the ciphertext from the server and forgets the link. Assistants using the old link get nothing.
    func burn() async {
        isWorking = true; lastError = nil
        defer { isWorking = false }
        if let creds = credentials {
            var request = URLRequest(url: server.appendingPathComponent("v1/voices/\(creds.id)"))
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(creds.owner)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 20
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    lastError = "The server didn't confirm the delete. The link is forgotten here; try Burn again later to be sure."
                    forget(); return
                }
            } catch {
                lastError = "Couldn't reach the voice server. The link is forgotten on this iPhone; try Burn again later to delete the copy."
                forget(); return
            }
        }
        forget()
    }

    private func forget() {
        Keychain.delete()
        credentials = nil
        publishedAt = nil
        publishedMessageCount = 0
        UserDefaults.standard.removeObject(forKey: "voice_published_at")
        UserDefaults.standard.removeObject(forKey: "voice_published_count")
    }

    // MARK: Helpers

    enum VoiceLinkError: Error { case server(String); var message: String { if case .server(let m) = self { return m }; return "" } }

    static func random(_ count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }

    static func base64url(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }

    /// The link's secrets live in this iPhone's keychain, not in UserDefaults.
    enum Keychain {
        private static let service = "com.barkey.app.voicelink"
        private static var query: [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "voice"] }

        static func load() -> Credentials? {
            var q = query; q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
            var item: CFTypeRef?
            guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
            return try? JSONDecoder().decode(Credentials.self, from: data)
        }

        static func save(_ c: Credentials) {
            guard let data = try? JSONEncoder().encode(c) else { return }
            SecItemDelete(query as CFDictionary)
            var q = query; q[kSecValueData as String] = data; q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(q as CFDictionary, nil)
        }

        static func delete() { SecItemDelete(query as CFDictionary) }
    }
}
