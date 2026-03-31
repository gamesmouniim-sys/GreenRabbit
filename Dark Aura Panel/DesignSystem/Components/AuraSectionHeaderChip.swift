import SwiftUI

struct AuraSectionHeaderChip: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            // Left accent line
            Rectangle()
                .fill(AuraColors.accentGradient)
                .frame(width: 3, height: 14)
                .shadow(color: AuraColors.accentGlow.opacity(0.8), radius: 4)

            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(1.8)
                .foregroundColor(AuraColors.accent)
                .shadow(color: AuraColors.accentGlow.opacity(0.5), radius: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AuraSectionHeaderChip(title: "Sensi Setup")
    }
}
