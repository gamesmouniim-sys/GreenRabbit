import SwiftUI
import Combine

// MARK: - Phantom Rush Game
// Ghost targets flicker between visible and invisible.
// Tap them ONLY during their bright visible flash.
// Tapping during the invisible phase costs points.
// 20-second round, Hard difficulty.

struct PhantomRushGame: View {
    @ObservedObject var settings: AppSettings

    private struct PhantomTarget: Identifiable {
        let id      = UUID()
        let pos     : CGPoint
        let size    : CGFloat
        var phase   : Double = 0        // 0→1 per pulse cycle
        let cycleLen: Double            // seconds per full cycle
        let visibleFraction: Double     // fraction of cycle that is "bright"

        var brightness: Double {
            // Sinusoidal: visible at top of sine curve
            let norm = sin(phase * .pi * 2)
            return max(0, norm)
        }
        var isVisible: Bool { phase < visibleFraction }
    }

    @State private var targets   : [PhantomTarget] = []
    @State private var hitFlashes: [UUID: Double]  = [:]   // opacity flash
    @State private var missFlash : Bool            = false
    @State private var driveTimer: AnyCancellable?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                ghostBackground(size: geo.size)

                // Targets
                ForEach(targets) { target in
                    let alpha = hitFlashes[target.id] ?? target.brightness
                    ZStack {
                        // Outer ghost ring
                        Circle()
                            .stroke(
                                AuraColors.accent.opacity(alpha * 0.5),
                                lineWidth: 2
                            )
                            .frame(width: target.size * 2 + 12, height: target.size * 2 + 12)
                        // Core
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(alpha * 0.95),
                                        AuraColors.accent.opacity(alpha * 0.8)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: target.size
                                )
                            )
                            .frame(width: target.size * 2, height: target.size * 2)
                            .shadow(color: AuraColors.accentGlow.opacity(alpha * 0.9), radius: 12)
                        // Ghost symbol
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: target.size * 0.65, weight: .bold))
                            .foregroundColor(Color.black.opacity(alpha * 0.7))
                    }
                    .position(target.pos)
                    .onTapGesture {
                        handleTap(target: target)
                    }
                }

                // Miss flash vignette
                if missFlash {
                    Color.red.opacity(0.10)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // HUD
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("PHANTOMS")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundColor(AuraColors.textTertiary)
                                .tracking(1.5)
                            Text("\(settings.currentSession.hits)")
                                .font(.system(size: 26, weight: .black, design: .monospaced))
                                .foregroundColor(AuraColors.accent)
                                .shadow(color: AuraColors.accentGlow, radius: 8)
                                .contentTransition(.numericText())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { registerMiss() }
            .onAppear  { startGame(geo: geo) }
            .onDisappear { driveTimer?.cancel() }
        }
        .ignoresSafeArea()
    }

    // MARK: - Background
    private func ghostBackground(size: CGSize) -> some View {
        ZStack {
            Color(red: 0.02, green: 0.04, blue: 0.03).ignoresSafeArea()
            Canvas { ctx, sz in
                // Hex-ish grid
                let col = AuraColors.accent.opacity(0.04)
                let step: CGFloat = 48
                var x: CGFloat = 0
                while x <= sz.width {
                    var y: CGFloat = (x / step).truncatingRemainder(dividingBy: 2) == 0 ? 0 : step / 2
                    while y <= sz.height {
                        var p = Path()
                        p.addEllipse(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                        ctx.fill(p, with: .color(col))
                        y += step
                    }
                    x += step
                }
            }
        }
    }

    // MARK: - Game logic
    private func startGame(geo: GeometryProxy) {
        spawnTargets(geo: geo)

        // Drive phase animation at 30fps
        driveTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard settings.currentSession.isActive else { return }
                let dt = 1.0 / 30.0
                for i in targets.indices {
                    targets[i].phase += dt / targets[i].cycleLen
                    if targets[i].phase >= 1.0 { targets[i].phase -= 1.0 }
                }
                // Spawn more targets every ~3s
                let elapsed = settings.selectedGame.roundDuration - settings.currentSession.timeRemaining
                let wanted = min(5, 2 + Int(elapsed / 3))
                if targets.count < wanted { spawnTargets(geo: geo) }
            }
    }

    private func spawnTargets(geo: GeometryProxy) {
        let count = min(3, 2)
        let margin: CGFloat = 55
        for _ in 0..<count {
            let t = PhantomTarget(
                pos: CGPoint(
                    x: CGFloat.random(in: margin...(geo.size.width  - margin)),
                    y: CGFloat.random(in: margin...(geo.size.height - margin))
                ),
                size: CGFloat.random(in: 22...34),
                phase: Double.random(in: 0...1),
                cycleLen: Double.random(in: 1.0...1.8),
                visibleFraction: Double.random(in: 0.30...0.50)
            )
            targets.append(t)
        }
    }

    private func handleTap(target: PhantomTarget) {
        guard settings.currentSession.isActive else { return }
        if target.isVisible {
            // Good hit
            let combo = settings.currentSession.combo + 1
            let pts   = 100 + min(100, combo * 12)
            settings.currentSession.hits    += 1
            settings.currentSession.score   += pts
            settings.currentSession.combo    = combo
            settings.currentSession.maxCombo = max(settings.currentSession.maxCombo, combo)

            withAnimation(.easeOut(duration: 0.15)) { hitFlashes[target.id] = 1.5 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeIn(duration: 0.2)) { hitFlashes.removeValue(forKey: target.id) }
                targets.removeAll { $0.id == target.id }
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            // Tapped ghost while invisible
            settings.currentSession.misses += 1
            settings.currentSession.combo   = 0
            settings.currentSession.score   = max(0, settings.currentSession.score - 30)
            withAnimation { missFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation { missFlash = false }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func registerMiss() {
        guard settings.currentSession.isActive else { return }
        settings.currentSession.misses += 1
        settings.currentSession.combo   = 0
        settings.currentSession.score   = max(0, settings.currentSession.score - 15)
    }
}
