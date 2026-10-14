import SwiftUI
import KeyboardKit

@main
struct BARkeyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            KeyboardAppView(for: .barkey) {
                if appState.hasCompletedOnboarding {
                    HomeView()
                        .environmentObject(appState)
                } else {
                    OnboardingView()
                        .environmentObject(appState)
                }
            }
        }
    }
}
