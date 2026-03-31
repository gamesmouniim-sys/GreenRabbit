import SwiftUI

struct DeviceInfosView: View {
    @EnvironmentObject var rc: RevenueCatService
    @StateObject private var deviceService = DeviceInfoService()
    @State private var sensiPreset  : DeviceSensiPreset? = nil
    @State private var scanDone     = false
    @State private var scanLine     : CGFloat = 0
    @State private var showPaywall  = false

    var body: some View {
        ZStack {
            // Terminal background
            Color(red: 0.02, green: 0.04, blue: 0.02).ignoresSafeArea()
            terminalGrid

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    scanHeader
                    if let info = deviceService.deviceInfo {
                        deviceBadge(info: info)
                        systemReadout(info: info)
                        displayPanel(info: info)
                        networkPanel
                        sensiButton
                    } else {
                        bootingView
                    }
                    Spacer(minLength: 120)
                }
            }
        }
        .onAppear {
            deviceService.fetchDeviceInfo()
            deviceService.estimatePing()
            withAnimation(.easeInOut(duration: 1.6)) { scanLine = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeOut(duration: 0.3)) { scanDone = true }
            }
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView().environmentObject(rc)
        }
        .sheet(item: $sensiPreset) { preset in
            DeviceSensiSheet(preset: preset)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Terminal grid
    private var terminalGrid: some View {
        Canvas { ctx, sz in
            let col = Color(red: 0.05, green: 0.95, blue: 0.35).opacity(0.03)
            var x: CGFloat = 0
            while x <= sz.width  { var p = Path(); p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: sz.height)); ctx.stroke(p, with: .color(col), lineWidth: 0.4); x += 36 }
            var y: CGFloat = 0
            while y <= sz.height { var p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: sz.width, y: y)); ctx.stroke(p, with: .color(col), lineWidth: 0.4); y += 36 }
        }
        .ignoresSafeArea()
    }

    // MARK: - Scan header
    private var scanHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AuraColors.accentGradient)
                    .frame(width: 3, height: 22)
                    .shadow(color: AuraColors.accentGlow, radius: 5)
                Text("DEVICE SCAN")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(3)
                Spacer()
                if !rc.isPro {
                    AuraPremiumButton {
                        showPaywall = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
                // Scan status chip
                HStack(spacing: 5) {
                    Circle()
                        .fill(scanDone ? AuraColors.accent : AuraColors.yellowWarning)
                        .frame(width: 5, height: 5)
                        .shadow(color: scanDone ? AuraColors.accentGlow : AuraColors.yellowWarning, radius: 3)
                    Text(scanDone ? "COMPLETE" : "SCANNING")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundColor(scanDone ? AuraColors.accent : AuraColors.yellowWarning)
                        .tracking(1)
                }
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(scanDone ? AuraColors.accent.opacity(0.1) : AuraColors.yellowWarning.opacity(0.1))
                        .overlay(Capsule().stroke(scanDone ? AuraColors.accent.opacity(0.35) : AuraColors.yellowWarning.opacity(0.35), lineWidth: 0.7))
                )
            }

            // Scan progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.05))
                    Capsule()
                        .fill(AuraColors.accentGradient)
                        .frame(width: geo.size.width * scanLine)
                        .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 4)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 18)
    }

    // MARK: - Device badge
    private func deviceBadge(info: DeviceInfo) -> some View {
        HStack(spacing: 14) {
            // Phone silhouette
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AuraColors.accent.opacity(0.1))
                    .frame(width: 52, height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AuraColors.accent.opacity(0.35), lineWidth: 1))
                Image(systemName: "iphone")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AuraColors.accent)
                    .shadow(color: AuraColors.accentGlow, radius: 6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(info.model)
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    termChip("iOS \(info.systemVersion)", color: AuraColors.accentSecondary)
                    termChip(info.language.uppercased(), color: AuraColors.textSecondary)
                }
            }
            Spacer()

            // Battery gauge
            batteryGauge(level: info.batteryLevel, state: info.batteryState)
        }
        .padding(16)
        .background(termCard)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - System readout
    private func systemReadout(info: DeviceInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("SYSTEM DIAGNOSTICS")
            VStack(spacing: 0) {
                termRow(icon: "internaldrive.fill",  label: "STORAGE",  value: "\(info.storageUsed) / \(info.storageTotal)", accent: AuraColors.accent)
                Divider().background(Color.white.opacity(0.04))
                termRow(icon: "memorychip",          label: "MEMORY",   value: info.memoryEstimate, accent: AuraColors.accentSecondary)
                Divider().background(Color.white.opacity(0.04))
                let fps: String = {
                    let s = UIScreen.main.maximumFramesPerSecond
                    return "\(s) Hz"
                }()
                termRow(icon: "gauge.high",          label: "REFRESH",  value: fps, accent: AuraColors.yellowWarning)
                Divider().background(Color.white.opacity(0.04))
                termRow(icon: "cpu",                 label: "ARCH",     value: "ARM64", accent: Color(red: 0.7, green: 0.5, blue: 1.0))
            }
            .background(termCard)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Display panel
    private func displayPanel(info: DeviceInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("DISPLAY MATRIX")
            VStack(spacing: 0) {
                termRow(icon: "rectangle.fill",      label: "RESOLUTION", value: "\(Int(info.screenBounds.width * info.screenScale))×\(Int(info.screenBounds.height * info.screenScale))px", accent: AuraColors.accent)
                Divider().background(Color.white.opacity(0.04))
                termRow(icon: "viewfinder",          label: "LOGICAL",    value: "\(Int(info.screenBounds.width))×\(Int(info.screenBounds.height)) pt", accent: AuraColors.accentSecondary)
                Divider().background(Color.white.opacity(0.04))
                termRow(icon: "circle.grid.cross",   label: "SCALE",      value: "@\(Int(info.screenScale))x", accent: AuraColors.yellowWarning)
                Divider().background(Color.white.opacity(0.04))
                termRow(icon: "rectangle.dashed",    label: "EFF. DPI",   value: "~\(Int(info.screenScale * 160)) dpi", accent: Color(red: 0.7, green: 0.5, blue: 1.0))
            }
            .background(termCard)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Network panel
    private var networkPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("NETWORK STATUS")
            VStack(spacing: 0) {
                termRow(icon: "wifi",   label: "CONNECTION", value: deviceService.networkType,   accent: AuraColors.accent)
                Divider().background(Color.white.opacity(0.04))
                termRow(icon: "timer",  label: "PING EST.",  value: deviceService.pingEstimate,  accent: AuraColors.accentSecondary)
            }
            .background(termCard)

            Text("Ping is an estimate measured against a test endpoint.")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)
                .padding(.top, 6)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Sensi button
    private var sensiButton: some View {
        Button {
            let show = {
                sensiPreset = deviceService.getDeviceSensiPreset()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            AdsService.shared.presentRewardedIfAvailable(for: .deviceRecommendedSensi, rewardAction: show, fallbackAction: show)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 15, weight: .semibold))
                VStack(alignment: .leading, spacing: 1) {
                    Text("GET RECOMMENDED SENSI")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .tracking(0.5)
                    Text("Optimized for your device model")
                        .font(.system(size: 9, design: .monospaced))
                        .opacity(0.7)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 18).padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AuraColors.accentGradient)
                    .shadow(color: AuraColors.accentGlow.opacity(0.45), radius: 14)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - Booting view
    private var bootingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AuraColors.accent)
                .scaleEffect(1.2)
            Text("INITIALIZING DEVICE SCAN...")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(AuraColors.accent)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Sub-components

    private var termCard: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(red: 0.04, green: 0.09, blue: 0.05).opacity(0.95))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AuraColors.accent.opacity(0.12), lineWidth: 0.8))
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack(spacing: 6) {
            Rectangle().fill(AuraColors.accent).frame(width: 2, height: 12).cornerRadius(1)
            Text(text)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(AuraColors.accent)
                .tracking(2)
        }
        .padding(.bottom, 8)
    }

    private func termRow(icon: String, label: String, value: String, accent: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(accent)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)
                .tracking(1)
                .frame(width: 84, alignment: .leading)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(accent)
                .shadow(color: accent.opacity(0.4), radius: 3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func termChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .heavy, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)).overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.7)))
    }

    private func batteryGauge(level: Float, state: String) -> some View {
        let pct  = Int(level * 100)
        let col  : Color = level > 0.5 ? AuraColors.accent : (level > 0.2 ? AuraColors.yellowWarning : AuraColors.redChip)
        return VStack(spacing: 4) {
            ZStack {
                // Battery shell
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(col.opacity(0.5), lineWidth: 1.2)
                    .frame(width: 36, height: 18)
                // Fill
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        .fill(col.opacity(0.75))
                        .frame(width: max(4, 32 * CGFloat(level)), height: 12)
                    Spacer()
                }
                .frame(width: 32, height: 12)
                .clipped()
            }
            Text("\(pct)%")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(col)
            Text(state)
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)
        }
    }
}

// MARK: - Device Sensi Sheet (kept from original)
struct DeviceSensiSheet: View {
    let preset: DeviceSensiPreset
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    @State private var rowsAppeared = false

    private var rows: [(String, String, Int, Color)] {[
        ("gauge.high",       "VICE DPI",  preset.viceDPI,    Color(red: 0.4, green: 0.8, blue: 1.0)),
        ("hand.raised.fill", "GENERAL",   preset.general,    AuraColors.accent),
        ("scope",            "RED DOT",   preset.redDot,     Color(red: 1.0, green: 0.35, blue: 0.35)),
        ("2.circle.fill",    "2X SCOPE",  preset.twoXScope,  Color(red: 1.0, green: 0.65, blue: 0.2)),
        ("4.circle.fill",    "4X SCOPE",  preset.fourXScope, Color(red: 1.0, green: 0.85, blue: 0.1)),
        ("eye.fill",         "SNIPER",    preset.sniper,     Color(red: 0.7, green: 0.5, blue: 1.0)),
        ("dpad.fill",        "FREE LOOK", preset.freeLook,   Color(red: 0.5, green: 0.9, blue: 0.6)),
    ]}

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [AuraColors.accent.opacity(0.12), .clear], center: .top, startRadius: 0, endRadius: 320).ignoresSafeArea()
            VStack(spacing: 0) {
                sheetHeader
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        deviceBadge
                        sensiGrid
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 110)
                }
            }
            VStack { Spacer(); bottomBar }
        }
        .preferredColorScheme(.dark)
        .onAppear { withAnimation(.easeOut(duration: 0.5).delay(0.15)) { rowsAppeared = true } }
    }

    private var sheetHeader: some View {
        Group {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars").font(.system(size: 13, weight: .bold)).foregroundColor(AuraColors.accent)
                    Text("RECOMMENDED SENSI").font(.system(size: 12, weight: .heavy, design: .monospaced)).foregroundColor(.white).tracking(1.2)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundColor(AuraColors.textTertiary)
                        .padding(8).background(Circle().fill(Color.white.opacity(0.06)))
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 18).padding(.vertical, 14).background(Color.black.opacity(0.6))
            Divider().background(Color.white.opacity(0.06))
        }
    }

    private var deviceBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "iphone").font(.system(size: 16, weight: .semibold)).foregroundColor(AuraColors.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.deviceName).font(.system(size: 16, weight: .black, design: .rounded)).foregroundColor(.white)
                Text("Free Fire Optimized Settings").font(.system(size: 11)).foregroundColor(AuraColors.textTertiary)
            }
            Spacer()
            VStack(spacing: 1) {
                Text("\(preset.viceDPI)").font(.system(size: 18, weight: .black, design: .monospaced)).foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
                Text("DPI").font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.75)).tracking(1)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.12)).overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.3), lineWidth: 1)))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.04)).overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1)))
        .opacity(rowsAppeared ? 1 : 0).offset(y: rowsAppeared ? 0 : 12)
        .animation(.easeOut(duration: 0.4), value: rowsAppeared)
    }

    private var sensiGrid: some View {
        VStack(spacing: 10) {
            ForEach(Array(rows.dropFirst().enumerated()), id: \.offset) { idx, row in
                sensiRow(icon: row.0, label: row.1, value: row.2, accent: row.3, delay: Double(idx) * 0.06)
            }
        }
    }

    private func sensiRow(icon: String, label: String, value: Int, accent: Color, delay: Double) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(accent.opacity(0.14)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundColor(accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundColor(AuraColors.textTertiary).tracking(1)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.06))
                        Capsule().fill(LinearGradient(colors: [accent.opacity(0.9), accent.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * min(CGFloat(value) / 200.0, 1.0))
                    }
                }
                .frame(height: 5)
            }
            Spacer()
            Text("\(value)").font(.system(size: 22, weight: .black, design: .monospaced)).foregroundColor(accent).frame(minWidth: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.03)).overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(accent.opacity(0.12), lineWidth: 1)))
        .opacity(rowsAppeared ? 1 : 0).offset(y: rowsAppeared ? 0 : 14)
        .animation(.easeOut(duration: 0.4).delay(delay + 0.1), value: rowsAppeared)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                UIPasteboard.general.string = preset.shareText
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation { copied = false } }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc").font(.system(size: 14, weight: .semibold))
                    Text(copied ? "COPIED!" : "COPY ALL").font(.system(size: 13, weight: .heavy, design: .monospaced)).tracking(0.5)
                }
                .foregroundColor(copied ? Color(red: 0.3, green: 0.9, blue: 0.55) : .white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(copied ? Color(red: 0.3, green: 0.9, blue: 0.55).opacity(0.14) : Color.white.opacity(0.06)).overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(copied ? Color(red: 0.3, green: 0.9, blue: 0.55).opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)))
            }.buttonStyle(.plain)

            ShareLink(item: preset.shareText) {
                HStack(spacing: 7) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 14, weight: .semibold))
                    Text("SHARE").font(.system(size: 13, weight: .heavy, design: .monospaced)).tracking(0.5)
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AuraColors.accent).shadow(color: AuraColors.accentGlow.opacity(0.4), radius: 10))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 20).padding(.bottom, 28).padding(.top, 12)
        .background(LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.92)], startPoint: .top, endPoint: .bottom).ignoresSafeArea(edges: .bottom))
    }
}
