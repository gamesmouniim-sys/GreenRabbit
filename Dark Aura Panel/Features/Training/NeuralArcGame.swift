import SwiftUI
import Combine

// MARK: - Neural Arc Game
// Numbered nodes appear across the screen.
// Tap them in EXACT numerical order before the 5-second TTL expires.
// Wrong order → penalty + sequence reset.
// Completing a set spawns a new, harder one.
// 45-second round, Expert difficulty.

struct NeuralArcGame: View {
    @ObservedObject var settings: AppSettings

    private struct ArcNode: Identifiable {
        let id       = UUID()
        let index    : Int       // 1-based display number
        let pos      : CGPoint
        let size     : CGFloat   = 30
        var age      : Double    = 0
        let ttl      : Double    = 5.0
        var timedOut : Bool      = false
        var age01: Double { min(1.0, age / ttl) }
    }

    @State private var nodes        : [ArcNode] = []
    @State private var nextExpected : Int = 1
    @State private var setSize      : Int = 4
    @State private var setsDone     : Int = 0
    @State private var wrongFlash   : UUID? = nil
    @State private var driveTimer   : AnyCancellable?
    @State private var gameSize     : CGSize = .zero
    @State private var safeInsets   : EdgeInsets = .init()

    // Computed playable rect — keeps nodes fully visible clear of the
    // status bar (top), bottom tab bar, and device rounded corners.
    private var playBounds: CGRect {
        let nodeR : CGFloat = 40   // half of largest visual diameter (size*2+10)/2 + 5
        let tabBar: CGFloat = 100  // generous tab bar + bottom safe area
        let minX = safeInsets.leading  + nodeR
        let maxX = gameSize.width  - safeInsets.trailing  - nodeR
        let minY = safeInsets.top  + nodeR + 8
        let maxY = gameSize.height - safeInsets.bottom - tabBar - nodeR
        // Guard against degenerate size (first frame before layout)
        guard maxX > minX, maxY > minY else {
            return CGRect(x: nodeR, y: nodeR,
                          width: max(1, gameSize.width  - nodeR * 2),
                          height: max(1, gameSize.height - nodeR * 2))
        }
        return CGRect(x: minX, y: minY,
                      width: maxX - minX,
                      height: maxY - minY)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                neuralBackground(size: geo.size)

                // Arc lines between nodes (in order)
                if nodes.count > 1 {
                    Canvas { ctx, _ in
                        for i in 0..<(nodes.count - 1) {
                            let a = nodes[i], b = nodes[i + 1]
                            var p = Path()
                            p.move(to: a.pos)
                            p.addLine(to: b.pos)
                            let completed = i < nextExpected - 1
                            ctx.stroke(
                                p,
                                with: .color(AuraColors.accentSecondary.opacity(completed ? 0.55 : 0.15)),
                                style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                            )
                        }
                    }
                }

                // Nodes
                ForEach(nodes) { node in
                    let completed = node.index < nextExpected
                    let isWrong   = wrongFlash == node.id
                    let remaining = 1.0 - node.age01

                    ZStack {
                        // TTL ring
                        Circle()
                            .trim(from: 0, to: CGFloat(remaining))
                            .stroke(AuraColors.accentSecondary.opacity(0.5), lineWidth: 2.5)
                            .rotationEffect(.degrees(-90))
                            .frame(width: node.size * 2 + 10, height: node.size * 2 + 10)

                        // Core
                        Circle()
                            .fill(isWrong
                                  ? AuraColors.redChip.opacity(0.8)
                                  : completed
                                    ? AuraColors.accentDim.opacity(0.35)
                                    : AuraColors.accent.opacity(0.22))
                            .frame(width: node.size * 2, height: node.size * 2)
                            .overlay(
                                Circle()
                                    .stroke(
                                        isWrong ? AuraColors.redChip : (completed ? AuraColors.accent : AuraColors.accent.opacity(0.7)),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: completed ? AuraColors.accentGlow.opacity(0.5) : .clear, radius: 8)

                        // Number
                        Text("\(node.index)")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(
                                isWrong ? AuraColors.redChip : completed ? AuraColors.accentGlow : .white
                            )
                    }
                    .frame(width: node.size * 2 + 10, height: node.size * 2 + 10)
                    .position(node.pos)
                    .scaleEffect(isWrong ? 0.88 : (completed ? 0.92 : 1.0))
                    .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isWrong)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: completed)
                    .onTapGesture {
                        handleTap(node: node)
                    }
                }

                // HUD
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("SEQUENCES")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundColor(AuraColors.textTertiary)
                                .tracking(1.5)
                            Text("\(setsDone)")
                                .font(.system(size: 26, weight: .black, design: .monospaced))
                                .foregroundColor(AuraColors.accentSecondary)
                                .shadow(color: AuraColors.accentSecondaryGlow, radius: 6)
                                .contentTransition(.numericText())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
            }
            .onAppear  {
                gameSize   = geo.size
                safeInsets = geo.safeAreaInsets
                startGame(geo: geo)
            }
            .onDisappear { driveTimer?.cancel() }
        }
        .ignoresSafeArea()
    }

    // MARK: - Background
    private func neuralBackground(size: CGSize) -> some View {
        ZStack {
            Color(red: 0.02, green: 0.03, blue: 0.05).ignoresSafeArea()
            Canvas { ctx, sz in
                let col = AuraColors.accentSecondary.opacity(0.04)
                var x: CGFloat = 0
                while x <= sz.width  { var p = Path(); p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: sz.height)); ctx.stroke(p, with: .color(col), lineWidth: 0.4); x += 44 }
                var y: CGFloat = 0
                while y <= sz.height { var p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: sz.width, y: y)); ctx.stroke(p, with: .color(col), lineWidth: 0.4); y += 44 }
            }
        }
    }

    // MARK: - Logic
    private func startGame(geo: GeometryProxy) {
        spawnSet(size: geo.size)
        driveTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard settings.currentSession.isActive else { return }
                let dt = 1.0 / 30.0
                for i in nodes.indices {
                    nodes[i].age += dt
                }
                // Check timeouts
                if nodes.contains(where: { $0.age >= $0.ttl }) {
                    handleTimeout(size: gameSize)
                }
            }
    }

    private func spawnSet(size: CGSize) {
        let bounds = playBounds
        var newNodes: [ArcNode] = []
        var positions: [CGPoint] = []

        for i in 1...setSize {
            var pos: CGPoint
            var attempts = 0
            repeat {
                pos = CGPoint(
                    x: CGFloat.random(in: bounds.minX...bounds.maxX),
                    y: CGFloat.random(in: bounds.minY...bounds.maxY)
                )
                attempts += 1
            } while positions.contains(where: { hypot($0.x - pos.x, $0.y - pos.y) < 80 })
                      && attempts < 30

            // Hard clamp — guaranteed on-screen regardless of what random returned
            pos.x = pos.x.clamped(to: bounds.minX...bounds.maxX)
            pos.y = pos.y.clamped(to: bounds.minY...bounds.maxY)

            positions.append(pos)
            newNodes.append(ArcNode(index: i, pos: pos))
        }
        nodes = newNodes
        nextExpected = 1
    }

    private func handleTap(node: ArcNode) {
        guard settings.currentSession.isActive else { return }
        if node.index == nextExpected {
            // Correct
            nextExpected += 1
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            if nextExpected > setSize {
                // Completed full set!
                let combo = settings.currentSession.combo + 1
                let pts   = 200 + setSize * 40 + combo * 25
                settings.currentSession.score    += pts
                settings.currentSession.hits     += 1
                settings.currentSession.combo     = combo
                settings.currentSession.maxCombo  = max(settings.currentSession.maxCombo, combo)
                setsDone += 1

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                setSize = min(6, setSize + (setsDone % 2 == 0 ? 1 : 0))

                // Brief green flash before respawn
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    spawnSet(size: gameSize)
                }
            }
        } else {
            // Wrong order
            settings.currentSession.misses += 1
            settings.currentSession.combo   = 0
            settings.currentSession.score   = max(0, settings.currentSession.score - 50)

            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.spring(response: 0.15)) { wrongFlash = node.id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { wrongFlash = nil }
                // Reset ages so nodes don't instantly expire after a wrong tap
                for i in nodes.indices { nodes[i].age = 0 }
                nextExpected = 1
            }
        }
    }

    private func handleTimeout(size: CGSize) {
        settings.currentSession.misses += 1
        settings.currentSession.combo   = 0
        settings.currentSession.score   = max(0, settings.currentSession.score - 30)
        spawnSet(size: size)
    }
}

// MARK: - Helpers
private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
