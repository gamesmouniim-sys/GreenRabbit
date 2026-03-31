import SwiftUI

// MARK: - AuraPremiumButton
// Animated gold PRO button: shimmer sweep + pulsing glow border.
// Drop it anywhere — it manages its own animation state.
struct AuraPremiumButton: View {
    let action: () -> Void
    @State private var pulse:   Bool    = false
    @State private var shimmer: CGFloat = -0.6

    private let gold1 = Color(red: 1.00, green: 0.80, blue: 0.10)
    private let gold2 = Color(red: 0.95, green: 0.52, blue: 0.02)

    var body: some View {
        Button(action: action) {
            ZStack {
                // Gold gradient base
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [gold1, gold2],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing))

                // Shimmer sweep
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.40), .clear],
                            startPoint: UnitPoint(x: shimmer, y: 0),
                            endPoint:   UnitPoint(x: shimmer + 0.55, y: 1)
                        )
                    )
                    .blendMode(.plusLighter)

                // Pulsing outer border
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(gold1.opacity(pulse ? 1.0 : 0.25), lineWidth: 1.0)
                    .shadow(color: gold1.opacity(pulse ? 0.9 : 0.15), radius: pulse ? 10 : 3)

                // Content
                HStack(spacing: 7) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.22))
                            .frame(width: 24, height: 24)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: gold1.opacity(0.8), radius: 4)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("UNLOCK")
                            .font(.system(size: 6, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.black.opacity(0.55))
                            .tracking(2)
                        Text("PRO")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .tracking(3)
                    }
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(Color.black.opacity(0.45))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
            }
            .fixedSize()
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false).delay(0.3)) {
                shimmer = 1.4
            }
        }
    }
}
