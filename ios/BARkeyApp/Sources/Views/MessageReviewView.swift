import SwiftUI

/// Shows captured messages as truncated previews for transparency.
/// Users can delete messages they don't want included, but can't copy full text.
struct MessageReviewView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showingExport = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if appState.messages.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 36))
                            .foregroundColor(Theme.textSecondary)
                        Text("No messages captured yet")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                } else {
                    VStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Text("\(appState.messages.count) messages captured")
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)
                            Text("Swipe to remove any you don't want included.")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.vertical, 16)

                        List {
                            ForEach(Array(appState.messages.enumerated()), id: \.offset) { index, message in
                                HStack {
                                    Text(truncate(message, to: 40))
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.textPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(message.split(separator: " ").count)w")
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .listRowBackground(Theme.cardBackground)
                            }
                            .onDelete { indexSet in
                                for index in indexSet.sorted().reversed() {
                                    appState.deleteMessage(at: index)
                                }
                            }
                        }
                        .listStyle(.plain)

                        if appState.isReady {
                            Button { showingExport = true } label: {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("Generate Voice Prompt")
                                }
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.accent)
                                .cornerRadius(14)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("Your Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
            .sheet(isPresented: $showingExport) {
                ExportView()
                    .environmentObject(appState)
            }
        }
    }

    private func truncate(_ text: String, to maxLength: Int) -> String {
        if text.count <= maxLength { return text }
        let end = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<end]) + "..."
    }
}
