import SwiftUI
import Combine

// MARK: - Game Phase
private enum GamePhase: Equatable {
    case countdown(Int)
    case playing
    case result
}

struct TrainingGameContainer: View {
    @ObservedObject var settings: AppSettings
    @EnvironmentObject var lm: LocalizationManager
    let onExit: () -> Void

    @State private var phase: GamePhase = .countdown(3)
    @State private var didTriggerFinishAd = false

    // Publish timers — always running, guarded by phase checks inside handlers
    private let countdownTick = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let gameTick      = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch phase {
            case .countdown(let n):
                countdownOverlay(n)

            case .playing:
                VStack(spacing: 0) {
                    gameHUD
                    gameContent
                }

            case .result:
                AuraResultBanner(
                    isWin: settings.currentSession.isWin,
                    score: settings.currentSession.score,
                    accuracy: settings.currentSession.accuracy,
                    headshots: settings.currentSession.headshots,
                    onRetry: {
                        settings.resetSession()
                        didTriggerFinishAd = false
                        withAnimation { phase = .countdown(3) }
                    },
                    onExit: { onExit() }
                )
            }
        }
        .onReceive(countdownTick) { _ in
            guard case .countdown(let n) = phase else { return }
            if n > 1 {
                withAnimation { phase = .countdown(n - 1) }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                withAnimation {
                    settings.currentSession.isActive = true
                    settings.currentSession.timeRemaining = settings.selectedGame.roundDuration
                    phase = .playing
                }
            }
        }
        .onReceive(gameTick) { _ in
            guard case .playing = phase,
                  settings.currentSession.isActive else { return }
            if settings.currentSession.timeRemaining > 0.1 {
                settings.currentSession.timeRemaining -= 0.1
            } else {
                settings.currentSession.isActive = false
                settings.endSession()
                if !didTriggerFinishAd {
                    didTriggerFinishAd = true
                    AdsService.shared.registerInteraction(
                        for: settings.currentSession.isWin ? .trainingFinishWin : .trainingFinishLose
                    )
                }
                withAnimation { phase = .result }
            }
        }
    }

    // MARK: - Countdown overlay

    private func countdownOverlay(_ n: Int) -> some View {
        ZStack(alignment: .topLeading) {
            // Close button during countdown
            Button {
                onExit()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AuraColors.accent)
                    Text(lm.t(.exit))
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(AuraColors.accent)
                        .tracking(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().fill(Color.black.opacity(0.35)))
                        .overlay(Capsule().stroke(AuraColors.accent.opacity(0.45), lineWidth: 1))
                )
                .shadow(color: AuraColors.accentGlow.opacity(0.25), radius: 6)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.leading, 16)

            // Countdown number centered
            VStack(spacing: 12) {
                Text(settings.selectedGame.rawValue.uppercased())
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(AuraColors.accent)
                    .tracking(3)
                Text("\(n)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Game HUD

    private var gameHUD: some View {
        HStack(spacing: 10) {
            // ── Close button (top-left, app glass style) ──
            Button {
                settings.currentSession.isActive = false
                settings.endSession()
                onExit()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AuraColors.accent)
                    Text(lm.t(.exit))
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(AuraColors.accent)
                        .tracking(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().fill(Color.black.opacity(0.35)))
                        .overlay(Capsule().stroke(AuraColors.accent.opacity(0.45), lineWidth: 1))
                )
                .shadow(color: AuraColors.accentGlow.opacity(0.25), radius: 6)
            }
            .buttonStyle(.plain)

            // ── Score ──
            VStack(alignment: .leading, spacing: 1) {
                Text(lm.t(.score))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(AuraColors.textTertiary)
                Text("\(settings.currentSession.score)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            }

            Spacer()

            if settings.currentSession.combo > 1 {
                Text("x\(settings.currentSession.combo)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(AuraColors.accent)
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // ── Time ──
            VStack(alignment: .trailing, spacing: 1) {
                Text(lm.t(.time))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(AuraColors.textTertiary)
                Text(String(format: "%.1f", max(0, settings.currentSession.timeRemaining)))
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(settings.currentSession.timeRemaining < 5 ? AuraColors.accent : .white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
    }

    // MARK: - Game Content

    @ViewBuilder
    private var gameContent: some View {
        switch settings.selectedGame {
        // Green Rabbit Vol.1
        case .speedTap:         SpeedTapGame(settings: settings)
        case .sniperZeroing:    SniperZeroingGame(settings: settings)
        case .dodgeShoot:       DodgeShootGame(settings: settings)
        case .memoryGrid:       MemoryGridGame(settings: settings)
        // Green Rabbit Vol.2
        case .phantomRush:      PhantomRushGame(settings: settings)
        case .neuralArc:        NeuralArcGame(settings: settings)
        case .zoneLock:         ZoneLockGame(settings: settings)
        case .pulseStrike:      PulseStrikeGame(settings: settings)
        }
    }
}
