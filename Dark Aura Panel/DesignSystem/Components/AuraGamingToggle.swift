import SwiftUI

struct AuraGamingToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isOn.toggle()
            }
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
        } label: {
            Capsule()
                .fill(isOn ? AuraColors.accent : Color.white.opacity(0.1))
                .frame(width: 48, height: 28)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .shadow(color: isOn ? AuraColors.accentGlow.opacity(0.5) : .clear, radius: 4)
                        .offset(x: isOn ? 10 : -10)
                )
                .overlay(
                    Capsule()
                        .stroke(isOn ? AuraColors.accentGlow.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Enabled" : "Disabled")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AuraGamingToggle(isOn: .constant(true))
    }
}
