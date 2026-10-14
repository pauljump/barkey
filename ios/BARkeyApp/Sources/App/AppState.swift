import SwiftUI
import KeyboardKit

@MainActor
class AppState: ObservableObject {
    @Published var messages: [String] = []
    @Published var profile: StyleProfile = StyleProfile()
    @Published var hasCompletedOnboarding: Bool
    @Published var hasExported: Bool
    @Published var isPaused: Bool {
        didSet { CaptureSettings.isPaused = isPaused }
    }

    /// Whether the keyboard is added in Settings and has Full Access.
    let keyboardStatus = KeyboardStatusContext(bundleId: "com.barkey.app.keyboard")

    private let onboardingKey = "has_completed_onboarding"
    private let exportedKey = "has_exported"

    var totalMessages: Int { messages.count }

    var progress: Double {
        min(Double(totalMessages) / Double(StyleProfile.targetMessageCount), 1.0)
    }

    /// Enough messages for a first prompt.
    var canExport: Bool {
        totalMessages >= StyleProfile.minimumForPrompt
    }

    /// The voice is at its best.
    var isReady: Bool {
        totalMessages >= StyleProfile.targetMessageCount
    }

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.hasExported = UserDefaults.standard.bool(forKey: exportedKey)
        self.isPaused = CaptureSettings.isPaused
        self.messages = MessageStore.loadMessages()
        self.profile = Self.buildProfile(from: self.messages)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func refresh() {
        keyboardStatus.refresh()
        let latest = MessageStore.loadMessages()
        guard latest != messages else { return }
        messages = latest
        profile = Self.buildProfile(from: messages)
    }

    func deleteMessage(at index: Int) {
        guard index >= 0 && index < messages.count else { return }
        MessageStore.deleteMessage(at: index)
        messages.remove(at: index)
        profile = Self.buildProfile(from: messages)
    }

    /// The exportable voice prompt, built from real messages.
    func generatePrompt() -> String {
        PromptGenerator.generateFromMessages(messages, profile: profile)
    }

    /// A shorter prompt that fits Apple's on-device model.
    func onDevicePrompt() -> String {
        PromptGenerator.generateFromMessages(messages, profile: profile, exampleCount: VoiceModel.onDeviceExampleCount)
    }

    /// Real messages that are not used as examples in the on-device prompt,
    /// for the blind test.
    func heldOutMessages(count: Int) -> [String] {
        let used = Set(PromptGenerator.selectRepresentativeMessages(from: messages, count: VoiceModel.onDeviceExampleCount))
        let pool = messages.filter { !used.contains($0) && $0.split(separator: " ").count >= 3 }
        return Array(pool.shuffled().prefix(count))
    }

    func markExported() {
        hasExported = true
        UserDefaults.standard.set(true, forKey: exportedKey)
    }

    /// Delete every captured message and start over.
    func burnEverything() {
        MessageStore.deleteAll()
        ProfileStore.reset()
        messages = []
        profile = StyleProfile()
        hasExported = false
        UserDefaults.standard.set(false, forKey: exportedKey)
    }

    /// Build a StyleProfile from raw messages (for UI stats display).
    private static func buildProfile(from messages: [String]) -> StyleProfile {
        var profile = StyleProfile()
        for message in messages {
            StyleAnalyzer.processMessage(message, into: &profile)
        }
        return profile
    }
}
