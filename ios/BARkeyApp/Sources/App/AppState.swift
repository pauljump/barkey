import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var messages: [String] = []
    @Published var profile: StyleProfile = StyleProfile()
    @Published var hasCompletedOnboarding: Bool
    @Published var hasExported: Bool

    private let onboardingKey = "has_completed_onboarding"
    private let exportedKey = "has_exported"

    var totalMessages: Int { messages.count }

    var progress: Double {
        min(Double(totalMessages) / Double(StyleProfile.targetMessageCount), 1.0)
    }

    var isReady: Bool {
        totalMessages >= StyleProfile.targetMessageCount
    }

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.hasExported = UserDefaults.standard.bool(forKey: exportedKey)
        self.messages = MessageStore.loadMessages()
        self.profile = Self.buildProfile(from: self.messages)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func refresh() {
        messages = MessageStore.loadMessages()
        profile = Self.buildProfile(from: messages)
    }

    func deleteMessage(at index: Int) {
        guard index >= 0 && index < messages.count else { return }
        MessageStore.deleteMessage(at: index)
        messages.remove(at: index)
        profile = Self.buildProfile(from: messages)
    }

    /// Generate the exportable voice prompt from raw messages.
    func generatePrompt() -> String {
        PromptGenerator.generateFromMessages(messages, profile: profile)
    }

    func markExported() {
        hasExported = true
        UserDefaults.standard.set(true, forKey: exportedKey)
    }

    /// Delete all raw messages after export.
    func burnMessages() {
        MessageStore.deleteAll()
        messages = []
    }

    func resetProfile() {
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
