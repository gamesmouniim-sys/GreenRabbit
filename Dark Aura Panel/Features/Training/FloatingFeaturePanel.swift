import SwiftUI

// MARK: - Group model (mirrors Home screen feature groups)
private struct FeatureGroup {
    let title: String
    let icon: String
    let items: [(name: String, sfIcon: String)]
}

struct FloatingFeaturePanel: View {
    @ObservedObject var settings: AppSettings
    @EnvironmentObject var lm: LocalizationManager
    @EnvironmentObject private var ads: AdsService
    let onClose: () -> Void

    @State private var expandedFeature: String?

    // Groups match exact order/names from HomeView — titles come from LocalizationManager
    private var activeGroups: [FeatureGroup] {
        var groups: [FeatureGroup] = []

        // ── SENSI SETUP ──
        var sensiItems: [(String, String)] = []
        if settings.phoneSensiEnabled  { sensiItems.append((lm.t(.phoneSensi), "speedometer")) }
        if settings.hudMobileEnabled   { sensiItems.append((lm.t(.hudMobile),  "rectangle.split.3x3")) }
        if settings.phoneDPIEnabled    { sensiItems.append((lm.t(.phoneDPI),   "viewfinder")) }
        if settings.gunSensiEnabled    { sensiItems.append((lm.t(.gunSensi),   "scope")) }
        if !sensiItems.isEmpty {
            groups.append(FeatureGroup(title: lm.t(.sensiSetupGroup), icon: "speedometer", items: sensiItems))
        }

        // ── AIM CROSS ──
        var aimItems: [(String, String)] = []
        if settings.basicAimEnabled    { aimItems.append((lm.t(.basicAim),    "plus.viewfinder")) }
        if settings.aimSetupEnabled    { aimItems.append((lm.t(.aimSetup),    "slider.horizontal.below.rectangle")) }
        if settings.aimColorsEnabled   { aimItems.append((lm.t(.aimColors),   "paintpalette.fill")) }
        if settings.aimSettingsEnabled { aimItems.append((lm.t(.aimSettings), "gearshape.fill")) }
        if !aimItems.isEmpty {
            groups.append(FeatureGroup(title: lm.t(.aimCrossGroup), icon: "plus.viewfinder", items: aimItems))
        }

        // ── TRICK KEY ──
        var trickItems: [(String, String)] = []
        if settings.ballPaintEnabled     { trickItems.append((lm.t(.ballPaint),     "paintbrush.fill")) }
        if settings.ballSetupEnabled     { trickItems.append((lm.t(.ballSetup),     "circle.dashed")) }
        if settings.invisibleBallEnabled { trickItems.append((lm.t(.invisibleBall), "eye.slash.fill")) }
        if !trickItems.isEmpty {
            groups.append(FeatureGroup(title: lm.t(.trickKeyGroup), icon: "wand.and.stars", items: trickItems))
        }

        // ── DEVICE INFO ──
        var overlayItems: [(String, String)] = []
        if settings.overlaySettings.showFPS         { overlayItems.append((lm.t(.fps),         "gauge.high")) }
        if settings.overlaySettings.showBatteryTemp { overlayItems.append((lm.t(.batteryTemp),  "thermometer.medium")) }
        if settings.overlaySettings.showRAM         { overlayItems.append((lm.t(.ram),          "memorychip")) }
        if settings.overlaySettings.showPing        { overlayItems.append((lm.t(.ping),         "wifi")) }
        if settings.overlaySettings.showDPI         { overlayItems.append((lm.t(.deviceDPI),    "rectangle.dashed")) }
        if !overlayItems.isEmpty {
            groups.append(FeatureGroup(title: lm.t(.deviceInfoGroup), icon: "info.circle", items: overlayItems))
        }

        return groups
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header ──
            HStack {
                Text(lm.t(.activeFeatures))
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(AuraColors.accent)
                    .tracking(1)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AuraColors.textTertiary)
                }
                .simultaneousGesture(
                    TapGesture().onEnded {
                        ads.registerInteraction(for: .uiInteraction)
                    }
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            if activeGroups.isEmpty {
                Text(lm.t(.noFeaturesActive))
                    .font(.system(size: 11))
                    .foregroundColor(AuraColors.textTertiary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(activeGroups, id: \.title) { group in
                            groupSection(group)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 10)
                }
                .frame(maxHeight: 360)
            }
        }
        .frame(width: 248)
        .auraGlass(cornerRadius: 16, borderOpacity: 0.15)
    }

    // MARK: – Group section
    @ViewBuilder
    private func groupSection(_ group: FeatureGroup) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Group header chip
            HStack(spacing: 4) {
                Image(systemName: group.icon)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(AuraColors.accent)
                Text(group.title)
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(AuraColors.accent)
                    .tracking(0.8)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(AuraColors.accent.opacity(0.12))
            )
            .padding(.leading, 2)
            .padding(.bottom, 2)

            // Items inside this group
            ForEach(group.items, id: \.name) { item in
                featureItem(name: item.name, icon: item.sfIcon)
            }
        }
    }

    // MARK: – Feature row
    @ViewBuilder
    private func featureItem(name: String, icon: String) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    expandedFeature = expandedFeature == name ? nil : name
                }
                ads.registerInteraction(for: .uiInteraction)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AuraColors.accent)
                        .frame(width: 18)

                    Text(name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: expandedFeature == name ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AuraColors.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(expandedFeature == name ? Color.white.opacity(0.06) : .clear)
                )
            }
            .buttonStyle(.plain)

            if expandedFeature == name {
                featureControls(for: name)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: – Inline controls per feature
    @ViewBuilder
    private func featureControls(for name: String) -> some View {
        switch name {
        case "Mobile Sensi", "Sensi Móvel", "Sensi Móvil", "سنسي موبايل":
            miniSlider(label: "Sensitivity", value: $settings.sensitivitySettings.phoneSensi, range: 1...100)
        case "Gun Sensi", "Sensi da Arma", "Sensi del Arma", "حساسية السلاح":
            miniSlider(label: "ADS Multiplier", value: $settings.sensitivitySettings.adsMultiplier, range: 0.1...2.0)
        case "Expert Aim", "Mira Expert", "تصويب خبير":
            VStack(spacing: 6) {
                miniSlider(label: "Size",      value: $settings.crosshairSettings.size,      range: 2...20)
                miniSlider(label: "Thickness", value: $settings.crosshairSettings.thickness, range: 1...6)
                miniSlider(label: "Gap",       value: $settings.crosshairSettings.gap,       range: 0...12)
                miniSlider(label: "Opacity",   value: $settings.crosshairSettings.opacity,   range: 0.1...1.0)
            }
        case "Aim Colors", "Cores da Mira", "Colores de Mira", "ألوان التصويب":
            colorPresets(for: .crosshair)
        case "Ball Color", "Cor da Bola", "Color de Bala", "لون الكرة":
            colorPresets(for: .projectile)
        case "Ball Config", "Config. Bola", "Config. Bala", "ضبط الكرة":
            VStack(spacing: 6) {
                Toggle("Trail", isOn: trackedBinding($settings.projectileSettings.trailEnabled))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .tint(AuraColors.accent)
                miniSlider(label: "Trail Length", value: $settings.projectileSettings.trailLength, range: 0.1...1.0)
            }
        case "Hide Ball", "Ocultar Bola", "إخفاء الكرة":
            Toggle("Invisible Mode", isOn: trackedBinding($settings.projectileSettings.invisible))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .tint(AuraColors.accent)
        case "Mobile DPI", "DPI Móvel", "DPI Móvil", "DPI موبايل":
            HStack(spacing: 4) {
                ForEach(RenderScalePreset.allCases) { preset in
                    Button {
                        settings.renderScale = preset
                        ads.registerInteraction(for: .uiInteraction)
                    } label: {
                        Text(preset.label)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(settings.renderScale == preset ? .white : AuraColors.textTertiary)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(
                                Capsule().fill(settings.renderScale == preset
                                    ? AuraColors.accent : Color.white.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        default:
            HStack(spacing: 4) {
                Circle().fill(AuraColors.greenPositive).frame(width: 6, height: 6)
                Text("Active")
                    .font(.system(size: 10))
                    .foregroundColor(AuraColors.greenPositive)
            }
        }
    }

    // MARK: – Color pickers
    private enum ColorTarget { case crosshair, projectile }

    private func colorPresets(for target: ColorTarget) -> some View {
        let palette: [CodableColor] = [.red, .cyan, .green, .yellow, .white, .orange]
        return HStack(spacing: 6) {
            ForEach(palette, id: \.r) { c in
                let isSelected = target == .crosshair
                    ? settings.crosshairSettings.color == c
                    : settings.projectileSettings.color == c
                Circle()
                    .fill(c.color)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color.white.opacity(isSelected ? 0.8 : 0), lineWidth: 2))
                    .onTapGesture {
                        if target == .crosshair { settings.crosshairSettings.color = c }
                        else { settings.projectileSettings.color = c }
                        ads.registerInteraction(for: .uiInteraction)
                    }
            }
        }
    }

    // MARK: – Mini slider
    private func miniSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(AuraColors.textTertiary)
                Spacer()
                Text(String(format: "%.1f", value.wrappedValue))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(AuraColors.accent)
            }
            Slider(
                value: value,
                in: range,
                onEditingChanged: { isEditing in
                    if isEditing {
                        ads.registerInteraction(for: .uiInteraction)
                    }
                }
            )
                .tint(AuraColors.accent)
                .frame(height: 16)
        }
    }

    private func trackedBinding(_ binding: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { binding.wrappedValue },
            set: { newValue in
                binding.wrappedValue = newValue
                ads.registerInteraction(for: .uiInteraction)
            }
        )
    }
}
