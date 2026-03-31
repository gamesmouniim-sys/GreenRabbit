import SwiftUI
import Combine

// MARK: - Dodge & Shoot Game
// A moving green target bounces around. Red danger zones also drift.
// Tap the green target for points; avoid tapping the red danger zones.
// 35-second round, Hard difficulty.

struct DodgeShootGame: View {
    @ObservedObject var settings: AppSettings

    // MARK: - Models
    private struct ShootTarget {
        var pos: CGPoint
        var vel: CGSize
        let size: CGFloat = 36
    }

    private struct DangerZone: Identifiable {
        let id = UUID()
        var pos: CGPoint
        var vel: CGSize
        let size: CGFloat
    }

    // MARK: - State
    @State private var target       = ShootTarget(pos: CGPoint(x: 180, y: 300), vel: CGSize(width: 2.2, height: 1.6))
    @State private var dangers      : [DangerZone] = []
    @State private var hitFlash     = false
    @State private var dangerHit    = false
    @State private var scorePopup   : (text: String, pos: CGPoint)? = nil
    @State private var physicsTimer : AnyCancellable?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color(red: 0.02, green: 0.04, blue: 0.02).ignoresSafeArea()
                scanlineCanvas(size: geo.size)

                // ── Danger zones ──────────────────────────────
                ForEach(dangers) { zone in
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AuraColors.redChip.opacity(0.55), AuraColors.redChip.opacity(0.1)],
                                    center: .center, startRadius: 0, endRadius: zone.size
                                )
                            )
                            .frame(width: zone.size * 2, height: zone.size * 2)
                        Circle()
                            .stroke(AuraColors.redChip.opacity(0.6), lineWidth: 1.5)
                            .frame(width: zone.size * 2, height: zone.size * 2)
                            .shadow(color: AuraColors.redChip.opacity(0.5), radius: 6)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: zone.size * 0.55, weight: .bold))
                            .foregroundColor(AuraColors.redChip.opacity(0.85))
                    }
                    .position(zone.pos)
                    .onTapGesture {
                        handleDangerTap(zone: zone)
                    }
                }

                // ── Shoot target ──────────────────────────────
                ZStack {
                    // Glow ring
                    Circle()
                        .stroke(AuraColors.accentGlow.opacity(hitFlash ? 0.9 : 0.35), lineWidth: hitFlash ? 4 : 2)
                        .frame(width: target.size * 2 + 16, height: target.size * 2 + 16)
                        .scaleEffect(hitFlash ? 1.3 : 1.0)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AuraColors.accent, AuraColors.accentDim],
                                center: .center, startRadius: 0, endRadius: target.size
                            )
                        )
                        .frame(width: target.size * 2, height: target.size * 2)
                        .shadow(color: AuraColors.accentGlow.opacity(hitFlash ? 1.0 : 0.6), radius: hitFlash ? 20 : 10)

                    Image(systemName: "crosshairs")
                        .font(.system(size: target.size * 0.7, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .position(target.pos)
                .scaleEffect(hitFlash ? 1.15 : 1.0)
                .animation(.spring(response: 0.15, dampingFraction: 0.6), value: hitFlash)
                .onTapGesture {
                    handleTargetTap()
                }

                // ── Score popup ────────────────────────────────
                if let popup = scorePopup {
                    Text(popup.text)
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(popup.text.contains("-") ? AuraColors.redChip : AuraColors.accent)
                        .shadow(color: (popup.text.contains("-") ? AuraColors.redChip : AuraColors.accentGlow).opacity(0.8), radius: 6)
                        .position(popup.pos)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.5).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }

                // ── Danger flash overlay ───────────────────────
                if dangerHit {
                    Color.red.opacity(0.12)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .onAppear  { startGame(geo: geo) }
            .onDisappear { stopGame() }
        }
        .ignoresSafeArea()
    }

    // MARK: - Background canvas
    private func scanlineCanvas(size: CGSize) -> some View {
        Canvas { ctx, sz in
            let col = Color(red: 0.05, green: 0.95, blue: 0.35).opacity(0.045)
            var path = Path()
            var y: CGFloat = 0
            while y <= sz.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: sz.width, y: y)); y += 3 }
            ctx.stroke(path, with: .color(col), lineWidth: 0.4)
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Game logic

    private func startGame(geo: GeometryProxy) {
        target.pos = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        spawnDangers(geo: geo)

        physicsTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard settings.currentSession.isActive else { return }
                updatePhysics(geo: geo)
            }
    }

    private func spawnDangers(geo: GeometryProxy) {
        let count = 3
        dangers = (0..<count).map { _ in
            DangerZone(
                pos: CGPoint(
                    x: CGFloat.random(in: 60...(geo.size.width - 60)),
                    y: CGFloat.random(in: 80...(geo.size.height - 80))
                ),
                vel: CGSize(
                    width:  CGFloat.random(in: -1.4...1.4),
                    height: CGFloat.random(in: -1.0...1.0)
                ),
                size: CGFloat.random(in: 28...42)
            )
        }
    }

    private func updatePhysics(geo: GeometryProxy) {
        let margin: CGFloat = 50
        let w = geo.size.width, h = geo.size.height

        // Move target
        target.pos.x += target.vel.width
        target.pos.y += target.vel.height

        // Add slight speed increase over time
        let elapsed = settings.selectedGame.roundDuration - settings.currentSession.timeRemaining
        let speedMul: CGFloat = 1.0 + CGFloat(elapsed) * 0.012

        if target.pos.x < margin || target.pos.x > w - margin { target.vel.width  *= -speedMul }
        if target.pos.y < margin || target.pos.y > h - margin { target.vel.height *= -speedMul }
        target.pos.x = max(margin, min(w - margin, target.pos.x))
        target.pos.y = max(margin, min(h - margin, target.pos.y))

        // Move dangers
        for i in dangers.indices {
            dangers[i].pos.x += dangers[i].vel.width
            dangers[i].pos.y += dangers[i].vel.height
            let m: CGFloat = dangers[i].size + 10
            if dangers[i].pos.x < m || dangers[i].pos.x > w - m { dangers[i].vel.width  *= -1 }
            if dangers[i].pos.y < m || dangers[i].pos.y > h - m { dangers[i].vel.height *= -1 }
        }
    }

    private func handleTargetTap() {
        guard settings.currentSession.isActive else { return }

        let combo = settings.currentSession.combo + 1
        let pts   = 120 + min(180, combo * 15)

        settings.currentSession.hits    += 1
        settings.currentSession.score   += pts
        settings.currentSession.combo    = combo
        settings.currentSession.maxCombo = max(settings.currentSession.maxCombo, combo)

        showPopup("+\(pts)", at: target.pos)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation { hitFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation { hitFlash = false }
        }
    }

    private func handleDangerTap(zone: DangerZone) {
        guard settings.currentSession.isActive else { return }

        settings.currentSession.misses += 1
        settings.currentSession.combo   = 0
        settings.currentSession.score   = max(0, settings.currentSession.score - 60)

        showPopup("-60", at: zone.pos)
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        withAnimation { dangerHit = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { dangerHit = false }
        }
    }

    private func showPopup(_ text: String, at pos: CGPoint) {
        withAnimation(.spring(response: 0.2)) {
            scorePopup = (text, pos)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                scorePopup = nil
            }
        }
    }

    private func stopGame() {
        physicsTimer?.cancel()
    }
}
