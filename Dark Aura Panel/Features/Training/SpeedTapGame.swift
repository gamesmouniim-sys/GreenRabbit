import SwiftUI
import Combine

// MARK: - Speed Tap Game
// Tap the flashing circles as fast as possible before they expire.
// 15-second round; targets vanish after a short window to keep pressure high.

struct SpeedTapGame: View {
    @ObservedObject var settings: AppSettings

    // MARK: - Target model
    private struct TapTarget: Identifiable {
        let id   = UUID()
        let pos  : CGPoint
        let size : CGFloat          // radius
        var born : Date = .now
        let ttl  : TimeInterval     // time-to-live (s)

        var isExpired: Bool { Date.now.timeIntervalSince(born) >= ttl }
        var age: Double { min(1.0, Date.now.timeIntervalSince(born) / ttl) }
    }

    @State private var targets  : [TapTarget] = []
    @State private var hitFlash : [UUID: CGFloat] = [:]  // scale flash on hit
    @State private var tapCount : Int = 0
    @State private var spawnTimer: AnyCancellable?
    @State private var expireTimer: AnyCancellable?

    // Derived difficulty: more targets spawn as time shrinks
    private var spawnInterval: TimeInterval {
        let elapsed = settings.selectedGame.roundDuration - settings.currentSession.timeRemaining
        return max(0.35, 0.8 - elapsed * 0.008)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background grid
                neonGrid(size: geo.size)

                // TPS counter
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("TAPS")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundColor(AuraColors.textTertiary)
                                .tracking(1.5)
                            Text("\(tapCount)")
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

                // Targets
                ForEach(targets) { target in
                    let scale = hitFlash[target.id] ?? 1.0
                    let remaining = 1.0 - target.age

                    ZStack {
                        // Countdown ring
                        Circle()
                            .trim(from: 0, to: remaining)
                            .stroke(AuraColors.accentSecondary.opacity(0.5), lineWidth: 3)
                            .rotationEffect(.degrees(-90))

                        // Main circle
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AuraColors.accent.opacity(0.9), AuraColors.accentDim.opacity(0.5)],
                                    center: .center, startRadius: 0, endRadius: target.size
                                )
                            )
                            .shadow(color: AuraColors.accentGlow.opacity(0.7), radius: 10)

                        // Center cross
                        Image(systemName: "plus")
                            .font(.system(size: target.size * 0.55, weight: .black))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(width: target.size * 2, height: target.size * 2)
                    .position(target.pos)
                    .scaleEffect(scale)
                    .onTapGesture {
                        handleTap(target: target, geo: geo)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { _ in
                // Missed tap
                registerMiss()
            }
            .onAppear  { startGame(geo: geo) }
            .onDisappear { stopGame() }
        }
        .ignoresSafeArea()
    }

    // MARK: - Neon grid background
    private func neonGrid(size: CGSize) -> some View {
        Canvas { ctx, sz in
            let spacing: CGFloat = 40
            let col = Color(red: 0.05, green: 0.95, blue: 0.35).opacity(0.06)
            var path = Path()
            var x: CGFloat = 0
            while x <= sz.width  { path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: sz.height)); x += spacing }
            var y: CGFloat = 0
            while y <= sz.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: sz.width, y: y)); y += spacing }
            ctx.stroke(path, with: .color(col), lineWidth: 0.5)
        }
        .frame(width: size.width, height: size.height)
        .background(AuraColors.background)
    }

    // MARK: - Game logic
    private func startGame(geo: GeometryProxy) {
        targets = []
        tapCount = 0
        scheduleSpawn(geo: geo)

        // Expire old targets every 0.1s
        expireTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation(.linear(duration: 0.1)) {
                    targets.removeAll { $0.isExpired }
                }
            }
    }

    private func scheduleSpawn(geo: GeometryProxy) {
        guard settings.currentSession.isActive else { return }
        spawnTarget(geo: geo)
        DispatchQueue.main.asyncAfter(deadline: .now() + spawnInterval) {
            scheduleSpawn(geo: geo)
        }
    }

    private func spawnTarget(geo: GeometryProxy) {
        guard settings.currentSession.isActive else { return }
        let margin: CGFloat = 50
        let size: CGFloat   = CGFloat.random(in: 22...36)
        let pos = CGPoint(
            x: CGFloat.random(in: margin...(geo.size.width  - margin)),
            y: CGFloat.random(in: margin...(geo.size.height - margin))
        )
        let ttl: TimeInterval = max(0.6, 1.2 - Double(tapCount) * 0.003)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            targets.append(TapTarget(pos: pos, size: size, ttl: ttl))
        }
        if targets.count > 6 { targets.removeFirst() }  // cap simultaneous targets
    }

    private func handleTap(target: TapTarget, geo: GeometryProxy) {
        guard settings.currentSession.isActive else { return }

        tapCount += 1
        let combo   = settings.currentSession.combo + 1
        let pts     = 80 + min(70, combo * 8)

        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            hitFlash[target.id] = 1.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                hitFlash[target.id] = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                targets.removeAll { $0.id == target.id }
                hitFlash.removeValue(forKey: target.id)
            }
        }

        settings.currentSession.hits    += 1
        settings.currentSession.score   += pts
        settings.currentSession.combo    = combo
        settings.currentSession.maxCombo = max(settings.currentSession.maxCombo, combo)

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func registerMiss() {
        guard settings.currentSession.isActive else { return }
        settings.currentSession.misses += 1
        settings.currentSession.combo   = 0
        settings.currentSession.score   = max(0, settings.currentSession.score - 15)
    }

    private func stopGame() {
        spawnTimer?.cancel()
        expireTimer?.cancel()
    }
}
