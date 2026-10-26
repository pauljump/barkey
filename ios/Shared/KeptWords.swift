import Foundation

/// Words the person taught the keyboard: tapped the typed word over a correction, or backspaced a correction away.
/// Shared with the app so it can show and clear them.
enum KeptWords {
    private static let suiteName = "group.com.barkey.app"
    private static let key = "kept_words"

    static func load() -> Set<String> {
        Set(UserDefaults(suiteName: suiteName)?.stringArray(forKey: key) ?? [])
    }

    static func add(_ word: String) {
        var words = load()
        words.insert(word.lowercased())
        UserDefaults(suiteName: suiteName)?.set(Array(words).sorted(), forKey: key)
    }

    static func remove(_ word: String) {
        var words = load()
        words.remove(word.lowercased())
        UserDefaults(suiteName: suiteName)?.set(Array(words).sorted(), forKey: key)
    }

    static func removeAll() {
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: key)
    }
}
