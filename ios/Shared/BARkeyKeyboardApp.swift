import KeyboardKit

extension KeyboardApp {
    /// Shared keyboard app configuration used by both the main app and keyboard extension.
    static var barkey: KeyboardApp {
        .init(
            name: "BARkey",
            appGroupId: "group.com.barkey.app",
            locales: [.english]
        )
    }
}
