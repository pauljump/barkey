import SwiftUI

struct ExportView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var copied = false
    @State private var burned = false
    @State private var shortlinkURL: String?
    @State private var isUploading = false
    @State private var uploadError: String?

    private var prompt: String {
        appState.generatePrompt()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Theme.ember)
                            Text("Your Voice Prompt")
                                .font(Theme.titleFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("Copy this or get a shortlink to use anywhere.")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        // Prompt preview
                        Text(prompt)
                            .font(Theme.monoFont)
                            .foregroundColor(Theme.textPrimary)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.smoke)
                            .cornerRadius(12)

                        // Copy button
                        Button {
                            UIPasteboard.general.string = prompt
                            copied = true
                            appState.markExported()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copied!" : "Copy to Clipboard")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(copied ? Color.green : Theme.accent)
                            .cornerRadius(14)
                            .animation(.easeInOut, value: copied)
                        }

                        // Shortlink section
                        VStack(spacing: 12) {
                            if let url = shortlinkURL {
                                // Show the shortlink
                                VStack(spacing: 8) {
                                    Text("Your shortlink")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Button {
                                        UIPasteboard.general.string = url
                                    } label: {
                                        HStack {
                                            Image(systemName: "link")
                                            Text(url)
                                                .lineLimit(1)
                                        }
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Theme.accent)
                                        .padding(14)
                                        .frame(maxWidth: .infinity)
                                        .background(Theme.accent.opacity(0.08))
                                        .cornerRadius(12)
                                    }
                                    Text("Tap to copy. Paste this one link into any LLM.")
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            } else {
                                // Upload button
                                Button {
                                    uploadPrompt()
                                } label: {
                                    HStack {
                                        if isUploading {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "link.badge.plus")
                                        }
                                        Text(isUploading ? "Creating shortlink..." : "Get Shortlink")
                                    }
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Theme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Theme.accent.opacity(0.08))
                                    .cornerRadius(14)
                                }
                                .disabled(isUploading)

                                if let error = uploadError {
                                    Text(error)
                                        .font(Theme.captionFont)
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How to use")
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)

                            instructionRow("1", "Open ChatGPT, Claude, Gemini, or any LLM")
                            instructionRow("2", "Paste the prompt or shortlink as the system prompt")
                            instructionRow("3", "Everything it writes will now match your voice")
                        }

                        // Burn
                        if appState.hasExported && !burned {
                            Button {
                                appState.burnMessages()
                                burned = true
                            } label: {
                                HStack {
                                    Image(systemName: "flame")
                                    Text("Burn captured messages")
                                    Spacer()
                                    Text("delete all raw text")
                                        .font(Theme.captionFont)
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.ember)
                                .padding(18)
                                .background(Theme.ember.opacity(0.08))
                                .cornerRadius(14)
                            }
                        }

                        if burned {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.green)
                                Text("Messages burned. Your voice prompt lives\nwherever you paste it. Delete BARkey anytime.")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 8)
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
        }
    }

    private func uploadPrompt() {
        isUploading = true
        uploadError = nil

        Task {
            do {
                let response = try await BARkeyAPI.uploadPrompt(prompt)
                await MainActor.run {
                    shortlinkURL = response.url
                    appState.markExported()
                    isUploading = false
                }
            } catch {
                await MainActor.run {
                    uploadError = "Upload failed. Check your connection."
                    isUploading = false
                }
            }
        }
    }

    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Theme.ash)
                .clipShape(Circle())
            Text(text)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
        }
    }
}
