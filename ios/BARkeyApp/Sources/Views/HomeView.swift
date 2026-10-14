import SwiftUI
import Combine
import KeyboardKit

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingReview = false
    @State private var showingExport = false
    @State private var showingRewrite = false
    @State private var showingBlindTest = false
    @State private var showingPricing = false
    @State private var confirmingBurn = false

    let refreshTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        KeyboardSetupBanner(status: appState.keyboardStatus)
                        if appState.isPaused { pausedBanner }
                        progressCard
                        if appState.totalMessages == 0 {
                            howItWorksCard
                        }
                        styleSummaryCard
                        actionsSection
                        controlsCard
                        betaCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .onReceive(refreshTimer) { _ in appState.refresh() }
            .onAppear {
                appState.refresh()
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if let i = args.firstIndex(of: "-openSheet"), i + 1 < args.count {
                    switch args[i + 1] {
                    case "export": showingExport = true
                    case "try": showingRewrite = true
                    case "blind": showingBlindTest = true
                    case "review": showingReview = true
                    default: break
                    }
                }
                #endif
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { appState.refresh() }
            }
            .sheet(isPresented: $showingReview) {
                MessageReviewView().environmentObject(appState)
            }
            .sheet(isPresented: $showingExport) {
                ExportView().environmentObject(appState)
            }
            .sheet(isPresented: $showingRewrite) {
                RewriteView().environmentObject(appState)
            }
            .sheet(isPresented: $showingBlindTest) {
                BlindTestView().environmentObject(appState)
            }
            .sheet(isPresented: $showingPricing) {
                PricingView()
            }
            .confirmationDialog(
                "Burn all \(appState.totalMessages) captured messages?",
                isPresented: $confirmingBurn,
                titleVisibility: .visible
            ) {
                Button("Burn everything", role: .destructive) { appState.burnEverything() }
            } message: {
                Text("They're deleted from this iPhone and can't be recovered. Copy your prompt first if you want to keep it.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("BARkey")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(Theme.charcoal)
            Text("Burn After Reading Keyboard")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.ash)
                .tracking(1.2)
        }
        .padding(.top, 8)
    }

    private var pausedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "pause.circle.fill")
                .foregroundColor(Theme.ash)
            Text("Capture is paused. BARkey still types, but isn't saving messages.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textPrimary)
            Spacer(minLength: 0)
            Button("Resume") { appState.isPaused = false }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.accent)
        }
        .padding(14)
        .background(Theme.smoke.opacity(0.6))
        .cornerRadius(14)
    }

    // MARK: - Progress

    private var progressCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Theme.progressTrack, lineWidth: 6)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: appState.progress)
                    .stroke(Theme.ember, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: appState.progress)

                Image(systemName: appState.isReady ? "checkmark" : "flame.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.ember)
            }

            Text("\(appState.totalMessages) / \(StyleProfile.targetMessageCount)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .contentTransition(.numericText())

            Text(progressCaption)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }

    private var progressCaption: String {
        let count = appState.totalMessages
        if count == 0 {
            return "messages captured. Send a few texts with BARkey to start."
        } else if !appState.canExport {
            let left = StyleProfile.minimumForPrompt - count
            return "messages captured. \(left) more for your first voice prompt."
        } else if !appState.isReady {
            return "Your voice prompt is ready to try. It keeps getting sharper up to \(StyleProfile.targetMessageCount)."
        }
        return "Your voice is at its best. Export it, then burn it."
    }

    // MARK: - How it works (before the first message)

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How it works")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)

            stepRow("keyboard", "Type normally", "Use BARkey to text in iMessage, WhatsApp, anywhere. Search bars, logins and codes are skipped.")
            stepRow("text.bubble", "It keeps what you send", "When a message is sent, BARkey saves it on this iPhone. Emails, links and numbers are blanked out first.")
            stepRow("wand.and.stars", "Get your voice prompt", "From \(StyleProfile.minimumForPrompt) messages, BARkey writes a prompt that makes any AI write like you.")
            stepRow("flame", "Burn it all", "Copy the prompt, burn your messages, delete BARkey.")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }

    // MARK: - Style summary

    @ViewBuilder
    private var styleSummaryCard: some View {
        if appState.profile.messageCount >= 25 {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your style so far")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)

                Text(PromptGenerator.generateSummary(from: appState.profile))
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)

                HStack(spacing: 10) {
                    statBadge("Avg words", "\(Int(appState.profile.avgWordsPerMessage.rounded()))")
                    statBadge("Emoji", "\(Int(appState.profile.emojiRate * 100))%")
                    statBadge("Slang", "\(Int(appState.profile.slangRate * 100))%")
                    statBadge("!", "\(Int(appState.profile.exclamationRate * 100))%")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Theme.cardBackground)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if appState.canExport {
                actionButton("doc.text", "Get Your Voice Prompt", detail: nil, primary: true) { showingExport = true }
                actionButton("wand.and.stars", "Try Your Voice", detail: "on-device", primary: false) { showingRewrite = true }
                actionButton("eye.trianglebadge.exclamationmark", "Spot the Fake", detail: "blind test", primary: false) { showingBlindTest = true }
            }
            if appState.totalMessages > 0 {
                actionButton("text.bubble", "Review Messages", detail: "\(appState.totalMessages) saved", primary: false) { showingReview = true }
            }
        }
    }

    // MARK: - Controls

    private var controlsCard: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $appState.isPaused) {
                Label("Pause capture", systemImage: "pause.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
            }
            .tint(Theme.accent)
            .padding(16)

            if appState.totalMessages > 0 {
                Divider().padding(.leading, 16)
                Button { confirmingBurn = true } label: {
                    HStack {
                        Label("Burn everything", systemImage: "flame")
                        Spacer()
                        Text("delete all messages")
                            .font(Theme.captionFont)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.ember)
                    .padding(16)
                }
            }
        }
        .background(Theme.cardBackground)
        .cornerRadius(14)
    }

    private var betaCard: some View {
        Button { showingPricing = true } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lock.shield")
                    .foregroundColor(Theme.ash)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free during the TestFlight beta")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Your messages stay on this iPhone. BARkey has no server and no analytics. Nothing is sent anywhere unless you copy or share it yourself.")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.ash)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Theme.smoke.opacity(0.5))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func actionButton(_ icon: String, _ title: String, detail: String?, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                if let detail {
                    Text(detail).font(Theme.captionFont)
                } else {
                    Image(systemName: "chevron.right")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(primary ? .white : Theme.accent)
            .padding(18)
            .background(primary ? Theme.accent : Theme.accent.opacity(0.08))
            .cornerRadius(14)
        }
    }

    private func stepRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.ember)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private func statBadge(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.smoke.opacity(0.4))
        .cornerRadius(8)
    }
}

/// Tells the person exactly which setup step is missing, live.
struct KeyboardSetupBanner: View {
    @ObservedObject var status: KeyboardStatusContext

    var body: some View {
        if !status.isKeyboardEnabled || !status.isFullAccessEnabled {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    status.isKeyboardEnabled ? "Turn on Full Access" : "Add the BARkey keyboard",
                    systemImage: "exclamationmark.circle.fill"
                )
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

                Text(status.isKeyboardEnabled
                     ? "BARkey can't save messages without Full Access. Settings → BARkey → Keyboards → BARkey → Allow Full Access."
                     : "Settings → BARkey → Keyboards → turn on BARkey and Allow Full Access. Then pick it with the 🌐 key.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent)
                        .cornerRadius(12)
                }
            }
            .padding(16)
            .background(Theme.ember.opacity(0.08))
            .cornerRadius(16)
        }
    }
}
