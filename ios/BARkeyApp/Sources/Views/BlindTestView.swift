import SwiftUI

/// The success test for a voice prompt: mix real messages with ones the
/// on-device model wrote in your voice, and see if you can tell them apart.
struct BlindTestView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    struct Card: Identifiable {
        let id = UUID()
        let text: String
        let isFake: Bool
    }

    static let roundSize = 3

    private static let situations = [
        "making plans for the weekend",
        "running ten minutes late",
        "reacting to good news from a friend",
        "asking someone to grab something from the store",
        "checking in on someone who's been quiet",
        "saying thanks for dinner",
        "recommending a show",
        "turning down an invitation",
    ]

    @State private var cards: [Card] = []
    @State private var picked: Set<UUID> = []
    @State private var revealed = false
    @State private var isLoading = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 8) {
                            Image(systemName: "eye.trianglebadge.exclamationmark")
                                .font(.system(size: 34))
                                .foregroundColor(Theme.ember)
                            Text("Spot the Fake")
                                .font(Theme.titleFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("\(Self.roundSize) of these you really sent. \(Self.roundSize) were written by AI using your voice prompt. Tap the ones you think are fake.")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        if case .unavailable(let reason) = VoiceModel.status {
                            notice(reason)
                        } else if appState.heldOutMessages(count: Self.roundSize).count < Self.roundSize {
                            notice("Capture a few more messages first. The test needs real messages that aren't already in your prompt.")
                        } else if isLoading {
                            ProgressView("Writing fakes on your iPhone…")
                                .padding(.vertical, 40)
                        } else if cards.isEmpty {
                            primaryButton("Start a Round", action: startRound)
                        } else {
                            ForEach(cards) { card in cardView(card) }

                            if revealed {
                                scoreView
                                primaryButton("Another Round", action: startRound)
                            } else {
                                primaryButton("Reveal", action: { withAnimation { revealed = true } })
                                    .disabled(picked.count != Self.roundSize)
                                    .opacity(picked.count == Self.roundSize ? 1 : 0.5)
                                Text("Pick \(Self.roundSize).")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }

                        if let errorText {
                            Text(errorText)
                                .font(Theme.captionFont)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Blind Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }

    private var scoreView: some View {
        let caught = cards.filter { $0.isFake && picked.contains($0.id) }.count
        let message: String
        switch caught {
        case Self.roundSize: message = "You caught every fake. The prompt needs more of your messages."
        case 0: message = "You didn't catch a single fake. That's your voice."
        default: message = "You caught \(caught) of \(Self.roundSize). Close enough to fool a stranger."
        }
        return Text(message)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Theme.cardBackground)
            .cornerRadius(14)
    }

    private func cardView(_ card: Card) -> some View {
        let isPicked = picked.contains(card.id)
        return Button {
            guard !revealed else { return }
            if isPicked { picked.remove(card.id) } else if picked.count < Self.roundSize { picked.insert(card.id) }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text(card.text)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if revealed {
                    Text(card.isFake ? "AI" : "You")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(card.isFake ? Theme.ember : Theme.ash)
                        .cornerRadius(6)
                } else if isPicked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isPicked ? Theme.accent.opacity(0.1) : Theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPicked ? Theme.accent : Theme.smoke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func notice(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(Theme.textPrimary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.smoke)
            .cornerRadius(12)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.accent)
                .cornerRadius(14)
        }
    }

    private func startRound() {
        let real = appState.heldOutMessages(count: Self.roundSize)
        let prompt = appState.onDevicePrompt()
        let situations = Array(Self.situations.shuffled().prefix(Self.roundSize))
        isLoading = true
        errorText = nil
        revealed = false
        picked = []
        Task {
            do {
                var fakes: [String] = []
                for situation in situations {
                    fakes.append(try await VoiceModel.fake(about: situation, voicePrompt: prompt))
                }
                cards = (real.map { Card(text: $0, isFake: false) } + fakes.map { Card(text: $0, isFake: true) }).shuffled()
            } catch {
                errorText = VoiceModel.friendlyMessage(for: error)
                cards = []
            }
            isLoading = false
        }
    }
}
