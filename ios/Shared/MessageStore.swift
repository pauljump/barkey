import Foundation

/// Stores raw captured messages in App Group shared storage.
/// The keyboard extension writes messages here. The containing app reads them,
/// processes into a StyleProfile when ready, then deletes the raw text.
enum MessageStore {
    private static let suiteName = "group.com.barkey.app"
    private static let messagesKey = "captured_messages"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func loadMessages() -> [String] {
        guard let defaults = defaults,
              let data = defaults.data(forKey: messagesKey),
              let messages = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return messages
    }

    static func appendMessage(_ message: String) {
        var messages = loadMessages()
        messages.append(message)
        saveMessages(messages)
    }

    static func count() -> Int {
        loadMessages().count
    }

    static func deleteMessage(at index: Int) {
        var messages = loadMessages()
        guard index >= 0 && index < messages.count else { return }
        messages.remove(at: index)
        saveMessages(messages)
    }

    static func deleteAll() {
        defaults?.removeObject(forKey: messagesKey)
    }

    private static func saveMessages(_ messages: [String]) {
        guard let defaults = defaults,
              let data = try? JSONEncoder().encode(messages) else { return }
        defaults.set(data, forKey: messagesKey)
    }
}
