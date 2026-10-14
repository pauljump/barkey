import SwiftUI
import KeyboardKit

@main
struct BARkeyApp: App {
    @StateObject private var appState: AppState

    init() {
        #if DEBUG
        DemoData.seedIfRequested()
        #endif
        _appState = StateObject(wrappedValue: AppState())
    }

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
