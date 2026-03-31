import SwiftUI

// MARK: – Splash Page  (Aurora / Deep-Space aesthetic)
// Completely different from the previous grid + floating icon design.
// – Animated star field + dual aurora gradients
// – App icon with segmented hex ring that snaps in
// – "DARK AURA" title slides in from both sides and merges
// – "GET STARTED" power-style button rises from the bottom

struct OnboardingSplashPage: View {
    let onNext: () -> Void

    // Stars
    @State private var starOp:       Double  = 0
    // Icon
    @State private var iconScale:    CGFloat = 0.0
    @State private var iconOp:       Double  = 0
    @State private var iconGlow:     Bool    = false
    // Hex ring segments (6 arcs)
    @State private var ringSegOp:    Double  = 0
    // Title – each half slides in from a side
    @State private var leftX:        CGFloat = -50
    @State private var rightX:       CGFloat =  50
    @State private var titleOp:      Double  = 0
    // Tag + edition line
    @State private var tagOp:        Double  = 0
    // Button
    @State private var buttonVis:    Bool    = false

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.03, blue: 0.03).ignoresSafeArea()
            starField
            aurora

            VStack(spacing: 0) {
                Spacer()

                // ── Icon + ring cluster ──────────────────────────
                ZStack {
                    // Glow blob
                    Circle()
                        .fill(RadialGradient(
                            colors: [AuraColors.accent.opacity(iconGlow ? 0.22 : 0.07), .clear],
                            center: .center, startRadius: 0, endRadius: 70
                        ))
                        .frame(width: 140, height: 140)

                    // 6-segment hex ring
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .trim(from: CGFloat(i) / 6.0 + 0.012,
                                  to:   CGFloat(i + 1) / 6.0 - 0.012)
                            .stroke(
                                AuraColors.accent.opacity(0.55),
                                style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                            )
                            .frame(width: 130, height: 130)
                            .rotationEffect(.degrees(-90))
                            .opacity(ringSegOp)
                            .scaleEffect(ringSegOp > 0 ? 1 : 0.8)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.6)
                                    .delay(0.25 + Double(i) * 0.06),
                                value: ringSegOp
                            )
                    }

                    // Second thin ring
                    Circle()
                        .stroke(AuraColors.accentSecondary.opacity(0.18),
                                style: StrokeStyle(lineWidth: 0.8, dash: [3, 9]))
                        .frame(width: 148, height: 148)
                        .opacity(ringSegOp)

                    // App icon
                    appIcon
                        .frame(width: 100, height: 100)
                        .scaleEffect(iconScale)
                        .opacity(iconOp)
                        .shadow(color: AuraColors.accentGlow.opacity(0.65), radius: 18)

                    // Corner bracket accents (4 corners of a virtual square)
                    ForEach(0..<4, id: \.self) { i in
                        cornerBracket
                            .rotationEffect(.degrees(Double(i) * 90))
                            .frame(width: 130, height: 130)
                            .opacity(ringSegOp * 0.6)
                    }
                }
                .frame(width: 180, height: 180)

                Spacer().frame(height: 34)

                // ── Title: "DARK AURA" slides in from both sides ──
                VStack(alignment: .center, spacing: 3) {
                    HStack(spacing: 0) {
                        Text("DARK")
                            .font(.system(size: 40, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .offset(x: leftX)
                        Text(" AURA")
                            .font(.system(size: 40, weight: .black, design: .monospaced))
                            .foregroundStyle(AuraColors.accentGradient)
                            .offset(x: rightX)
                    }
                    .opacity(titleOp)
                    .shadow(color: AuraColors.accentGlow.opacity(0.25), radius: 10)

                    Text("P  A  N  E  L")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(AuraColors.textSecondary)
                        .tracking(3)
                        .opacity(titleOp)
                }

                Spacer().frame(height: 14)

                // ── Tagline ───────────────────────────────────────
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(AuraColors.accent.opacity(0.45))
                        .frame(width: 28, height: 0.8)
                    ForEach(["AIM", "·", "TRAIN", "·", "DOMINATE"], id: \.self) { w in
                        Text(w)
                            .font(.system(size: 9, weight: w == "·" ? .regular : .bold,
                                          design: .monospaced))
                            .foregroundColor(w == "·"
                                             ? AuraColors.accent
                                             : AuraColors.textTertiary)
                    }
                    Rectangle()
                        .fill(AuraColors.accent.opacity(0.45))
                        .frame(width: 28, height: 0.8)
                }
                .opacity(tagOp)

                Spacer().frame(height: 58)

                // ── Power-style launch button ─────────────────────
                if buttonVis {
                    launchButton
                        .padding(.horizontal, 28)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { runSequence() }
    }

    // MARK: – Launch button
    private var launchButton: some View {
        Button(action: onNext) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(
                        colors: [AuraColors.accent, AuraColors.accent.opacity(0.72)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.14), .clear],
                        startPoint: .top, endPoint: .center
                    ))
                    .padding(1)

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "power")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                    }

                    Text("GET STARTED")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                        .tracking(2)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                }
                .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
        }
        .buttonStyle(.plain)
        .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 22)
    }

    // MARK: – App icon
    private var appIcon: some View {
        Group {
            if let img = Self.loadAppIcon() {
                Image(uiImage: img).resizable().scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AuraColors.accent.opacity(0.15))
                    Image(systemName: "hare.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(AuraColors.accent)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AuraColors.accent.opacity(0.45), lineWidth: 1.5)
        )
    }

    /// Loads the compiled app icon from the bundle, with named-image fallbacks.
    private static func loadAppIcon() -> UIImage? {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let lastName = files.last,
           let img = UIImage(named: lastName) {
            return img
        }
        return UIImage(named: "AppIcon") ?? UIImage(named: "RabbitIcon")
    }

    // MARK: – Corner bracket accent
    private var cornerBracket: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                p.move(to: CGPoint(x: w - 12, y: 0))
                p.addLine(to: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: w, y: 12))
            }
            .stroke(AuraColors.accent.opacity(0.55),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
    }

    // MARK: – Background: aurora
    private var aurora: some View {
        ZStack {
            RadialGradient(
                colors: [AuraColors.accent.opacity(0.11), .clear],
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 60, endRadius: 380
            )
            RadialGradient(
                colors: [AuraColors.accentSecondary.opacity(0.06), .clear],
                center: UnitPoint(x: 0.18, y: 0.72),
                startRadius: 30, endRadius: 260
            )
            RadialGradient(
                colors: [AuraColors.accentSecondary.opacity(0.04), .clear],
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 20, endRadius: 220
            )
        }
        .ignoresSafeArea()
    }

    // MARK: – Background: stars
    private var starField: some View {
        Canvas { ctx, size in
            for i in 0..<70 {
                let x = CGFloat((i * 137 + 13) % Int(size.width))
                let y = CGFloat((i * 89  + 27) % Int(size.height))
                let r: CGFloat = i % 6 == 0 ? 1.4 : i % 3 == 0 ? 0.9 : 0.55
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2,
                                           width: r, height: r)),
                    with: .color(.white.opacity(starOp * (i % 4 == 0 ? 0.55 : 0.22)))
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: – Entry sequence
    private func runSequence() {
        // Stars fade in
        withAnimation(.easeIn(duration: 0.9)) { starOp = 1 }

        // Icon assembles
        withAnimation(.spring(response: 0.62, dampingFraction: 0.52).delay(0.15)) {
            iconScale = 1.0; iconOp = 1.0
        }
        withAnimation(.easeInOut(duration: 0.01).delay(0.28)) { ringSegOp = 1 }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.7)) {
            iconGlow = true
        }

        // Title slides in
        withAnimation(.spring(response: 0.58, dampingFraction: 0.72).delay(0.55)) {
            leftX = 0; rightX = 0; titleOp = 1
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.82)) { tagOp = 1 }

        // Button rises
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.68)) {
                buttonVis = true
            }
        }
    }
}
