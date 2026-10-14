import Foundation

/// Stores captured messages in App Group shared storage.
/// The keyboard extension writes messages here. The containing app reads them,
/// builds the voice prompt from them, and deletes them when the user burns.
enum MessageStore {
    private static let suiteName = "group.com.barkey.app"
    private static let messagesKey = "captured_messages"

    /// Oldest messages roll off past this, so storage stays small.
    static let maxStored = 1_000

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

    /// Cleans and appends a message. Returns false if it was dropped.
    @discardableResult
    static func appendMessage(_ raw: String) -> Bool {
        guard let message = CaptureFilter.clean(raw) else { return false }
        var messages = loadMessages()
        if messages.last == message { return false }
        messages.append(message)
        if messages.count > maxStored {
            messages.removeFirst(messages.count - maxStored)
        }
        saveMessages(messages)
        return true
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
