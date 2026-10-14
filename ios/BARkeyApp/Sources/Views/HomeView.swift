import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingReview = false
    @State private var showingRewrite = false
    @State private var showingPricing = false

    let refreshTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        progressCard
                        if appState.totalMessages == 0 {
                            howItWorksCard
                            pricingCard
                        }
                        styleSummaryCard
                        actionsSection
                        if appState.totalMessages > 0 && !appState.hasExported {
                            transparencyCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .onReceive(refreshTimer) { _ in
                appState.refresh()
            }
            .onAppear {
                appState.refresh()
            }
            .sheet(isPresented: $showingReview) {
                MessageReviewView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingRewrite) {
                RewriteView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingPricing) {
                PricingView()
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

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(spacing: 16) {
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

            if appState.isReady {
                Text("Your voice is ready")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)
                Text("Review your messages and generate your prompt.")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("\(appState.totalMessages) / \(StyleProfile.targetMessageCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text("messages captured")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }

    // MARK: - How It Works (shown before first message)

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How it works")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)

            stepRow(
                icon: "keyboard",
                title: "Type normally",
                detail: "Use BARkey as your keyboard in any app. Text, email, whatever."
            )
            stepRow(
                icon: "chart.bar",
                title: "We learn your voice",
                detail: "Your writing patterns are captured on-device. Nothing leaves your phone."
            )
            stepRow(
                icon: "wand.and.stars",
                title: "Get your voice prompt",
                detail: "At 500 messages, we generate a prompt that makes any AI write like you."
            )
            stepRow(
                icon: "flame",
                title: "Burn it all",
                detail: "Export your prompt, delete your data, delete BARkey. You're done forever."
            )

            // Transparency note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .foregroundColor(Theme.ash)
                Text("Yes, we capture your messages. So does every keyboard app. The difference: we show you exactly what we stored, we never send it anywhere, and we delete it when you're done.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Theme.ash)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }

    // MARK: - Pricing (shown upfront)

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What you get for $9.99")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)

            pricingRow("doc.text", "Your voice prompt", "A portable prompt that makes any LLM write exactly like you. Works with ChatGPT, Claude, Gemini, or anything else.")
            pricingRow("link", "Hosted shortlink", "A shareable URL for your voice. Paste one link into any AI's custom instructions instead of a wall of text.")
            pricingRow("infinity", "Yours forever", "One payment. No subscription. Your voice prompt is yours to keep, share, and use anywhere.")
            pricingRow("flame", "Then delete us", "We succeed when you don't need us anymore. Export, burn your data, uninstall.")

            Text("Capturing is free. You only pay when your voice is ready.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.ember)
                .padding(.top, 4)
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }

    // MARK: - Style Summary

    private var styleSummaryCard: some View {
        Group {
            if appState.profile.messageCount >= 50 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Style")
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)

                    Text(PromptGenerator.generateSummary(from: appState.profile))
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)

                    HStack(spacing: 16) {
                        statBadge("Avg", "\(Int(appState.profile.avgWordsPerMessage))w")
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
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if appState.totalMessages > 0 {
                Button { showingReview = true } label: {
                    HStack {
                        Image(systemName: "text.bubble")
                        Text("Review Messages")
                        Spacer()
                        Text("\(appState.totalMessages) captured")
                            .font(Theme.captionFont)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(appState.isReady ? .white : Theme.accent)
                    .padding(18)
                    .background(appState.isReady ? Theme.accent : Theme.accent.opacity(0.08))
                    .cornerRadius(14)
                }
            }

            if appState.profile.messageCount >= 100 {
                Button { showingRewrite = true } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Try Your Voice")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .padding(18)
                    .background(Theme.accent.opacity(0.08))
                    .cornerRadius(14)
                }
            }

            // Pricing
            Button { showingPricing = true } label: {
                HStack {
                    Image(systemName: "tag")
                    Text("Pricing")
                    Spacer()
                    Text("$9.99 one-time")
                        .font(Theme.captionFont)
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.textSecondary)
                .padding(18)
                .background(Theme.smoke.opacity(0.5))
                .cornerRadius(14)
            }

            if appState.hasExported {
                Button {
                    appState.resetProfile()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Start Fresh")
                        Spacer()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .padding(18)
                    .background(Theme.smoke.opacity(0.5))
                    .cornerRadius(14)
                }
            }
        }
    }

    // MARK: - Transparency Card (shown while capturing)

    private var transparencyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "eye")
                    .foregroundColor(Theme.ash)
                Text("Full transparency")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
            }
            Text("Your messages are stored on this device only. Nothing is sent to a server. When you export your voice prompt, you can burn all captured messages with one tap. We built BARkey to be deleted.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Theme.ash)
        }
        .padding(16)
        .background(Theme.smoke.opacity(0.5))
        .cornerRadius(14)
    }

    // MARK: - Helpers

    private func stepRow(icon: String, title: String, detail: String) -> some View {
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
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private func pricingRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Theme.ember)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(detail)
                    .font(.system(size: 13, weight: .regular))
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.smoke.opacity(0.4))
        .cornerRadius(8)
    }
}
