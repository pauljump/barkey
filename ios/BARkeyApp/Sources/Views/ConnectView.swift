import SwiftUI

/// Your voice, used directly by your assistants. No copy-paste: one private link.
struct ConnectView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var link: VoiceLink
    @Environment(\.dismiss) var dismiss
    @State private var copied: String?
    @State private var confirmingBurn = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        if link.isPublished { linksCard } else { publishCard }
                        shortcutCard
                        privacyCard
                        if link.isPublished { burnButton }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Your assistants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundColor(Theme.accent) } }
            .confirmationDialog("Take your voice offline?", isPresented: $confirmingBurn, titleVisibility: .visible) {
                Button("Burn the online copy", role: .destructive) { Task { await link.burn() } }
            } message: {
                Text("The encrypted copy is deleted from the server and every link stops working. Your messages on this iPhone are not touched.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Write like me, everywhere")
                .font(Theme.titleFont)
                .foregroundColor(Theme.textPrimary)
            Text("Instead of pasting a prompt, give your assistant one private link. It reads your voice when it drafts for you. Built from \(appState.totalMessages) of your messages.")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
        }
    }

    private var publishCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Put your voice online")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
            Text("Your prompt is encrypted on this iPhone first. The server only ever holds the scrambled copy; the key stays in your link. Burn it any time.")
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
            if let error = link.lastError {
                Text(error).font(.system(size: 13)).foregroundColor(Theme.ember)
            }
            Button {
                Task { await appState.publishVoice() }
            } label: {
                HStack {
                    if link.isWorking { ProgressView().tint(.white) } else { Image(systemName: "link") }
                    Text(link.isWorking ? "Publishing…" : "Create my private link")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(appState.canExport ? Theme.accent : Theme.ash)
                .cornerRadius(14)
            }
            .disabled(!appState.canExport || link.isWorking)
            if !appState.canExport {
                Text("Available at \(StyleProfile.minimumForPrompt) messages.")
                    .font(Theme.captionFont).foregroundColor(Theme.textSecondary)
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(20)
    }

    private var linksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Online", systemImage: "checkmark.seal.fill").foregroundColor(.green)
                Spacer()
                if let at = link.publishedAt {
                    Text("updated \(at.formatted(.relative(presentation: .named)))")
                        .font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                }
            }
            .font(.system(size: 15, weight: .semibold))

            if let error = link.lastError { Text(error).font(.system(size: 13)).foregroundColor(Theme.ember) }

            linkRow("Claude, ChatGPT", "Add as a connector (MCP). Tools: my_voice, write_like_me.", link.mcpURL, key: "mcp")
            linkRow("Muse", "Tell Muse: “Build a custom connector that GETs this URL and uses the voice field whenever you write as me.”", link.restURL, key: "rest")
            linkRow("Dot and anything else", "A plain page. Share it, or paste the link into the chat and ask it to write like that.", link.pageURL, key: "page")

            Button {
                Task { await appState.publishVoice() }
            } label: {
                HStack {
                    if link.isWorking { ProgressView() } else { Image(systemName: "arrow.clockwise") }
                    Text("Refresh with my latest \(appState.totalMessages) messages")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.accent.opacity(0.08))
                .cornerRadius(12)
            }
            .disabled(link.isWorking)
            Text("Refreshes on its own after every 25 new messages. Same links, new voice.")
                .font(Theme.captionFont).foregroundColor(Theme.textSecondary)
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(20)
    }

    private func linkRow(_ title: String, _ detail: String, _ url: URL?, key: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.textPrimary)
            Text(detail).font(.system(size: 13)).foregroundColor(Theme.textSecondary)
            if let url {
                HStack(spacing: 8) {
                    Text(url.absoluteString)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = url.absoluteString
                        copied = key
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { if copied == key { copied = nil } }
                    } label: {
                        Text(copied == key ? "Copied" : "Copy")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(copied == key ? .green : Theme.accent)
                    }
                    ShareLink(item: url) { Image(systemName: "square.and.arrow.up").foregroundColor(Theme.accent) }
                }
                .padding(10)
                .background(Theme.smoke.opacity(0.6))
                .cornerRadius(10)
            }
        }
    }

    private var shortcutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In any app, from the keyboard")
                .font(Theme.headlineFont).foregroundColor(Theme.textPrimary)
            Text("Type the shortcut word and a space in any chat (Dot, Muse, ChatGPT, anywhere) and BARkey replaces it with a short version of your voice, then keeps typing. Works with no link at all.")
                .font(.system(size: 14)).foregroundColor(Theme.textSecondary)
            Toggle(isOn: $appState.voiceShortcutEnabled) {
                Text("Shortcut on").font(.system(size: 15, weight: .medium)).foregroundColor(Theme.textPrimary)
            }.tint(Theme.accent)
            HStack {
                Text("Word").font(.system(size: 15, weight: .medium)).foregroundColor(Theme.textPrimary)
                Spacer()
                TextField("myvoice", text: $appState.voiceShortcut)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 15, design: .monospaced))
                    .frame(maxWidth: 160)
            }
            .padding(12)
            .background(Theme.smoke.opacity(0.6))
            .cornerRadius(10)
            Text(appState.canExport ? "Try it: open any chat, type \(appState.voiceShortcut) and a space." : "Available at \(StyleProfile.minimumForPrompt) messages.")
                .font(Theme.captionFont).foregroundColor(Theme.textSecondary)
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(20)
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield").foregroundColor(Theme.ash)
            Text("The server never sees your words in the clear: it stores the encrypted prompt and decrypts in memory only when a link with the key is used. Nothing else about you is kept. Burn deletes it.")
                .font(.system(size: 12)).foregroundColor(Theme.ash)
        }
        .padding(16)
        .background(Theme.smoke.opacity(0.5))
        .cornerRadius(14)
    }

    private var burnButton: some View {
        Button { confirmingBurn = true } label: {
            HStack {
                Image(systemName: "flame")
                Text("Take my voice offline")
                Spacer()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Theme.ember)
            .padding(18)
            .background(Theme.ember.opacity(0.08))
            .cornerRadius(14)
        }
    }
}
