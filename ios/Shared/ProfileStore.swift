import Foundation

/// Reads and writes StyleProfile to App Group shared storage.
/// Both the keyboard extension and containing app use this to share data.
enum ProfileStore {
    private static let suiteName = "group.com.barkey.app"
    private static let profileKey = "style_profile"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func load() -> StyleProfile {
        guard let defaults = defaults,
              let data = defaults.data(forKey: profileKey),
              let profile = try? JSONDecoder().decode(StyleProfile.self, from: data) else {
            return StyleProfile()
        }
        return profile
    }

    static func save(_ profile: StyleProfile) {
        guard let defaults = defaults,
              let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
    }

    static func reset() {
        defaults?.removeObject(forKey: profileKey)
    }
}
