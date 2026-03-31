import SwiftUI

struct AuraResultBanner: View {
    let isWin: Bool
    let score: Int
    let accuracy: Double
    let headshots: Int
    let onRetry: () -> Void
    let onExit: () -> Void

    @State private var appear      = false
    @State private var glowPulse   = false
    @State private var scanOffset: CGFloat = -300

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.92).ignoresSafeArea()
                .opacity(appear ? 1 : 0)

            // Neon radial glow behind card
            if isWin {
                RadialGradient(
                    colors: [AuraColors.accent.opacity(0.18), .clear],
                    center: .center, startRadius: 0, endRadius: 280
                )
                .ignoresSafeArea()
                .scaleEffect(glowPulse ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowPulse)
            }

            VStack(spacing: 0) {
                // ── Result title ─────────────────────────────
                VStack(spacing: 8) {
                    Text(isWin ? "VICTORY" : "DEFEATED")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundStyle(
                            isWin
                                ? LinearGradient(
                                    colors: [AuraColors.accent, AuraColors.accentSecondary],
                                    startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.6), Color.white.opacity(0.3)],
                                    startPoint: .leading, endPoint: .trailing)
                        )
                        .shadow(color: isWin ? AuraColors.accentGlow.opacity(0.8) : .clear, radius: 20)
                        .tracking(4)
                        .scaleEffect(appear ? 1 : 0.5)

                    // Decorative line
                    HStack(spacing: 0) {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, isWin ? AuraColors.accent : AuraColors.textTertiary, .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                        .frame(height: 1)
                        .frame(maxWidth: 200)
                        .shadow(color: isWin ? AuraColors.accentGlow : .clear, radius: 4)
                        Spacer()
                    }

                    Text(isWin ? "ROUND COMPLETE" : "BETTER LUCK NEXT TIME")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(isWin ? AuraColors.textAccent : AuraColors.textTertiary)
                        .tracking(2.5)
                }
                .padding(.bottom, 28)

                // ── Stats panel ───────────────────────────────
                VStack(spacing: 1) {
                    HStack(spacing: 0) {
                        statItem(icon: "trophy.fill",        label: "SCORE",     value: "\(score)",         color: AuraColors.accent)
                        divider
                        statItem(icon: "scope",              label: "ACCURACY",  value: "\(Int(accuracy))%", color: AuraColors.yellowWarning)
                        divider
                        statItem(icon: "person.fill.viewfinder", label: "HS",   value: "\(headshots)",      color: AuraColors.redChip)
                    }
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AuraColors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        isWin ? AuraColors.accent.opacity(0.3) : AuraColors.cardBorder,
                                        lineWidth: isWin ? 1.2 : 0.8
                                    )
                            )
                            .shadow(color: isWin ? AuraColors.accentGlow.opacity(0.15) : .clear, radius: 12)
                    )
                    // Animated scan line on win
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        isWin ? AnyView(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, AuraColors.accent.opacity(0.12), .clear],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .frame(height: 40)
                                .offset(y: scanOffset)
                                .clipped()
                        ) : AnyView(EmptyView())
                    )
                }

                Spacer().frame(height: 28)

                // ── Action buttons ────────────────────────────
                HStack(spacing: 14) {
                    Button(action: onExit) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                            Text("EXIT")
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                .tracking(1.5)
                        }
                        .foregroundColor(AuraColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AuraColors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(AuraColors.cardBorder, lineWidth: 0.8)
                                )
                        )
                    }

                    Button(action: onRetry) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .bold))
                            Text("RETRY")
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                .tracking(1.5)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AuraColors.accentGradient)
                                .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 12)
                        )
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 36)
            .offset(y: appear ? 0 : 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) { appear = true }
            UINotificationFeedbackGenerator().notificationOccurred(isWin ? .success : .error)
            if isWin {
                glowPulse = true
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    scanOffset = 300
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(AuraColors.cardBorder)
            .frame(width: 1, height: 44)
    }

    private func statItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.6), radius: 4)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
    }
}
