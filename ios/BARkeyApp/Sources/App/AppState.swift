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

    /// Your voice online for assistants (Claude, ChatGPT, Muse).
    let voiceLink = VoiceLink()

    /// The word the keyboard turns into your voice brief.
    @Published var voiceShortcut: String = VoiceBrief.shortcut {
        didSet { VoiceBrief.shortcut = voiceShortcut; if voiceShortcut != VoiceBrief.shortcut { voiceShortcut = VoiceBrief.shortcut } }
    }
    @Published var voiceShortcutEnabled: Bool = VoiceBrief.isEnabled {
        didSet { VoiceBrief.isEnabled = voiceShortcutEnabled }
    }

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
        updateBrief()
    }

    /// Keeps the keyboard's brief current and, if the voice is online, republishes after enough new messages.
    private func updateBrief() {
        if canExport {
            VoiceBrief.brief = PromptGenerator.generateBrief(messages, profile: profile)
        } else {
            VoiceBrief.clear()
        }
        if voiceLink.isPublished, totalMessages - voiceLink.publishedMessageCount >= 25 {
            let prompt = generatePrompt(), count = totalMessages
            Task { await voiceLink.publish(prompt: prompt, messageCount: count) }
        }
    }

    /// Put the current prompt online (or refresh it) for assistants.
    func publishVoice() async {
        await voiceLink.publish(prompt: generatePrompt(), messageCount: totalMessages)
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
        updateBrief()
    }

    func deleteMessage(at index: Int) {
        guard index >= 0 && index < messages.count else { return }
        MessageStore.deleteMessage(at: index)
        messages.remove(at: index)
        profile = Self.buildProfile(from: messages)
        updateBrief()
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
        KeptWords.removeAll()
        VoiceBrief.clear()
        messages = []
        profile = StyleProfile()
        hasExported = false
        UserDefaults.standard.set(false, forKey: exportedKey)
        if voiceLink.credentials != nil { Task { await voiceLink.burn() } }
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
