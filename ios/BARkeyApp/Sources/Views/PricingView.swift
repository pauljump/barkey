import SwiftUI

struct PricingView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 8) {
                            Text("$9.99")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundColor(Theme.charcoal)
                            Text("One time. Not a subscription.")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.ash)
                        }
                        .padding(.top, 8)

                        // What you get
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Own your voice")
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)

                            featureRow(
                                icon: "wand.and.stars",
                                title: "Your voice prompt",
                                detail: "A portable system prompt built from your real writing. Paste it into any LLM and everything it writes sounds like you. Not generic. Not close. You."
                            )

                            featureRow(
                                icon: "link",
                                title: "Hosted shortlink",
                                detail: "Get a permanent URL for your voice — like barkey.app/paul. Paste one link into ChatGPT's custom instructions, Claude's system prompt, or any AI tool. Update your voice anytime, every link stays current."
                            )

                            featureRow(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Unlimited regeneration",
                                detail: "Your writing evolves. Capture new messages anytime and regenerate your voice prompt as many times as you want. The $9.99 unlocks the feature permanently."
                            )

                            featureRow(
                                icon: "square.and.arrow.up",
                                title: "Multiple export formats",
                                detail: "Optimized prompts for ChatGPT, Claude, Gemini, and other platforms. Each format is tuned for how that specific AI handles system instructions."
                            )
                        }
                        .padding(20)
                        .background(Theme.cardBackground)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)

                        // What's free
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What's free")
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)

                            freeRow("keyboard", "Use the BARkey keyboard")
                            freeRow("chart.bar", "Capture unlimited messages")
                            freeRow("text.bubble", "Review what we captured")
                            freeRow("eye", "See your style summary")
                            freeRow("trash", "Delete your data anytime")
                        }
                        .padding(20)
                        .background(Theme.cardBackground)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)

                        // Philosophy
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "flame")
                                    .foregroundColor(Theme.ember)
                                Text("The anti-app")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                            }

                            Text("Most apps want you to stay forever. BARkey wants you to leave.")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)

                            Text("We built BARkey to be deleted. Capture your voice, export your prompt, burn your data, uninstall. You keep your voice forever. We keep nothing.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Theme.ash)

                            Text("Your messages never leave your phone during capture. When you export, your prompt is generated on-device. The hosted shortlink is the only thing that touches our servers — and you control what's on it.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Theme.ash)
                        }
                        .padding(20)
                        .background(Theme.ember.opacity(0.06))
                        .cornerRadius(20)

                        // FAQ-style
                        VStack(alignment: .leading, spacing: 16) {
                            faqRow(
                                q: "Why not just paste my messages into ChatGPT myself?",
                                a: "You could. But \"write like me\" with a few pasted messages gives mediocre results. BARkey analyzes hundreds of messages to find your actual patterns — sentence length, punctuation habits, vocabulary, openers, tone. The prompt we generate is engineered to make LLMs match your voice precisely."
                            )
                            faqRow(
                                q: "What if my writing style changes?",
                                a: "Capture new messages and regenerate. Your $9.99 unlocks regeneration forever."
                            )
                            faqRow(
                                q: "Do you store my messages on a server?",
                                a: "No. Messages are captured and stored only on your device. When you burn them, they're gone. We literally cannot read your messages."
                            )
                        }
                        .padding(20)
                        .background(Theme.cardBackground)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Pricing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.ember)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text(detail)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }

    private func freeRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.green)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Theme.ash)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Theme.textPrimary)
        }
    }

    private func faqRow(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(q)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Text(a)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Theme.textSecondary)
        }
    }
}
