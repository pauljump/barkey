import SwiftUI
import Combine
import KeyboardKit

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? Theme.accent : Theme.progressTrack)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)

                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    privacyStep.tag(1)
                    setupStep.tag(2)
                    liveStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Ember icon placeholder
            ZStack {
                Circle()
                    .fill(Theme.ember.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "flame.fill")
                    .font(.system(size: 52))
                    .foregroundColor(Theme.ember)
            }

            Text("BARkey")
                .font(Theme.titleFont)
                .foregroundColor(Theme.textPrimary)

            Text("Learn how you write.\nIn a couple hundred texts, you'll have your voice — forever.")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                withAnimation { currentStep = 1 }
            } label: {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 2: Privacy

    private var privacyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.ember)

            Text("What We Track")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 16) {
                privacyRow(icon: "checkmark.circle.fill", color: .green,
                    text: "Messages you send, saved on this iPhone so your prompt can quote your real voice")
                privacyRow(icon: "checkmark.circle.fill", color: .green,
                    text: "Emails, links and long numbers blanked out before saving")
                privacyRow(icon: "checkmark.circle.fill", color: .green,
                    text: "Every saved message visible to you, deletable one by one or all at once")

                Divider().padding(.vertical, 4)

                privacyRow(icon: "xmark.circle.fill", color: .red,
                    text: "Search bars, logins, codes, card numbers — skipped")
                privacyRow(icon: "xmark.circle.fill", color: .red,
                    text: "Who you message — never recorded")
                privacyRow(icon: "xmark.circle.fill", color: .red,
                    text: "Servers, accounts, analytics — there are none")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                withAnimation { currentStep = 2 }
            } label: {
                Text("I Understand")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 3: Enable Keyboard

    private var setupStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Enable BARkey Keyboard")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 20) {
                setupRow(number: "1", title: "Open Settings",
                    detail: "Tap the button below to go to Settings")
                setupRow(number: "2", title: "Tap Keyboards",
                    detail: "Under BARkey, tap \"Keyboards\"")
                setupRow(number: "3", title: "Enable BARkey",
                    detail: "Toggle BARkey on")
                setupRow(number: "4", title: "Allow Full Access",
                    detail: "Required so the keyboard can hand your messages to the BARkey app. Everything stays on this iPhone.")
            }
            .padding(.horizontal, 24)

            SetupChecklist(status: appState.keyboardStatus)
                .padding(.horizontal, 24)

            Button {
                // Deep link to keyboard settings
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.accent.opacity(0.12))
                .cornerRadius(14)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                withAnimation { currentStep = 3 }
            } label: {
                Text("I've Enabled It")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 4: You're Live

    private var liveStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.ember.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(Theme.ember)
            }

            Text("You're Live")
                .font(Theme.titleFont)
                .foregroundColor(Theme.textPrimary)

            Text("Start typing normally in any app.\nBARkey is learning your voice in the background.\n\nCheck back here to see your progress.")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Mini progress bar preview
            VStack(spacing: 8) {
                ProgressView(value: 0, total: Double(StyleProfile.targetMessageCount))
                    .tint(Theme.ember)
                Text("0 / \(StyleProfile.targetMessageCount) messages")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                appState.completeOnboarding()
            } label: {
                Text("Let's Go")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers

    private func privacyRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))
            Text(text)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
        }
    }

    private func setupRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Theme.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(detail)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

/// Live check of the two settings the keyboard needs.
struct SetupChecklist: View {
    @ObservedObject var status: KeyboardStatusContext
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row("BARkey keyboard added", done: status.isKeyboardEnabled)
            row("Full Access allowed", done: status.isFullAccessEnabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.smoke.opacity(0.5))
        .cornerRadius(12)
        .onReceive(timer) { _ in status.refresh() }
    }

    private func row(_ text: String, done: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundColor(done ? .green : Theme.ash)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textPrimary)
        }
    }
}
