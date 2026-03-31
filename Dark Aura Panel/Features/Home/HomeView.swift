import SwiftUI
import StoreKit

struct HomeView: View {
    @ObservedObject var settings: AppSettings
    @Binding var selectedTab: AuraTab
    @EnvironmentObject var lm: LocalizationManager
    @EnvironmentObject var rc: RevenueCatService
    @Environment(\.requestReview) private var requestReview
    @State private var showAlert   = false
    @State private var showPaywall = false
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding   = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                headerHUD
                powerCore
                moduleSection(title: "CROSSHAIR", icon: "plus.viewfinder", rows: [
                    ModuleRow(label: "Standard Aim",   icon: "plus.viewfinder",            sub: "Crosshair overlay", isOn: $settings.basicAimEnabled),
                    ModuleRow(label: "Expert Aim",     icon: "slider.horizontal.below.rectangle", sub: "Custom config", isOn: $settings.aimSetupEnabled, isProOnly: true),
                    ModuleRow(label: "Aim Colors",     icon: "paintpalette.fill",          sub: "Color schemes", isOn: $settings.aimColorsEnabled, rewarded: .homeAimColors),
                    ModuleRow(label: "Aim Settings",   icon: "gearshape.fill",             sub: "Advanced tweaks", isOn: $settings.aimSettingsEnabled),
                ])
                moduleSection(title: "SENSI CONFIG", icon: "speedometer", rows: [
                    ModuleRow(label: "Mobile Sensi",   icon: "hand.point.up.left.fill",   sub: "Global sensitivity", isOn: $settings.phoneSensiEnabled),
                    ModuleRow(label: "HUD Layout",     icon: "rectangle.split.3x3",        sub: "Button placement", isOn: $settings.hudMobileEnabled),
                    ModuleRow(label: "Mobile DPI",     icon: "viewfinder",                 sub: "DPI calibration", isOn: $settings.phoneDPIEnabled),
                    ModuleRow(label: "Gun Sensi",      icon: "scope",                      sub: "Per-weapon tuning", isOn: $settings.gunSensiEnabled, isProOnly: true),
                ])
                moduleSection(title: "TRICK BUTTON", icon: "paintbrush.fill", rows: [
                    ModuleRow(label: "Ball Color",     icon: "paintbrush.fill",            sub: "Projectile color", isOn: $settings.ballPaintEnabled),
                    ModuleRow(label: "Ball Config",    icon: "circle.dashed",              sub: "Custom trajectory", isOn: $settings.ballSetupEnabled, isProOnly: true),
                    ModuleRow(label: "Hide Ball",      icon: "eye.slash.fill",             sub: "Hide projectile", isOn: $settings.invisibleBallEnabled, rewarded: .homeInvisibleBall),
                ])
                moduleSection(title: "TOOLS", icon: "gauge.high", rows: [
                    ModuleRow(label: "FPS Counter",    icon: "gauge.high",                 sub: "Live frame rate", isOn: $settings.overlaySettings.showFPS),
                    ModuleRow(label: "Thermal",        icon: "thermometer.medium",         sub: "Battery temp", isOn: $settings.overlaySettings.showBatteryTemp),
                    ModuleRow(label: "RAM Usage",      icon: "memorychip",                 sub: "Memory readout", isOn: $settings.overlaySettings.showRAM, rewarded: .homeRAM),
                    ModuleRow(label: "Ping Monitor",   icon: "wifi",                       sub: "Network latency", isOn: $settings.overlaySettings.showPing, isProOnly: true),
                    ModuleRow(label: "DPI Overlay",    icon: "rectangle.dashed",           sub: "Screen DPI", isOn: $settings.overlaySettings.showDPI, isProOnly: true),
                ])
                moduleSection(title: "OPTIMIZE GAME", icon: "sparkles", rows: [
                    ModuleRow(label: "Delete Junk",    icon: "trash.fill",                 sub: "Clear cache & temp files", isOn: $settings.deleteJunkEnabled),
                    ModuleRow(label: "Silent Mode",    icon: "speaker.slash.fill",         sub: "Mute system sounds", isOn: $settings.silentModeEnabled),
                ])
                rateCard
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
        .background(AuraColors.gradientBackground.ignoresSafeArea())
        .overlay {
            if showAlert {
                AuraAlertView(message: lm.t(.enableFeatureFirst)) {
                    withAnimation { showAlert = false }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView().environmentObject(rc)
        }
    }

    // MARK: - Header HUD

    private var headerHUD: some View {
        HStack(spacing: 0) {
            // Left: App name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AuraColors.accentGradient)
                        .frame(width: 3, height: 22)
                        .shadow(color: AuraColors.accentGlow, radius: 5)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("DARK AURA")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(AuraColors.accent)
                            .tracking(3)
                        Text("GREEN RABBIT")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(2)
                    }
                }
                Text("COMMAND CENTER  ·  READY")
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundColor(AuraColors.textTertiary)
                    .tracking(1.5)
                    .padding(.leading, 9)
            }
            Spacer()

            // Right: Status + GET PREMIUM
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(settings.isPoweredOn ? AuraColors.accent : AuraColors.textTertiary)
                        .frame(width: 6, height: 6)
                        .shadow(color: settings.isPoweredOn ? AuraColors.accentGlow : .clear, radius: 4)
                    Text(settings.isPoweredOn ? "ARMED" : "STANDBY")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(settings.isPoweredOn ? AuraColors.accent : AuraColors.textTertiary)
                        .tracking(1)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(settings.isPoweredOn ? AuraColors.accent.opacity(0.12) : Color.white.opacity(0.06))
                        .overlay(Capsule().stroke(settings.isPoweredOn ? AuraColors.accent.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 0.8))
                )

                if !rc.isPro {
                    AuraPremiumButton {
                        showPaywall = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Power Core

    private var powerCore: some View {
        ZStack {
            // Cyberpunk grid
            Canvas { ctx, sz in
                let col = Color(red: 0.05, green: 0.95, blue: 0.35).opacity(0.06)
                var path = Path()
                var x: CGFloat = 0
                while x <= sz.width  { path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: sz.height)); x += 28 }
                var y: CGFloat = 0
                while y <= sz.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: sz.width, y: y)); y += 28 }
                ctx.stroke(path, with: .color(col), lineWidth: 0.4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(spacing: 18) {
                AuraPowerButton(isActive: settings.isPoweredOn) { handlePowerTap() }

                VStack(spacing: 6) {
                    Text(settings.isPoweredOn ? lm.t(.trainingArmed) : lm.t(.standby))
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(settings.isPoweredOn ? AuraColors.accent : AuraColors.textTertiary)
                        .tracking(3)
                    if settings.isPoweredOn {
                        Text("MODULES DEPLOYED — READY FOR COMBAT")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(AuraColors.accent.opacity(0.5))
                            .tracking(1)
                    }
                }
            }
            .padding(.vertical, 28)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AuraColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            settings.isPoweredOn ? AuraColors.accent.opacity(0.3) : AuraColors.cardBorder,
                            lineWidth: settings.isPoweredOn ? 1.2 : 0.8
                        )
                )
        )
        .shadow(color: settings.isPoweredOn ? AuraColors.accentGlow.opacity(0.1) : .clear, radius: 16)
    }

    // MARK: - Module Section

    @ViewBuilder
    private func moduleSection(title: String, icon: String, rows: [ModuleRow]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AuraColors.accent)
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(AuraColors.accent)
                    .tracking(2)
                Rectangle()
                    .fill(AuraColors.accent.opacity(0.2))
                    .frame(height: 0.8)
                Spacer()
            }

            // Module cards
            VStack(spacing: 8) {
                ForEach(rows) { row in
                    moduleCard(row)
                }
            }
        }
    }

    @ViewBuilder
    private func moduleCard(_ row: ModuleRow) -> some View {
        let isLocked = row.isProOnly && !rc.isPro
        let isOn     = row.isOn.wrappedValue
        let toggle   = Binding<Bool>(
            get: { row.isOn.wrappedValue },
            set: { v in handleFeatureToggle(row, newValue: v, isLocked: isLocked) }
        )

        HStack(spacing: 14) {
            // Icon zone
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isOn ? AuraColors.accent.opacity(0.18) : Color.white.opacity(0.04))
                    .frame(width: 42, height: 42)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(isOn ? AuraColors.accent.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 0.8)
                    )
                Image(systemName: isLocked ? "lock.fill" : row.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isLocked ? AuraColors.textTertiary : (isOn ? AuraColors.accent : AuraColors.textSecondary))
                    .shadow(color: isOn ? AuraColors.accentGlow.opacity(0.8) : .clear, radius: 5)
            }

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(row.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isOn ? .white : AuraColors.textSecondary)
                Text(row.sub)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(AuraColors.textTertiary)
            }

            Spacer()

            // Premium badge or custom ARM switch
            if isLocked {
                Button { showPaywall = true; UIImpactFeedbackGenerator(style: .light).impactOccurred() } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill").font(.system(size: 8, weight: .bold))
                        Text("PREMIUM").font(.system(size: 7, weight: .heavy, design: .monospaced)).tracking(0.5)
                    }
                    .foregroundColor(AuraColors.proGold)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(AuraColors.proGold.opacity(0.12)).overlay(Capsule().stroke(AuraColors.proGold.opacity(0.4), lineWidth: 0.8)))
                }
                .buttonStyle(.plain)
            }

            // Custom ARM toggle
            AuraArmToggle(isOn: toggle)
                .disabled(isLocked)
                .opacity(isLocked ? 0.3 : 1.0)
                .allowsHitTesting(!isLocked)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isOn
                    ? AuraColors.accent.opacity(0.06)
                    : Color(red: 0.05, green: 0.08, blue: 0.06).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isOn ? AuraColors.accent.opacity(0.28) : Color.white.opacity(0.05), lineWidth: isOn ? 1.0 : 0.6)
                )
        )
        .shadow(color: isOn ? AuraColors.accent.opacity(0.06) : .clear, radius: 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if isLocked { showPaywall = true; UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
    }

    // MARK: - Rate card

    private var rateCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            requestReview()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 1, green: 0.8, blue: 0).opacity(0.14))
                        .frame(width: 42, height: 42)
                    Image(systemName: "star.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(red: 1, green: 0.8, blue: 0))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(lm.t(.rateApp))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("Rate Dark Aura Panel — Green Rabbit")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(AuraColors.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AuraColors.textTertiary)
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.05, green: 0.08, blue: 0.06).opacity(0.9))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.05), lineWidth: 0.6))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func handlePowerTap() {
        if settings.isPoweredOn {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { settings.isPoweredOn = false }
            settings.currentSession.isActive = false
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            settings.saveSettings()
            return
        }
        guard settings.hasAnyFeatureEnabled else {
            withAnimation { showAlert = true }
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { settings.isPoweredOn = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        settings.saveSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { selectedTab = .training }
        }
    }

    private func handleFeatureToggle(_ row: ModuleRow, newValue: Bool, isLocked: Bool) {
        guard !isLocked else { showPaywall = true; UIImpactFeedbackGenerator(style: .light).impactOccurred(); return }
        let apply = { row.isOn.wrappedValue = newValue; settings.saveSettings() }
        if let p = row.rewarded, newValue {
            AdsService.shared.presentRewardedIfAvailable(for: p, rewardAction: apply, fallbackAction: apply)
        } else {
            apply()
            AdsService.shared.registerInteraction(for: .homeAllFeatures)
        }
    }
}

// MARK: - Module Row Model
private struct ModuleRow: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let sub: String
    var isOn: Binding<Bool>
    var isProOnly: Bool = false
    var rewarded: AdsService.Placement? = nil
}

// MARK: - AuraArmToggle
// Unique military-style ARM / DISARM switch replacing the standard toggle.
private struct AuraArmToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) { isOn.toggle() }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                // Background capsule
                Capsule()
                    .fill(isOn
                        ? AuraColors.accent.opacity(0.18)
                        : Color.white.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(isOn ? AuraColors.accent.opacity(0.6) : Color.white.opacity(0.12), lineWidth: 0.9)
                    )

                HStack(spacing: 0) {
                    if isOn { Spacer() }

                    // Sliding pill
                    ZStack {
                        Capsule()
                            .fill(isOn ? AuraColors.accent : Color.white.opacity(0.12))
                            .shadow(color: isOn ? AuraColors.accentGlow.opacity(0.6) : .clear, radius: 4)
                        Text(isOn ? "ARM" : "OFF")
                            .font(.system(size: 7, weight: .heavy, design: .monospaced))
                            .foregroundColor(isOn ? .black : AuraColors.textTertiary)
                            .tracking(0.5)
                    }
                    .frame(width: 36, height: 20)

                    if !isOn { Spacer() }
                }
                .padding(3)

                // Status dot
                if isOn {
                    HStack {
                        Circle()
                            .fill(AuraColors.accent)
                            .frame(width: 4, height: 4)
                            .shadow(color: AuraColors.accentGlow, radius: 3)
                            .padding(.leading, 7)
                        Spacer()
                    }
                }
            }
            .frame(width: 72, height: 28)
        }
        .buttonStyle(.plain)
    }
}
