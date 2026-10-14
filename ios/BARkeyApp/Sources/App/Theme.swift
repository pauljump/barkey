import SwiftUI

enum Theme {
    // BARkey brand — warm, temporary, ember-like
    static let ember = Color(red: 1.0, green: 0.42, blue: 0.21)       // #FF6B35
    static let ash = Color(red: 0.35, green: 0.33, blue: 0.32)        // #595553
    static let smoke = Color(red: 0.92, green: 0.90, blue: 0.88)      // #EBE6E1
    static let charcoal = Color(red: 0.15, green: 0.14, blue: 0.13)   // #262421
    static let warmWhite = Color(red: 0.98, green: 0.96, blue: 0.94)  // #FAF5F0

    // Semantic colors
    static let accent = ember
    static let background = warmWhite
    static let cardBackground = Color.white
    static let textPrimary = charcoal
    static let textSecondary = ash
    static let progressTrack = smoke
    static let progressFill = ember

    // Typography
    static let titleFont: Font = .system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont: Font = .system(size: 20, weight: .semibold, design: .rounded)
    static let bodyFont: Font = .system(size: 16, weight: .regular, design: .default)
    static let captionFont: Font = .system(size: 13, weight: .medium, design: .default)
    static let monoFont: Font = .system(size: 14, weight: .regular, design: .monospaced)
}
