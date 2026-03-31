import SwiftUI

struct AuraPowerButton: View {
    let isActive: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow rings
                if isActive {
                    Circle()
                        .stroke(AuraColors.accentGlow.opacity(0.15), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)

                    Circle()
                        .stroke(AuraColors.accentGlow.opacity(0.08), lineWidth: 1.5)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale * 0.97)
                }

                // Base circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isActive
                                ? [AuraColors.accent, AuraColors.accent.opacity(0.6), Color.black]
                                : [Color(white: 0.15), Color(white: 0.08), Color.black],
                            center: .center,
                            startRadius: 5,
                            endRadius: 60
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: isActive ? AuraColors.accentGlow.opacity(0.6) : .clear, radius: 20)

                // Border ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: isActive
                                ? [AuraColors.accent, AuraColors.accentGlow, AuraColors.accent]
                                : [Color.white.opacity(0.15), Color.white.opacity(0.05), Color.white.opacity(0.15)],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(rotation))

                // Power icon
                Image(systemName: "power")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(isActive ? .white : AuraColors.textSecondary)
                    .shadow(color: isActive ? AuraColors.accentGlow.opacity(0.8) : .clear, radius: 8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isActive ? "Deactivate training mode" : "Activate training mode")
        .onAppear {
            if isActive { startAnimations() }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue { startAnimations() } else { stopAnimations() }
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }

    private func stopAnimations() {
        withAnimation(.easeOut(duration: 0.4)) {
            pulseScale = 1.0
            rotation = 0
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            AuraPowerButton(isActive: false, action: {})
            AuraPowerButton(isActive: true, action: {})
        }
    }
}
