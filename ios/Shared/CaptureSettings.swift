import Foundation

/// Settings the app writes and the keyboard reads, via the shared App Group.
enum CaptureSettings {
    private static let suiteName = "group.com.barkey.app"
    private static let pausedKey = "capture_paused"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var isPaused: Bool {
        get { defaults?.bool(forKey: pausedKey) ?? false }
        set { defaults?.set(newValue, forKey: pausedKey) }
    }
}
