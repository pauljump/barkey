import SwiftUI

/// Runs the voice prompt on Apple's on-device model: rewrite a message in your
/// voice, or draft the reply you'd send.
struct RewriteView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case rewrite = "Rewrite it"
        case reply = "Reply to it"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .rewrite
    @State private var inputText = ""
    @State private var result = ""
    @State private var isWorking = false
    @State private var errorText: String?
    @FocusState private var editorFocused: Bool

    private var status: VoiceModel.Status { VoiceModel.status }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.ember)
                            Text("Try Your Voice")
                                .font(Theme.titleFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("Runs on this iPhone with Apple Intelligence. Nothing is sent anywhere.")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        if case .unavailable(let reason) = status {
                            Text(reason)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textPrimary)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.smoke)
                                .cornerRadius(12)
                        }

                        Picker("Mode", selection: $mode) {
                            ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(mode == .rewrite ? "A message to rewrite in your voice" : "A message someone sent you")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)

                            TextEditor(text: $inputText)
                                .font(Theme.bodyFont)
                                .focused($editorFocused)
                                .frame(minHeight: 110)
                                .padding(10)
                                .scrollContentBackground(.hidden)
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.smoke, lineWidth: 1))
                        }

                        Button(action: run) {
                            HStack {
                                if isWorking { ProgressView().tint(.white) }
                                Text(isWorking ? "Writing…" : (mode == .rewrite ? "Rewrite in My Voice" : "Write My Reply"))
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canRun ? Theme.accent : Theme.ash)
                            .cornerRadius(14)
                        }
                        .disabled(!canRun)

                        if let errorText {
                            Text(errorText)
                                .font(Theme.captionFont)
                                .foregroundColor(.red)
                        }

                        if !result.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("In your voice")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)
                                Text(result)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textPrimary)
                                    .textSelection(.enabled)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.ember.opacity(0.08))
                                    .cornerRadius(12)
                                HStack {
                                    Button {
                                        UIPasteboard.general.string = result
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    Spacer()
                                    Button(action: run) {
                                        Label("Try again", systemImage: "arrow.clockwise")
                                    }
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.accent)

                                Text("Apple's on-device model is small, so this is a rough take. Your exported prompt does better in ChatGPT or Claude.")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .onAppear {
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if let i = args.firstIndex(of: "-tryText"), i + 1 < args.count {
                    inputText = args[i + 1]
                    run()
                }
                #endif
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

    private var canRun: Bool {
        status == .ready && !isWorking && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func run() {
        guard canRun else { return }
        editorFocused = false
        isWorking = true
        errorText = nil
        let text = inputText
        let prompt = appState.onDevicePrompt()
        let mode = mode
        Task {
            do {
                let output = mode == .rewrite
                    ? try await VoiceModel.rewrite(text, voicePrompt: prompt)
                    : try await VoiceModel.reply(to: text, voicePrompt: prompt)
                result = output
            } catch {
                errorText = VoiceModel.friendlyMessage(for: error)
            }
            isWorking = false
        }
    }
}
