import SwiftUI

enum AuraColors {
    // Backgrounds
    static let background = Color(red: 0.03, green: 0.05, blue: 0.03)
    static let cardBackground = Color(red: 0.05, green: 0.12, blue: 0.06).opacity(0.7)
    static let cardBorder = Color(red: 0.1, green: 0.9, blue: 0.3).opacity(0.18)

    // Primary neon green accent
    static let accent = Color(red: 0.05, green: 0.95, blue: 0.35)
    static let accentGlow = Color(red: 0.1, green: 1.0, blue: 0.45)
    static let accentDim = Color(red: 0.04, green: 0.7, blue: 0.25)

    // Cyberpunk secondary accent (teal/cyan)
    static let accentSecondary = Color(red: 0.0, green: 0.85, blue: 0.75)
    static let accentSecondaryGlow = Color(red: 0.0, green: 1.0, blue: 0.9)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textTertiary = Color.white.opacity(0.35)
    static let textAccent = Color(red: 0.05, green: 0.95, blue: 0.35)

    // Overlays & glass
    static let overlayDark = Color.black.opacity(0.75)
    static let glassFill = Color(red: 0.04, green: 0.1, blue: 0.05).opacity(0.8)

    // Semantic colors
    static let redChip = Color(red: 1.0, green: 0.2, blue: 0.25)           // danger/error
    static let greenPositive = Color(red: 0.05, green: 0.95, blue: 0.35)   // same as accent
    static let yellowWarning = Color(red: 0.9, green: 0.85, blue: 0.0)
    static let proGold = Color(red: 1.0, green: 0.85, blue: 0.2)

    // Gradients
    static let gradientBackground = LinearGradient(
        colors: [
            Color(red: 0.03, green: 0.06, blue: 0.03),
            Color(red: 0.01, green: 0.03, blue: 0.02)
        ],
        startPoint: .top, endPoint: .bottom
    )

    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.95, blue: 0.35),
            Color(red: 0.0, green: 0.75, blue: 0.55)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let neonGlowGradient = RadialGradient(
        colors: [
            Color(red: 0.05, green: 0.95, blue: 0.35).opacity(0.35),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 120
    )

    // Card scanline effect color
    static let scanline = Color(red: 0.1, green: 1.0, blue: 0.4).opacity(0.04)
}
