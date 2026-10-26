import Foundation

/// The short "write like me" text the keyboard can type for you, and the shortcut word that triggers it.
/// The app writes both into the shared App Group; the keyboard reads them.
enum VoiceBrief {
    private static let suiteName = "group.com.barkey.app"
    private static let briefKey = "voice_brief"
    private static let shortcutKey = "voice_shortcut"
    private static let enabledKey = "voice_shortcut_enabled"

    static let defaultShortcut = "myvoice"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    static var brief: String? {
        get { defaults?.string(forKey: briefKey) }
        set { defaults?.set(newValue, forKey: briefKey) }
    }

    /// Lowercase word that, followed by a space, becomes the brief. Letters only, 3 to 20 characters.
    static var shortcut: String {
        get { defaults?.string(forKey: shortcutKey) ?? defaultShortcut }
        set {
            let cleaned = newValue.lowercased().filter(\.isLetter)
            defaults?.set(cleaned.isEmpty ? defaultShortcut : String(cleaned.prefix(20)), forKey: shortcutKey)
        }
    }

    static var isEnabled: Bool {
        get { defaults?.object(forKey: enabledKey) == nil ? true : defaults!.bool(forKey: enabledKey) }
        set { defaults?.set(newValue, forKey: enabledKey) }
    }

    static func clear() {
        defaults?.removeObject(forKey: briefKey)
    }
}
