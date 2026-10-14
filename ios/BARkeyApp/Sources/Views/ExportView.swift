import SwiftUI

struct ExportView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var copied = false
    @State private var confirmingBurn = false
    @State private var burned = false
    @State private var prompt = ""
    @State private var showingFullPrompt = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.ember)
                            Text("Your Voice Prompt")
                                .font(Theme.titleFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("Built from \(appState.totalMessages) of your messages, on this iPhone.")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        if !appState.isReady {
                            Text("This is an early draft. It gets noticeably better by \(StyleProfile.targetMessageCount) messages.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textPrimary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.ember.opacity(0.08))
                                .cornerRadius(10)
                        }

                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = prompt
                                copied = true
                                appState.markExported()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                            } label: {
                                Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(copied ? Color.green : Theme.accent)
                                    .cornerRadius(14)
                                    .animation(.easeInOut, value: copied)
                            }

                            ShareLink(item: prompt, subject: Text("My voice prompt")) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Theme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Theme.accent.opacity(0.08))
                                    .cornerRadius(14)
                            }
                            .simultaneousGesture(TapGesture().onEnded { appState.markExported() })
                        }

                        Text(prompt)
                            .font(Theme.monoFont)
                            .foregroundColor(Theme.textPrimary)
                            .textSelection(.enabled)
                            .lineLimit(showingFullPrompt ? nil : 14)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.smoke)
                            .cornerRadius(12)

                        Button(showingFullPrompt ? "Show less" : "Show the whole prompt") {
                            withAnimation { showingFullPrompt.toggle() }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.accent)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Where to paste it")
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)

                            instructionRow("ChatGPT", "Settings → Personalization → Custom instructions.")
                            instructionRow("Claude", "Put it in a Project's instructions, or save it as a custom style.")
                            instructionRow("Gemini", "Make a Gem and paste it as the Gem's instructions.")
                            instructionRow("Anything else", "Paste it at the start of a chat, before you ask for a draft.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if burned {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.green)
                                Text("Messages burned. Your voice lives wherever you pasted it.\nYou can delete BARkey now.")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 8)
                        } else {
                            Button { confirmingBurn = true } label: {
                                HStack {
                                    Image(systemName: "flame")
                                    Text("Burn captured messages")
                                    Spacer()
                                    Text(appState.hasExported ? "you've copied it" : "copy first")
                                        .font(Theme.captionFont)
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.ember)
                                .padding(18)
                                .background(Theme.ember.opacity(0.08))
                                .cornerRadius(14)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .onAppear { prompt = appState.generatePrompt() }
            .confirmationDialog("Burn all captured messages?", isPresented: $confirmingBurn, titleVisibility: .visible) {
                Button("Burn everything", role: .destructive) {
                    appState.burnEverything()
                    burned = true
                }
            } message: {
                Text(appState.hasExported
                     ? "The prompt you copied keeps working. The messages are gone for good."
                     : "You haven't copied the prompt yet. Once burned, it can't be rebuilt.")
            }
        }
    }

    private func instructionRow(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
    }
}
