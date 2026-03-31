import SwiftUI

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 18
    var borderOpacity: Double = 0.18
    var accentBorder: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AuraColors.glassFill)
                    .overlay(
                        // Subtle scanline pattern for cyberpunk feel
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(AuraColors.scanline)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        accentBorder
                            ? AuraColors.accent.opacity(borderOpacity)
                            : AuraColors.cardBorder,
                        lineWidth: accentBorder ? 1.2 : 0.8
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// Neon glow border modifier
struct NeonBorderModifier: ViewModifier {
    var cornerRadius: CGFloat = 18
    var color: Color = AuraColors.accent
    var intensity: Double = 0.7

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color.opacity(intensity), lineWidth: 1)
                    .shadow(color: color.opacity(0.5), radius: 6)
            )
    }
}

extension View {
    func auraGlass(cornerRadius: CGFloat = 18, borderOpacity: Double = 0.18, accentBorder: Bool = false) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, borderOpacity: borderOpacity, accentBorder: accentBorder))
    }

    func neonBorder(cornerRadius: CGFloat = 18, color: Color = AuraColors.accent, intensity: Double = 0.7) -> some View {
        modifier(NeonBorderModifier(cornerRadius: cornerRadius, color: color, intensity: intensity))
    }
}
