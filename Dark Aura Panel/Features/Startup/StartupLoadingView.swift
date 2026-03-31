import SwiftUI

struct StartupLoadingView: View {
    let isRetryState: Bool
    let isRetrying: Bool
    let onRetry: () -> Void

    // Orbit
    @State private var orbit1:    Double  = 0
    @State private var orbit2:    Double  = 180
    // Glow rings
    @State private var ringPulse: Bool    = false
    // Icon entrance
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOp:    Double  = 0
    // Segment loader
    @State private var litSegs:   Int     = 0
    // Text
    @State private var textVis:   Bool    = false

    private let totalSegs = 10

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.03, blue: 0.02).ignoresSafeArea()
            hexCanvas
            bottomGlow

            VStack(spacing: 0) {
                Spacer()

                // ── Central icon cluster ──────────────────────────
                ZStack {
                    // Pulsing halos (3 concentric rings)
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                AuraColors.accent.opacity(ringPulse
                                    ? 0.18 - Double(i) * 0.05
                                    : 0.04),
                                lineWidth: 0.8
                            )
                            .frame(width: CGFloat(124 + i * 36),
                                   height: CGFloat(124 + i * 36))
                            .scaleEffect(ringPulse ? 1.05 : 1.0)
                            .animation(
                                .easeInOut(duration: 2.0 + Double(i) * 0.4)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.25),
                                value: ringPulse
                            )
                    }

                    // Dashed orbit track
                    Circle()
                        .stroke(
                            AuraColors.accent.opacity(0.09),
                            style: StrokeStyle(lineWidth: 0.8, dash: [4, 8])
                        )
                        .frame(width: 156, height: 156)

                    // Orbit bead 1 — fast, primary accent
                    orbitBead(color: AuraColors.accent,
                              glowColor: AuraColors.accentGlow,
                              size: 9, radius: 78)
                        .rotationEffect(.degrees(orbit1))

                    // Orbit bead 2 — slow, secondary accent
                    orbitBead(color: AuraColors.accentSecondary,
                              glowColor: AuraColors.accentSecondary.opacity(0.6),
                              size: 5, radius: 78)
                        .rotationEffect(.degrees(orbit2))

                    // App icon
                    appIcon
                        .frame(width: 110, height: 110)
                        .scaleEffect(iconScale)
                        .opacity(iconOp)
                        .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 24)
                }

                Spacer().frame(height: 42)

                // ── Labels ───────────────────────────────────────
                VStack(spacing: 6) {
                    Text("DARK AURA RABBIT")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(AuraColors.accent)
                        .tracking(5)
                        .shadow(color: AuraColors.accentGlow.opacity(0.8), radius: 6)

                    if isRetryState {
                        Text("Connection required to download panel settings.")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(AuraColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else {
                        Text("Loading Dark Aura Rabbit Settings...")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(AuraColors.textTertiary)
                            .tracking(0.2)
                    }
                }
                .opacity(textVis ? 1 : 0)
                .offset(y: textVis ? 0 : 10)
                .animation(.easeOut(duration: 0.55).delay(0.4), value: textVis)

                Spacer().frame(height: 30)

                // ── Loading indicator or retry ────────────────────
                if isRetryState {
                    retrySection
                } else {
                    segmentLoader
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
        .onAppear { boot() }
    }

    // MARK: – Orbit bead
    private func orbitBead(color: Color, glowColor: Color,
                           size: CGFloat, radius: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: glowColor.opacity(0.9), radius: size * 1.4)
            .offset(y: -radius)
    }

    // MARK: – App icon
    private var appIcon: some View {
        Group {
            if let img = Self.loadAppIcon() {
                Image(uiImage: img).resizable().scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(AuraColors.accent.opacity(0.14))
                    Image(systemName: "hare.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(AuraColors.accent)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AuraColors.accent.opacity(0.3), lineWidth: 1)
        )
    }

    /// Loads the actual compiled app icon from the bundle, with named-image fallbacks.
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

    // MARK: – Segment loading bar
    private var segmentLoader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                ForEach(0..<totalSegs, id: \.self) { i in
                    Capsule()
                        .fill(i < litSegs
                              ? AuraColors.accent
                              : AuraColors.accent.opacity(0.10))
                        .frame(width: 22, height: 5)
                        .shadow(color: i < litSegs
                                ? AuraColors.accentGlow.opacity(0.85)
                                : .clear, radius: 3)
                        .animation(
                            .spring(response: 0.2, dampingFraction: 0.7)
                                .delay(Double(i) * 0.03),
                            value: litSegs
                        )
                }
            }
            Text(litSegs < totalSegs
                 ? "\(litSegs * 10)%"
                 : "READY")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)
        }
    }

    // MARK: – Retry section
    private var retrySection: some View {
        Group {
            if isRetrying {
                ProgressView()
                    .controlSize(.regular)
                    .tint(AuraColors.accent)
            } else {
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .bold))
                        Text("Reload Connection")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(AuraColors.accentGradient)
                            .shadow(color: AuraColors.accentGlow.opacity(0.5), radius: 10)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: – Hex background
    private var hexCanvas: some View {
        Canvas { ctx, size in
            let r: CGFloat  = 22
            let col = Color(red: 0.05, green: 0.95, blue: 0.35).opacity(0.04)
            let cols = Int(size.width  / (r * 1.73)) + 2
            let rows = Int(size.height / (r * 1.50)) + 2
            for row in 0...rows {
                for c in 0...cols {
                    let cx = CGFloat(c) * r * 1.73 + (row % 2 == 0 ? 0 : r * 0.865)
                    let cy = CGFloat(row) * r * 1.50
                    var p = Path()
                    for i in 0..<6 {
                        let ang = CGFloat(i) * .pi / 3 - .pi / 6
                        let pt  = CGPoint(x: cx + (r - 1) * cos(ang),
                                          y: cy + (r - 1) * sin(ang))
                        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                    }
                    p.closeSubpath()
                    ctx.stroke(p, with: .color(col), lineWidth: 0.5)
                }
            }
        }
        .ignoresSafeArea()
    }

    private var bottomGlow: some View {
        VStack {
            Spacer()
            RadialGradient(
                colors: [AuraColors.accent.opacity(0.12), .clear],
                center: .center, startRadius: 10, endRadius: 200
            )
            .frame(height: 200)
        }
        .ignoresSafeArea()
    }

    // MARK: – Boot sequence
    private func boot() {
        textVis   = true
        ringPulse = true

        // Icon entrance
        withAnimation(.spring(response: 0.7, dampingFraction: 0.58).delay(0.12)) {
            iconScale = 1.0
            iconOp    = 1.0
        }
        // Orbit — primary fast
        withAnimation(.linear(duration: 3.4).repeatForever(autoreverses: false)) {
            orbit1 = 360
        }
        // Orbit — secondary slow, already offset by 180°
        withAnimation(.linear(duration: 5.8).repeatForever(autoreverses: false)) {
            orbit2 = 360 + 180
        }

        // Segment fill (only during normal loading)
        guard !isRetryState else { return }
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            for i in 1...totalSegs {
                try? await Task.sleep(nanoseconds: 210_000_000)
                litSegs = i
            }
        }
    }
}
