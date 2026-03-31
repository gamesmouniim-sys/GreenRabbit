import SwiftUI
import Combine

// MARK: - Sniper Zeroing Game
// A crosshair drifts with simulated wind. Tap the screen when the
// crosshair is centred on the target bullseye to score.
// Expert difficulty — 60-second round.

struct SniperZeroingGame: View {
    @ObservedObject var settings: AppSettings

    // MARK: - State
    @State private var reticleOffset: CGSize = .zero   // current drift position
    @State private var velocity: CGSize = CGSize(width: 1.2, height: 0.7)
    @State private var windAngle: Double = 0            // shifts slowly
    @State private var windStrength: Double = 1.0
    @State private var isFiring: Bool = false           // brief fire animation
    @State private var lastHitScore: Int? = nil
    @State private var shotResult: ShotResult = .none
    @State private var roundCount: Int = 0
    @State private var driftTimer: AnyCancellable?
    @State private var windTimer: AnyCancellable?

    enum ShotResult { case none, bullseye, inner, outer, miss }

    // Scoring zones (radius in pt from centre)
    private let bullseyeR: CGFloat = 14
    private let innerR   : CGFloat = 30
    private let outerR   : CGFloat = 52

    var body: some View {
        GeometryReader { geo in
            let centre = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // Dark tactical background
                Color(red: 0.02, green: 0.05, blue: 0.02).ignoresSafeArea()

                // Range markings
                rangeGrid(size: geo.size)

                // ── Target bullseye ──────────────────────────
                ZStack {
                    // Outer zone
                    Circle()
                        .stroke(AuraColors.textTertiary.opacity(0.25), lineWidth: 1)
                        .frame(width: outerR * 2, height: outerR * 2)
                    // Inner zone
                    Circle()
                        .stroke(AuraColors.yellowWarning.opacity(0.4), lineWidth: 1)
                        .frame(width: innerR * 2, height: innerR * 2)
                    // Bullseye
                    Circle()
                        .fill(AuraColors.redChip.opacity(0.8))
                        .frame(width: bullseyeR * 2, height: bullseyeR * 2)
                        .shadow(color: AuraColors.redChip.opacity(0.5), radius: 6)
                    // Centre dot
                    Circle()
                        .fill(.white)
                        .frame(width: 4, height: 4)
                }
                .position(centre)

                // ── Hit flash overlay ────────────────────────
                if isFiring {
                    shotResultOverlay
                        .position(centre)
                }

                // ── Sniper reticle ───────────────────────────
                SniperReticle(shotResult: shotResult)
                    .frame(width: 120, height: 120)
                    .position(
                        x: centre.x + reticleOffset.width,
                        y: centre.y + reticleOffset.height
                    )

                // ── Wind indicator ────────────────────────────
                VStack {
                    Spacer()
                    windIndicator
                        .padding(.bottom, 20)
                }

                // ── Round counter ─────────────────────────────
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("SHOTS FIRED")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundColor(AuraColors.textTertiary)
                                .tracking(1.5)
                            Text("\(roundCount)")
                                .font(.system(size: 24, weight: .black, design: .monospaced))
                                .foregroundColor(AuraColors.accent)
                                .shadow(color: AuraColors.accentGlow, radius: 6)
                                .contentTransition(.numericText())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                fireShot(geo: geo)
            }
            .onAppear  { startGame(geo: geo) }
            .onDisappear { stopGame() }
        }
        .ignoresSafeArea()
    }

    // MARK: - Subviews

    @ViewBuilder
    private var shotResultOverlay: some View {
        VStack(spacing: 4) {
            if let pts = lastHitScore {
                Text(shotResult == .miss ? "MISS" : "+\(pts)")
                    .font(.system(size: shotResult == .bullseye ? 28 : 20,
                                  weight: .black, design: .monospaced))
                    .foregroundColor(resultColor)
                    .shadow(color: resultColor.opacity(0.8), radius: 8)
                    .transition(.scale.combined(with: .opacity))

                if shotResult == .bullseye {
                    Text("BULLSEYE!")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(AuraColors.accent)
                        .tracking(2)
                }
            }
        }
        .offset(y: -80)
    }

    private var resultColor: Color {
        switch shotResult {
        case .bullseye: return AuraColors.accent
        case .inner:    return AuraColors.yellowWarning
        case .outer:    return AuraColors.textSecondary
        case .miss:     return AuraColors.redChip
        case .none:     return .clear
        }
    }

    private var windIndicator: some View {
        HStack(spacing: 10) {
            Text("WIND")
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)
                .tracking(2)

            // Wind arrow
            Image(systemName: "arrow.up")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AuraColors.accentSecondary)
                .rotationEffect(.degrees(windAngle))
                .shadow(color: AuraColors.accentSecondary.opacity(0.6), radius: 4)

            // Wind strength bar
            HStack(spacing: 2) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Double(i) < windStrength
                              ? AuraColors.accentSecondary
                              : AuraColors.textTertiary.opacity(0.2))
                        .frame(width: 8, height: 12 + CGFloat(i) * 2)
                }
            }

            Text(windLabel)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(AuraColors.accentSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AuraColors.cardBackground)
                .overlay(Capsule().stroke(AuraColors.cardBorder, lineWidth: 0.8))
        )
    }

    private var windLabel: String {
        switch windStrength {
        case ..<1.5: return "CALM"
        case ..<2.5: return "LIGHT"
        case ..<3.5: return "MODERATE"
        default:     return "STRONG"
        }
    }

    // MARK: - Tactical range grid
    private func rangeGrid(size: CGSize) -> some View {
        Canvas { ctx, sz in
            let col = Color(red: 0.05, green: 0.95, blue: 0.35).opacity(0.05)
            // Horizontal mil-dot lines
            for i in stride(from: 0, through: sz.height, by: 60) {
                var p = Path()
                p.move(to: .init(x: 0, y: i))
                p.addLine(to: .init(x: sz.width, y: i))
                ctx.stroke(p, with: .color(col), lineWidth: 0.5)
            }
            // Vertical mil-dot lines
            for i in stride(from: 0, through: sz.width, by: 60) {
                var p = Path()
                p.move(to: .init(x: i, y: 0))
                p.addLine(to: .init(x: i, y: sz.height))
                ctx.stroke(p, with: .color(col), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Game logic

    private func startGame(geo: GeometryProxy) {
        let maxDrift: CGFloat = min(geo.size.width, geo.size.height) * 0.32
        windStrength = Double.random(in: 0.5...2.5)
        windAngle    = Double.random(in: 0...360)

        // Smooth drift update at 30 fps
        driftTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard settings.currentSession.isActive else { return }
                updateDrift(maxDrift: maxDrift)
            }

        // Slowly shift wind every 4 seconds
        windTimer = Timer.publish(every: 4.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation(.easeInOut(duration: 2)) {
                    windAngle    = Double.random(in: 0...360)
                    windStrength = Double.random(in: 0.5...4.0)
                }
            }
    }

    private func updateDrift(maxDrift: CGFloat) {
        let speed: CGFloat = CGFloat(windStrength) * 0.6
        let windRad = windAngle * .pi / 180
        let windX: CGFloat = CGFloat(cos(windRad)) * speed * 0.4
        let windY: CGFloat = CGFloat(sin(windRad)) * speed * 0.4

        velocity.width  += CGFloat.random(in: -0.15...0.15) + windX * 0.05
        velocity.height += CGFloat.random(in: -0.15...0.15) + windY * 0.05

        // Clamp velocity
        velocity.width  = max(-speed, min(speed, velocity.width))
        velocity.height = max(-speed, min(speed, velocity.height))

        // Bounce off bounds
        let newX = reticleOffset.width  + velocity.width
        let newY = reticleOffset.height + velocity.height
        if abs(newX) > maxDrift { velocity.width  *= -0.7 }
        if abs(newY) > maxDrift { velocity.height *= -0.7 }

        reticleOffset.width  = max(-maxDrift, min(maxDrift, newX))
        reticleOffset.height = max(-maxDrift, min(maxDrift, newY))
    }

    private func fireShot(geo: GeometryProxy) {
        guard settings.currentSession.isActive, !isFiring else { return }

        let dist = sqrt(reticleOffset.width * reticleOffset.width +
                        reticleOffset.height * reticleOffset.height)

        var pts = 0
        var result: ShotResult = .miss

        if dist <= bullseyeR {
            result = .bullseye; pts = 300
            settings.currentSession.headshots += 1
        } else if dist <= innerR {
            result = .inner; pts = 180
            settings.currentSession.hits += 1
        } else if dist <= outerR {
            result = .outer; pts = 80
            settings.currentSession.hits += 1
        } else {
            result = .miss; pts = -30
            settings.currentSession.misses += 1
        }

        let combo = result == .miss ? 0 : settings.currentSession.combo + 1
        settings.currentSession.combo    = combo
        settings.currentSession.maxCombo = max(settings.currentSession.maxCombo, combo)
        settings.currentSession.score    = max(0, settings.currentSession.score + pts + combo * 20)
        roundCount += 1
        lastHitScore = abs(pts)
        shotResult   = result

        UIImpactFeedbackGenerator(style: result == .bullseye ? .heavy : .medium).impactOccurred()

        withAnimation(.spring(response: 0.15)) { isFiring = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation { isFiring = false; shotResult = .none }
        }
    }

    private func stopGame() {
        driftTimer?.cancel()
        windTimer?.cancel()
    }
}

// MARK: - Sniper Reticle View
private struct SniperReticle: View {
    let shotResult: SniperZeroingGame.ShotResult

    var body: some View {
        ZStack {
            let c = AuraColors.accent
            // Cross hairs
            Rectangle()
                .fill(c.opacity(0.85))
                .frame(width: 120, height: 1)
            Rectangle()
                .fill(c.opacity(0.85))
                .frame(width: 1, height: 120)
            // Gap at centre
            Rectangle()
                .fill(Color(red: 0.02, green: 0.05, blue: 0.02))
                .frame(width: 20, height: 20)
            // Mil-dot circles
            ForEach([CGFloat(20), 40, 55], id: \.self) { r in
                Circle()
                    .stroke(c.opacity(0.3), lineWidth: 0.6)
                    .frame(width: r, height: r)
            }
            // Centre dot
            Circle()
                .fill(c)
                .frame(width: 5, height: 5)
                .shadow(color: AuraColors.accentGlow, radius: 4)
            // Corner brackets
            ForEach([(CGFloat(-1),CGFloat(-1)), (1,-1), (-1,1), (1,1)], id: \.0) { sx, sy in
                Path { p in
                    let ox: CGFloat = sx * 48; let oy: CGFloat = sy * 48
                    p.move(to: .init(x: ox, y: oy + sy * 10))
                    p.addLine(to: .init(x: ox, y: oy))
                    p.addLine(to: .init(x: ox + sx * 10, y: oy))
                }
                .stroke(c.opacity(0.7), lineWidth: 1.5)
            }
        }
        .shadow(color: shotResult == .bullseye ? AuraColors.accentGlow : .clear, radius: 12)
    }
}
