import SwiftUI

struct TrainingView: View {
    @ObservedObject var settings: AppSettings
    @EnvironmentObject var lm: LocalizationManager
    @EnvironmentObject var rc: RevenueCatService
    @State private var isPlayingGame    = false
    @State private var showPaywall      = false

    private var vol1: [TrainingGameMode] { TrainingGameMode.allCases.filter { $0.volume == 1 } }
    private var vol2: [TrainingGameMode] { TrainingGameMode.allCases.filter { $0.volume == 2 } }

    var body: some View {
        ZStack {
            AuraColors.gradientBackground.ignoresSafeArea()

            if isPlayingGame {
                TrainingGameContainer(settings: settings, onExit: {
                    withAnimation { isPlayingGame = false }
                })
            } else {
                drillSelectionView
            }

            if settings.hasOverlayEnabled && isPlayingGame {
                deviceOverlayBar
            }
        }
    }

    // MARK: - Selection

    private var drillSelectionView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 26) {

                // ── Header ──────────────────────────────────────────
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AuraColors.accentGradient)
                            .frame(width: 3, height: 22)
                            .shadow(color: AuraColors.accentGlow, radius: 6)
                        Text("TRAINING")
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(3)
                        Spacer()
                        if settings.isPoweredOn {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(AuraColors.accent)
                                    .frame(width: 6, height: 6)
                                    .shadow(color: AuraColors.accentGlow, radius: 4)
                                Text("\(settings.activeFeatureSummary.count) ACTIVE")
                                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                    .foregroundColor(AuraColors.accent)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(AuraColors.accent.opacity(0.12))
                                .overlay(Capsule().stroke(AuraColors.accent.opacity(0.4), lineWidth: 0.8)))
                        }
                        if !rc.isPro {
                            AuraPremiumButton {
                                showPaywall = true
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                    }
                    Text("CHOOSE YOUR CHALLENGE")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(AuraColors.textTertiary)
                        .tracking(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 11)
                }
                .padding(.top, 16)

                // ── Premium banner ──────────────────────────────────
                if !rc.isPro {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill").font(.system(size: 13))
                            .foregroundColor(AuraColors.proGold)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("UPGRADE TO PREMIUM")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white).tracking(1)
                            Text("Unlock all training modes & premium features")
                                .font(.system(size: 10)).foregroundColor(AuraColors.textTertiary)
                        }
                        Spacer()
                        Button { showPaywall = true } label: {
                            Text("UNLOCK")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(AuraColors.accent))
                                .shadow(color: AuraColors.accentGlow.opacity(0.5), radius: 6)
                        }.buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AuraColors.proGold.opacity(0.07))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AuraColors.proGold.opacity(0.25), lineWidth: 0.8))
                    )
                }

                // ── Vol.1 Grid ──────────────────────────────────────
                volumeSection(title: "VOL.1 — CORE", subtitle: "REFLEX · PRECISION · STRATEGY", modes: vol1, accentColor: AuraColors.accent)

                // ── Vol.2 Grid ──────────────────────────────────────
                volumeSection(title: "VOL.2 — ADVANCED", subtitle: "TIMING · SEQUENCE · TRACKING", modes: vol2, accentColor: AuraColors.accentSecondary)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView().environmentObject(rc)
        }
    }

    // MARK: - Volume section (2-column card grid)

    @ViewBuilder
    private func volumeSection(title: String, subtitle: String, modes: [TrainingGameMode], accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section label
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 3, height: 16)
                        .cornerRadius(2)
                        .shadow(color: accentColor.opacity(0.8), radius: 4)
                    Text(title)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(accentColor)
                        .tracking(2)
                    Spacer()
                }
                Text(subtitle)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(AuraColors.textTertiary)
                    .tracking(1.5)
                    .padding(.leading, 11)
            }

            // 2-column grid
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(modes) { mode in
                    gameCard(mode: mode, accentColor: accentColor)
                }
            }
        }
    }

    // MARK: - Game card (square)

    @ViewBuilder
    private func gameCard(mode: TrainingGameMode, accentColor: Color) -> some View {
        let best      = settings.bestScores.best(for: mode)
        let diffCol   = difficultyColor(mode.difficulty)
        let isLocked  = mode.isPremium && !rc.isPro

        Button {
            if isLocked {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showPaywall = true
                return
            }
            settings.selectedGame = mode
            settings.resetSession()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { isPlayingGame = true }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            AdsService.shared.registerInteraction(for: .trainingAllGamesStart)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Top bar: difficulty + duration
                HStack(spacing: 6) {
                    Text(mode.difficulty.uppercased())
                        .font(.system(size: 7, weight: .heavy, design: .monospaced))
                        .foregroundColor(diffCol)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(diffCol.opacity(0.14)))

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "clock").font(.system(size: 7))
                        Text("\(Int(mode.roundDuration))s")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(AuraColors.textTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                        .shadow(color: accentColor.opacity(0.25), radius: 10)
                    Image(systemName: mode.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(accentColor)
                        .shadow(color: accentColor.opacity(0.8), radius: 6)
                }
                .padding(.leading, 14)

                Spacer()

                // Name + description
                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.rawValue.uppercased())
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(0.5)
                        .lineLimit(1)
                    Text(mode.description)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(AuraColors.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 14)

                // Best score + play caret
                HStack {
                    if best > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "trophy.fill").font(.system(size: 7))
                            Text("\(best)").font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(accentColor)
                    }
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentColor.opacity(0.8))
                        .padding(6)
                        .background(Circle().fill(accentColor.opacity(0.14)))
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 178)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AuraColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isLocked
                                    ? AuraColors.proGold.opacity(0.45)
                                    : accentColor.opacity(0.22),
                                    lineWidth: isLocked ? 1.2 : 1.0)
                    )
            )
            .shadow(color: accentColor.opacity(0.07), radius: 12)
            // ── Premium lock overlay ──
            .overlay(alignment: .topTrailing) {
                if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8, weight: .black))
                        Text("PRO")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .tracking(1)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AuraColors.proGold)
                            .shadow(color: AuraColors.proGold.opacity(0.5), radius: 6)
                    )
                    .padding(10)
                }
            }
            .overlay {
                if isLocked {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(AuraColors.proGold.opacity(0.8))
                                .shadow(color: AuraColors.proGold.opacity(0.4), radius: 8)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start \(mode.rawValue)")
    }

    // MARK: - Helpers

    private func difficultyColor(_ d: String) -> Color {
        switch d {
        case "Easy":   return AuraColors.greenPositive
        case "Medium": return AuraColors.yellowWarning
        case "Hard":   return Color(red: 1.0, green: 0.5, blue: 0.1)
        case "Expert": return AuraColors.redChip
        default:       return AuraColors.textTertiary
        }
    }

    // MARK: - Device Overlay

    private var deviceOverlayBar: some View {
        VStack {
            HStack(spacing: 6) {
                if settings.overlaySettings.showFPS         { AuraStatOverlayPill(label: "FPS",  value: "60") }
                if settings.overlaySettings.showBatteryTemp { AuraStatOverlayPill(label: "TEMP", value: "36°C", color: AuraColors.greenPositive) }
                if settings.overlaySettings.showRAM {
                    let used = Int(Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824 * 0.6)
                    AuraStatOverlayPill(label: "RAM", value: "\(used)GB")
                }
                if settings.overlaySettings.showPing  { AuraStatOverlayPill(label: "PING", value: "24ms", color: AuraColors.greenPositive) }
                if settings.overlaySettings.showDPI   { AuraStatOverlayPill(label: "DPI",  value: "\(Int(UIScreen.main.scale * 160))") }
            }
            .padding(.top, 4)
            Spacer()
        }
    }
}
