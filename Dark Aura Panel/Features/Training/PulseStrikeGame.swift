import SwiftUI
import Combine

// MARK: - Pulse Strike Game
// A target sits at a fixed point.
// A concentric ring continuously EXPANDS from the target outward and resets.
// Tap the target when the expanding ring aligns with the fixed "strike circle"
// around the target. Timing window is tight — score by precision, not speed.
// 25-second round, Hard difficulty.

struct PulseStrikeGame: View {
    @ObservedObject var settings: AppSettings

    // Strike circle radius (fixed ring around target the pulse must match)
    private let strikeR: CGFloat = 38

    // Pulse animation: phase 0→1 means ring radius from 0 → maxPulseR
    private let maxPulseR: CGFloat = 90
    private let cycleLen : Double  = 1.8  // seconds per full pulse cycle

    @State private var pulsePhase : Double = 0     // 0→1
    @State private var targetPos  : CGPoint = CGPoint(x: 187, y: 380)
    @State private var strikes    : Int = 0
    @State private var lastResult : PulseResult = .none
    @State private var showResult : Bool = false
    @State private var driveTimer : AnyCancellable?

    enum PulseResult {
        case none, perfect, good, okay, miss
        var label: String {
            switch self { case .none: return ""; case .perfect: return "PERFECT"; case .good: return "GOOD"; case .okay: return "OKAY"; case .miss: return "MISS" }
        }
        var color: Color {
            switch self { case .perfect: return AuraColors.accent; case .good: return AuraColors.yellowWarning; case .okay: return AuraColors.accentSecondary; case .miss, .none: return AuraColors.redChip }
        }
        var points: Int {
            switch self { case .perfect: return 300; case .good: return 150; case .okay: return 60; case .miss: return -40; case .none: return 0 }
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pulseBackground(size: geo.size)

                let pR = maxPulseR * CGFloat(pulsePhase)

                // Outer expanding pulse ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [AuraColors.accentSecondary.opacity(0.7), AuraColors.accentSecondary.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 2.0
                    )
                    .frame(width: pR * 2, height: pR * 2)
                    .position(targetPos)
                    .opacity(Double(1.0 - CGFloat(pulsePhase) * 0.6))

                // Second trailing ring
                let pR2 = maxPulseR * CGFloat(max(0, pulsePhase - 0.18))
                if pulsePhase > 0.18 {
                    Circle()
                        .stroke(AuraColors.accent.opacity(0.25), lineWidth: 1.0)
                        .frame(width: pR2 * 2, height: pR2 * 2)
                        .position(targetPos)
                }

                // Fixed STRIKE circle (the "timing target")
                Circle()
                    .stroke(AuraColors.accentGlow.opacity(0.55), lineWidth: 1.5)
                    .frame(width: strikeR * 2, height: strikeR * 2)
                    .position(targetPos)
                    .shadow(color: AuraColors.accentGlow.opacity(0.4), radius: 6)

                // Target core
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AuraColors.accent.opacity(0.9), AuraColors.accentDim.opacity(0.5)],
                                center: .center, startRadius: 0, endRadius: 22
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: AuraColors.accentGlow.opacity(0.7), radius: 12)
                    Image(systemName: "scope")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .position(targetPos)

                // Result label
                if showResult {
                    Text(lastResult.label)
                        .font(.system(size: lastResult == .perfect ? 32 : 22, weight: .black, design: .monospaced))
                        .foregroundColor(lastResult.color)
                        .shadow(color: lastResult.color.opacity(0.8), radius: 10)
                        .position(x: targetPos.x, y: targetPos.y - 72)
                        .transition(.scale.combined(with: .opacity))
                }

                // HUD
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("STRIKES")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundColor(AuraColors.textTertiary)
                                .tracking(1.5)
                            Text("\(strikes)")
                                .font(.system(size: 26, weight: .black, design: .monospaced))
                                .foregroundColor(AuraColors.accent)
                                .shadow(color: AuraColors.accentGlow, radius: 8)
                                .contentTransition(.numericText())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }
                    Spacer()

                    // Timing meter at bottom
                    timingMeter
                        .padding(.bottom, 24)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleTap()
            }
            .onAppear  {
                targetPos = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.45)
                startGame()
            }
            .onDisappear { driveTimer?.cancel() }
        }
        .ignoresSafeArea()
    }

    // MARK: - Timing meter
    private var timingMeter: some View {
        VStack(spacing: 5) {
            Text("TAP WHEN RING HITS THE CIRCLE")
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)
                .tracking(1.2)

            GeometryReader { geo in
                let w = geo.size.width
                // Normalize pulse radius vs strike radius
                let strikeNorm = CGFloat(strikeR / maxPulseR)
                let perfectHalf: CGFloat = 0.04
                let goodHalf   : CGFloat = 0.10
                let okHalf     : CGFloat = 0.16
                let needleX = CGFloat(pulsePhase) * w

                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06)).frame(height: 6)
                    // Okay window
                    Capsule()
                        .fill(AuraColors.accentSecondary.opacity(0.25))
                        .frame(width: w * okHalf * 2, height: 6)
                        .offset(x: w * (strikeNorm - okHalf))
                    // Good window
                    Capsule()
                        .fill(AuraColors.yellowWarning.opacity(0.4))
                        .frame(width: w * goodHalf * 2, height: 6)
                        .offset(x: w * (strikeNorm - goodHalf))
                    // Perfect window
                    Capsule()
                        .fill(AuraColors.accent)
                        .frame(width: w * perfectHalf * 2, height: 6)
                        .offset(x: w * (strikeNorm - perfectHalf))
                    // Needle
                    Capsule()
                        .fill(.white)
                        .frame(width: 2, height: 12)
                        .offset(x: needleX - 1)
                        .shadow(color: AuraColors.accentGlow, radius: 4)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Background
    private func pulseBackground(size: CGSize) -> some View {
        ZStack {
            Color(red: 0.02, green: 0.03, blue: 0.05).ignoresSafeArea()
            Canvas { ctx, sz in
                let col = AuraColors.accentSecondary.opacity(0.035)
                for r in stride(from: CGFloat(60), through: max(sz.width, sz.height), by: 55) {
                    var p = Path()
                    p.addEllipse(in: CGRect(
                        x: sz.width / 2 - r, y: sz.height * 0.45 - r,
                        width: r * 2, height: r * 2
                    ))
                    ctx.stroke(p, with: .color(col), lineWidth: 0.4)
                }
            }
        }
    }

    // MARK: - Logic
    private func startGame() {
        driveTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard settings.currentSession.isActive else { return }
                pulsePhase += (1.0 / 60.0) / cycleLen
                if pulsePhase >= 1.0 { pulsePhase -= 1.0 }
            }
    }

    private func handleTap() {
        guard settings.currentSession.isActive else { return }

        // Current pulse radius
        let currentR = maxPulseR * CGFloat(pulsePhase)
        let diff = abs(currentR - strikeR)

        var result: PulseResult
        if diff <= maxPulseR * 0.04 {
            result = .perfect
        } else if diff <= maxPulseR * 0.10 {
            result = .good
        } else if diff <= maxPulseR * 0.16 {
            result = .okay
        } else {
            result = .miss
        }

        let pts = result.points
        let combo = result == .miss ? 0 : settings.currentSession.combo + 1

        if result != .miss {
            settings.currentSession.hits    += 1
            strikes += 1
        } else {
            settings.currentSession.misses  += 1
        }
        settings.currentSession.score    = max(0, settings.currentSession.score + pts + combo * 15)
        settings.currentSession.combo     = combo
        settings.currentSession.maxCombo  = max(settings.currentSession.maxCombo, combo)

        if result == .perfect {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if result == .miss {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        lastResult = result
        withAnimation(.spring(response: 0.15)) { showResult = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.25)) { showResult = false }
        }
    }
}
