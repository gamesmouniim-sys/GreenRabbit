import SwiftUI

// MARK: – Language Page  (Glassmorphism Constellation Cards)
// Completely different from previous terminal/circuit-trace design.
// – Deep space background with star particles + two aurora orb blobs
// – Animated "CHOOSE YOUR LANGUAGE" title with globe pulse
// – 2×2 grid of frosted glass cards: big flag + name + glow on select
// – Animated "CONTINUE" button with gradient fill

struct OnboardingLanguagePage: View {
    @EnvironmentObject var lm: LocalizationManager
    let onNext: () -> Void

    @State private var titleVisible  = false
    @State private var cardsVisible  = false
    @State private var buttonVisible = false
    @State private var globePulse    = false

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────
            Color(red: 0.03, green: 0.04, blue: 0.06).ignoresSafeArea()
            starField
            auroraBlobs

            VStack(spacing: 0) {
                // ── Title block ─────────────────────────────────────
                VStack(spacing: 10) {
                    // Globe icon with pulse ring
                    ZStack {
                        Circle()
                            .stroke(AuraColors.accent.opacity(globePulse ? 0.0 : 0.45),
                                    lineWidth: 1.5)
                            .frame(width: globePulse ? 72 : 48, height: globePulse ? 72 : 48)
                            .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false),
                                       value: globePulse)
                        Circle()
                            .fill(AuraColors.accent.opacity(0.12))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "globe.americas.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(AuraColors.accent)
                                    .shadow(color: AuraColors.accentGlow, radius: 8)
                            )
                    }
                    .padding(.top, 54)

                    Text("CHOOSE YOUR")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(AuraColors.textTertiary)
                        .tracking(4)

                    Text("LANGUAGE")
                        .font(.system(size: 30, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(4)
                        .shadow(color: AuraColors.accent.opacity(0.3), radius: 10)

                    // Decorative divider
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, AuraColors.accent.opacity(0.5)],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(height: 1)
                        Circle()
                            .fill(AuraColors.accent)
                            .frame(width: 4, height: 4)
                            .shadow(color: AuraColors.accentGlow, radius: 4)
                        Rectangle()
                            .fill(LinearGradient(colors: [AuraColors.accent.opacity(0.5), .clear],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 48)
                    .padding(.top, 4)
                }
                .opacity(titleVisible ? 1 : 0)
                .offset(y: titleVisible ? 0 : -18)
                .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1),
                           value: titleVisible)

                // ── Language card grid ──────────────────────────────
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { idx, lang in
                        languageCard(lang, idx: idx)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .opacity(cardsVisible ? 1 : 0)
                .scaleEffect(cardsVisible ? 1 : 0.92)
                .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.3),
                           value: cardsVisible)

                Spacer(minLength: 20)

                // ── Continue button ─────────────────────────────────
                if buttonVisible {
                    continueButton
                        .padding(.horizontal, 28)
                        .padding(.bottom, 50)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear { runSequence() }
    }

    // MARK: – Language card
    @ViewBuilder
    private func languageCard(_ lang: AppLanguage, idx: Int) -> some View {
        let sel = lm.language == lang
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                lm.language = lang
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack(alignment: .topTrailing) {
                // Card body
                VStack(spacing: 10) {
                    // Flag in a circle frame
                    ZStack {
                        Circle()
                            .fill(sel
                                  ? AuraColors.accent.opacity(0.18)
                                  : Color.white.opacity(0.06))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Circle()
                                    .stroke(sel
                                            ? AuraColors.accent.opacity(0.6)
                                            : Color.white.opacity(0.08),
                                            lineWidth: sel ? 1.5 : 0.8)
                            )
                            .shadow(color: sel ? AuraColors.accentGlow.opacity(0.4) : .clear,
                                    radius: 12)
                        Text(lang.flag)
                            .font(.system(size: 32))
                    }
                    .scaleEffect(sel ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: sel)

                    VStack(spacing: 3) {
                        Text(lang.nativeName)
                            .font(.system(size: 14, weight: sel ? .bold : .medium))
                            .foregroundColor(sel ? .white : AuraColors.textSecondary)
                            .multilineTextAlignment(.center)
                        Text(lang.rawValue.uppercased())
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                            .foregroundColor(sel ? AuraColors.accent : AuraColors.textTertiary)
                            .tracking(2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    ZStack {
                        // Frosted glass base
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(sel
                                  ? AuraColors.accent.opacity(0.07)
                                  : Color.white.opacity(0.04))
                        // Glass sheen
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(sel ? 0.10 : 0.05), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .padding(1)
                        // Border
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(sel
                                    ? AuraColors.accent.opacity(0.55)
                                    : Color.white.opacity(0.08),
                                    lineWidth: sel ? 1.4 : 0.7)
                    }
                )
                .shadow(color: sel ? AuraColors.accentGlow.opacity(0.2) : Color.black.opacity(0.3),
                        radius: sel ? 16 : 6)

                // Checkmark badge when selected
                if sel {
                    ZStack {
                        Circle()
                            .fill(AuraColors.accent)
                            .frame(width: 22, height: 22)
                            .shadow(color: AuraColors.accentGlow.opacity(0.8), radius: 6)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.black)
                    }
                    .padding(10)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: sel)
    }

    // MARK: – Continue button
    private var continueButton: some View {
        Button(action: onNext) {
            HStack(spacing: 12) {
                Text("CONTINUE")
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                    .tracking(2)
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AuraColors.accentGradient)
                    // Top gloss
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.white.opacity(0.18), .clear],
                            startPoint: .top, endPoint: .center
                        ))
                        .padding(1)
                }
            )
            .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 18)
        }
        .buttonStyle(.plain)
    }

    // MARK: – Star field background
    private var starField: some View {
        Canvas { ctx, size in
            let rng = SystemRandomNumberGenerator()
            var gen = rng
            for _ in 0..<90 {
                let x = CGFloat.random(in: 0...size.width, using: &gen)
                let y = CGFloat.random(in: 0...size.height, using: &gen)
                let r = CGFloat.random(in: 0.5...1.8, using: &gen)
                let op = Double.random(in: 0.15...0.6, using: &gen)
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r,
                                               width: r * 2, height: r * 2)),
                         with: .color(Color.white.opacity(op)))
            }
        }
        .ignoresSafeArea()
    }

    // MARK: – Aurora orb blobs
    private var auroraBlobs: some View {
        ZStack {
            RadialGradient(
                colors: [AuraColors.accent.opacity(0.18), .clear],
                center: .topLeading, startRadius: 20, endRadius: 340
            )
            RadialGradient(
                colors: [Color(red: 0.0, green: 0.4, blue: 0.9).opacity(0.10), .clear],
                center: .bottomTrailing, startRadius: 20, endRadius: 380
            )
        }
        .ignoresSafeArea()
    }

    // MARK: – Entry sequence
    private func runSequence() {
        globePulse = true
        withAnimation(.easeOut(duration: 0.5).delay(0.05)) { titleVisible  = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.25)) { cardsVisible  = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
                buttonVisible = true
            }
        }
    }
}
