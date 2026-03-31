import SwiftUI

struct AuraFloatingMenuButton: View {
    let isExpanded: Bool
    let action: () -> Void
    @EnvironmentObject private var ads: AdsService

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                action()
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            ads.registerInteraction(for: .uiInteraction)
        }) {
            ZStack {
                // Glass backing
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().fill(Color.black.opacity(0.45)))
                    .overlay(Circle().stroke(AuraColors.accent.opacity(0.5), lineWidth: 1.2))
                    .frame(width: 58, height: 58)
                    .shadow(color: AuraColors.accentGlow.opacity(0.35), radius: 12)

                if isExpanded {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AuraColors.accent)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Custom float icon from Assets
                    Image("floaticon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isExpanded)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "Close settings menu" : "Open settings menu")
    }
}
