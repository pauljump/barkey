import SwiftUI

/// Free tier demo: paste any text and see what it would sound like in your voice.
/// Shows the style in action without giving away the full prompt.
struct RewriteView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var inputText = ""
    @State private var showingResult = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.ember)
                            Text("Try Your Voice")
                                .font(Theme.titleFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("Paste any text below. We'll show you what it sounds like rewritten in your style.")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        // Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original text")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)

                            TextEditor(text: $inputText)
                                .font(Theme.bodyFont)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.smoke, lineWidth: 1)
                                )
                        }

                        // Style summary
                        if showingResult {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your voice would say it like...")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)

                                Text(rewritePreview)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.ember.opacity(0.08))
                                    .cornerRadius(12)

                                Text("This is a preview based on your style stats. With the full prompt + an LLM, the rewrite will be much more accurate.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }

                        // Action
                        Button {
                            showingResult = true
                        } label: {
                            Text("Rewrite in My Voice")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(inputText.isEmpty ? Theme.ash : Theme.accent)
                                .cornerRadius(14)
                        }
                        .disabled(inputText.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Try Your Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }

    /// Simple on-device rewrite preview using style stats.
    /// This is NOT the full LLM rewrite — just a demonstration of the style analysis.
    private var rewritePreview: String {
        let profile = appState.profile
        var notes: [String] = []

        if profile.avgWordsPerMessage < 8 {
            notes.append("Your version would be shorter — you average \(Int(profile.avgWordsPerMessage)) words per message.")
        }
        if profile.exclamationRate < 0.05 {
            notes.append("You'd drop the exclamation marks — you use them in only \(Int(profile.exclamationRate * 100))% of messages.")
        }
        if profile.emojiRate < 0.05 {
            notes.append("No emoji — you almost never use them (\(Int(profile.emojiRate * 100))%).")
        }
        if profile.slangRate > 0.2 {
            notes.append("You'd use more casual language — \(Int(profile.slangRate * 100))% of your messages have slang.")
        }
        if let opener = profile.topOpeners.first {
            notes.append("You'd probably start with \"\(opener.0)\" — your most common opener.")
        }

        if notes.isEmpty {
            notes.append("Your style profile is still building. More messages = more accurate preview.")
        }

        return notes.joined(separator: "\n\n")
    }
}
