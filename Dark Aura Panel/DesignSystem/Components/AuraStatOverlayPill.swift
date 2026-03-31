import SwiftUI

struct AuraStatOverlayPill: View {
    let label: String
    let value: String
    var color: Color = AuraColors.accent

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)
            Text(value)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Color.black.opacity(0.5)))
        )
        .overlay(
            Capsule().stroke(color.opacity(0.25), lineWidth: 0.8)
        )
    }
}
