import SwiftUI
import Combine

// MARK: - Zone Lock Game
// A glowing safe zone drifts around the screen.
// Tap INSIDE it to score (combo multiplier builds up).
// Tap OUTSIDE = penalty + combo reset.
// The zone shrinks and moves faster as time passes.
// 30-second round, Medium difficulty.

struct ZoneLockGame: View {
    @ObservedObject var settings: AppSettings

    // Zone state
    @State private var zonePos   : CGPoint = .zero
    @State private var zoneVel   : CGSize  = CGSize(width: 1.4, height: 1.0)
    @State private var zoneRadius: CGFloat = 52
    @State private var pulsing   : Bool    = false   // ring pulse animation
    @State private var successRing: Bool   = false
    @State private var dangerFlash: Bool   = false
    @State private var tapCount  : Int     = 0
    @State private var driveTimer: AnyCancellable?
    @State private var pulseTimer : AnyCancellable?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                zoneBackground(size: geo.size)

                // Safe zone
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(
                            AuraColors.accent.opacity(pulsing ? 0.0 : 0.35),
                            lineWidth: 1.2
                        )
                        .frame(width: zoneRadius * 2 + 28, height: zoneRadius * 2 + 28)
                        .scaleEffect(pulsing ? 1.35 : 1.0)
                        .animation(.easeOut(duration: 0.5), value: pulsing)

                    // Zone fill
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AuraColors.accent.opacity(0.18),
                                    AuraColors.accent.opacity(0.04)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: zoneRadius
                            )
                        )
                        .frame(width: zoneRadius * 2, height: zoneRadius * 2)
                        .overlay(
                            Circle()
                                .stroke(AuraColors.accent.opacity(0.75), lineWidth: 1.5)
                                .frame(width: zoneRadius * 2, height: zoneRadius * 2)
                                .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 8)
                        )

                    // Success ring flash
                    if successRing {
                        Circle()
                            .stroke(AuraColors.accentGlow.opacity(0.7), lineWidth: 2.5)
                            .frame(width: zoneRadius * 2 + 8, height: zoneRadius * 2 + 8)
                    }

                    // Center crosshair
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(AuraColors.accent.opacity(0.8))
                        .shadow(color: AuraColors.accentGlow, radius: 6)
                }
                .position(zonePos)

                // Tap flash
                if dangerFlash {
                    Color.red.opacity(0.10).ignoresSafeArea().allowsHitTesting(false)
                }

                // HUD
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("ZONE HITS")
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

                // Zone radius indicator
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "circle.dashed")
                            .font(.system(size: 10))
                            .foregroundColor(AuraColors.textTertiary)
                        Text("ZONE \(Int(zoneRadius))pt")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundColor(AuraColors.textTertiary)
                            .tracking(1)
                    }
                    .padding(.bottom, 22)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                handleTap(at: location)
            }
            .onAppear  { startGame(geo: geo) }
            .onDisappear { driveTimer?.cancel(); pulseTimer?.cancel() }
        }
        .ignoresSafeArea()
    }

    // MARK: - Background
    private func zoneBackground(size: CGSize) -> some View {
        ZStack {
            Color(red: 0.02, green: 0.05, blue: 0.03).ignoresSafeArea()
            Canvas { ctx, sz in
                let col = AuraColors.accent.opacity(0.035)
                // Diagonal scan lines
                var y: CGFloat = -sz.width
                while y <= sz.height + sz.width {
                    var p = Path()
                    p.move(to: .init(x: 0, y: y))
                    p.addLine(to: .init(x: sz.width, y: y + sz.width))
                    ctx.stroke(p, with: .color(col), lineWidth: 0.4)
                    y += 18
                }
            }
        }
    }

    // MARK: - Logic
    private func startGame(geo: GeometryProxy) {
        zonePos = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

        driveTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard settings.currentSession.isActive else { return }
                updateZone(geo: geo)
            }

        pulseTimer = Timer.publish(every: 1.2, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation { pulsing = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { pulsing = false }
                }
            }
    }

    private func updateZone(geo: GeometryProxy) {
        let elapsed = settings.selectedGame.roundDuration - settings.currentSession.timeRemaining
        let speedMul: CGFloat = 1.0 + CGFloat(elapsed) * 0.025

        zonePos.x += zoneVel.width  * speedMul
        zonePos.y += zoneVel.height * speedMul

        let margin = zoneRadius + 20
        if zonePos.x < margin || zonePos.x > geo.size.width  - margin { zoneVel.width  *= -1 }
        if zonePos.y < margin || zonePos.y > geo.size.height - margin { zoneVel.height *= -1 }

        zonePos.x = max(margin, min(geo.size.width  - margin, zonePos.x))
        zonePos.y = max(margin, min(geo.size.height - margin, zonePos.y))

        // Shrink zone over time
        let targetRadius = max(28, 52 - CGFloat(elapsed) * 0.4)
        zoneRadius = zoneRadius + (targetRadius - zoneRadius) * 0.02
    }

    private func handleTap(at location: CGPoint) {
        guard settings.currentSession.isActive else { return }

        let dist = hypot(location.x - zonePos.x, location.y - zonePos.y)
        if dist <= zoneRadius {
            // Inside zone
            tapCount += 1
            let combo = settings.currentSession.combo + 1
            let pts   = 30 + min(70, combo * 8)
            settings.currentSession.hits    += 1
            settings.currentSession.score   += pts
            settings.currentSession.combo    = combo
            settings.currentSession.maxCombo = max(settings.currentSession.maxCombo, combo)

            withAnimation(.spring(response: 0.15)) { successRing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation { successRing = false }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            // Outside zone
            settings.currentSession.misses += 1
            settings.currentSession.combo   = 0
            settings.currentSession.score   = max(0, settings.currentSession.score - 20)
            withAnimation { dangerFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { dangerFlash = false }
            }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }
}
