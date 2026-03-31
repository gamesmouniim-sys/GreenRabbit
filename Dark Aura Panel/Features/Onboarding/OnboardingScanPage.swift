import SwiftUI
import Network
import Combine

// MARK: – Scan Page  (Radar / Sonar aesthetic)
// Completely different from previous phone-frame + scanline design.
// – Large circular radar with rotating sweep sector (Canvas-driven)
// – Ping dots appear at random positions during sweep
// – After scan: results slide up as terminal data rows
// – Full-screen, no phone mock-up

struct OnboardingScanPage: View {
    @EnvironmentObject var lm: LocalizationManager
    @EnvironmentObject var ads: AdsService
    let onFinish: () -> Void

    // Radar
    @State private var sweepAngle:   Double  = -90       // -90 = top
    @State private var scanProgress: Double  = 0
    @State private var pingDots:     [PingDot] = []
    @State private var radarPulse:   Bool    = false

    // Phases
    @State private var scanPhase:    ScanPhase = .idle
    @State private var sweepTimer:   AnyCancellable?

    // Results
    @State private var deviceRows:   [DeviceRow] = []
    @State private var revealCount:  Int     = 0
    @State private var resultsVis:   Bool    = false
    @State private var headerText:   String  = "INITIATING SCAN"

    private let radarSize:  CGFloat = 220
    private let scanSecs:   Double  = 2.6

    enum ScanPhase { case idle, scanning, done }

    struct PingDot: Identifiable {
        let id    = UUID()
        let angle:  Double    // radians from top
        let radius: CGFloat
        var age:    Double    = 0   // 0…1
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            hexBackground

            VStack(spacing: 0) {
                Spacer()

                // ── Phase label ──────────────────────────────────
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(scanPhase == .done
                                  ? AuraColors.greenPositive
                                  : AuraColors.accent)
                            .frame(width: 6, height: 6)
                            .shadow(color: scanPhase == .done
                                    ? AuraColors.greenPositive.opacity(0.8)
                                    : AuraColors.accentGlow,
                                    radius: 5)
                        Text(headerText)
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(scanPhase == .done
                                             ? AuraColors.greenPositive
                                             : AuraColors.textTertiary)
                            .tracking(2.5)
                            .animation(.easeInOut(duration: 0.4), value: headerText)
                    }

                    Text(scanPhase == .scanning
                         ? String(format: "%.0f%%", scanProgress * 100)
                         : scanPhase == .done
                             ? "DEVICE IDENTIFIED"
                             : "STARTING...")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(scanPhase == .done ? AuraColors.greenPositive : .white)
                        .animation(.easeInOut(duration: 0.35), value: scanPhase)
                }

                Spacer().frame(height: 28)

                // ── Radar circle ─────────────────────────────────
                ZStack {
                    radarCanvas
                    pingLayer
                }
                .frame(width: radarSize, height: radarSize)
                .scaleEffect(radarPulse ? 1.015 : 1.0)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                           value: radarPulse)

                Spacer().frame(height: 24)

                // ── Progress bar (scanning only) ──────────────────
                if scanPhase == .scanning {
                    progressBar
                        .padding(.horizontal, 48)
                        .transition(.opacity)
                }

                // ── Results ───────────────────────────────────────
                if scanPhase == .done {
                    resultSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Spacer().frame(height: 32)
                }

                Spacer()
            }
        }
        .onAppear {
            deviceRows = collectDeviceInfo()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startScan() }
        }
        .onDisappear { sweepTimer?.cancel() }
    }

    // MARK: – Radar canvas
    private var radarCanvas: some View {
        Canvas { ctx, size in
            let cx   = size.width  / 2
            let cy   = size.height / 2
            let maxR = size.width  / 2 - 1
            let cpt  = CGPoint(x: cx, y: cy)

            // ── Concentric circles ──
            for i in 1...4 {
                let r = CGFloat(i) * maxR / 4
                let alpha = 0.08 + Double(i) * 0.02
                ctx.stroke(
                    Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r*2, height: r*2)),
                    with: .color(AuraColors.accent.opacity(alpha)),
                    lineWidth: 0.7
                )
            }

            // ── Cross-hairs ──
            var h = Path()
            h.move(to: CGPoint(x: cx - maxR, y: cy))
            h.addLine(to: CGPoint(x: cx + maxR, y: cy))
            ctx.stroke(h, with: .color(AuraColors.accent.opacity(0.10)), lineWidth: 0.6)
            var v = Path()
            v.move(to: CGPoint(x: cx, y: cy - maxR))
            v.addLine(to: CGPoint(x: cx, y: cy + maxR))
            ctx.stroke(v, with: .color(AuraColors.accent.opacity(0.10)), lineWidth: 0.6)

            // ── Diagonal guides ──
            for deg in [45.0, 135.0] {
                let rad = deg * .pi / 180
                var d = Path()
                d.move(to: CGPoint(x: cx - maxR * cos(rad), y: cy - maxR * sin(rad)))
                d.addLine(to: CGPoint(x: cx + maxR * cos(rad), y: cy + maxR * sin(rad)))
                ctx.stroke(d, with: .color(AuraColors.accent.opacity(0.06)), lineWidth: 0.4)
            }

            // ── Sweep sector ──
            if scanPhase == .scanning || scanPhase == .done {
                let startRad = -Double.pi / 2
                let endRad   = (sweepAngle * .pi / 180)

                var sector = Path()
                sector.move(to: cpt)
                sector.addArc(center: cpt, radius: maxR,
                              startAngle: .radians(startRad),
                              endAngle:   .radians(endRad),
                              clockwise: false)
                sector.closeSubpath()
                ctx.fill(sector, with: .color(AuraColors.accent.opacity(0.06)))

                // Leading edge glow line
                let ex = cx + maxR * cos(endRad)
                let ey = cy + maxR * sin(endRad)
                var edge = Path()
                edge.move(to: cpt)
                edge.addLine(to: CGPoint(x: ex, y: ey))
                ctx.stroke(edge, with: .color(AuraColors.accent.opacity(0.75)), lineWidth: 2)

                // Bright tip dot on leading edge
                ctx.fill(
                    Path(ellipseIn: CGRect(x: ex - 3.5, y: ey - 3.5, width: 7, height: 7)),
                    with: .color(AuraColors.accent)
                )
            }

            // ── Done: full bright ring ──
            if scanPhase == .done {
                ctx.stroke(
                    Path(ellipseIn: CGRect(x: cx - maxR, y: cy - maxR,
                                           width: maxR * 2, height: maxR * 2)),
                    with: .color(AuraColors.greenPositive.opacity(0.55)),
                    lineWidth: 1.5
                )
            }

            // ── Outer ring ──
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - maxR, y: cy - maxR,
                                       width: maxR * 2, height: maxR * 2)),
                with: .color(AuraColors.accent.opacity(0.35)),
                lineWidth: 1.5
            )

            // ── Center dot ──
            ctx.fill(
                Path(ellipseIn: CGRect(x: cx - 3, y: cy - 3, width: 6, height: 6)),
                with: .color(AuraColors.accent)
            )
        }
    }

    // MARK: – Ping dots overlay
    private var pingLayer: some View {
        ZStack {
            ForEach(pingDots) { dot in
                Circle()
                    .fill(AuraColors.accent)
                    .frame(width: 5, height: 5)
                    .shadow(color: AuraColors.accentGlow.opacity(0.9), radius: 4)
                    .offset(
                        x: dot.radius * cos(dot.angle),
                        y: dot.radius * sin(dot.angle)
                    )
                    .opacity(1 - dot.age)
            }
        }
        .frame(width: radarSize, height: radarSize)
    }

    // MARK: – Progress bar
    private var progressBar: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 3)
                Capsule()
                    .fill(AuraColors.accentGradient)
                    .frame(width: max(6, CGFloat(scanProgress) *
                                     (UIScreen.main.bounds.width - 96)),
                           height: 3)
                    .animation(.linear(duration: 0.08), value: scanProgress)
            }
        }
    }

    // MARK: – Results section
    private var resultSection: some View {
        VStack(spacing: 16) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 7) {
                    ForEach(Array(deviceRows.prefix(revealCount).enumerated()),
                            id: \.offset) { _, row in
                        termRow(row)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 220)

            if revealCount >= deviceRows.count {
                continueButton
                    .padding(.horizontal, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: – Terminal data row
    private func termRow(_ row: DeviceRow) -> some View {
        HStack(spacing: 12) {
            // Icon chip
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AuraColors.accent.opacity(0.11))
                    .frame(width: 30, height: 30)
                Image(systemName: row.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AuraColors.accent)
            }

            // Label
            Text(row.label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)

            Spacer()

            // Value
            Text(row.value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AuraColors.accent.opacity(0.1), lineWidth: 0.7)
                )
        )
    }

    // MARK: – Continue button
    private var continueButton: some View {
        Button {
            Task {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                await ads.requestTrackingPermissionBeforeProceeding()
                await MainActor.run { onFinish() }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Text("LAUNCH PANEL")
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                    .tracking(1.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(
                            colors: [AuraColors.greenPositive, AuraColors.greenPositive.opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.white.opacity(0.14), .clear],
                            startPoint: .top, endPoint: .center
                        ))
                        .padding(1)
                }
            )
            .shadow(color: AuraColors.greenPositive.opacity(0.45), radius: 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: – Background
    private var hexBackground: some View {
        Canvas { ctx, size in
            let r: CGFloat = 20
            let col = Color(red: 0.05, green: 0.95, blue: 0.35).opacity(0.035)
            let cols = Int(size.width  / (r * 1.73)) + 2
            let rows = Int(size.height / (r * 1.50)) + 2
            for row in 0...rows {
                for c in 0...cols {
                    let cx = CGFloat(c) * r * 1.73 + (row % 2 == 0 ? 0 : r * 0.865)
                    let cy = CGFloat(row) * r * 1.50
                    var p = Path()
                    for i in 0..<6 {
                        let ang = CGFloat(i) * .pi / 3 - .pi / 6
                        let pt  = CGPoint(x: cx + (r - 1) * cos(ang),
                                          y: cy + (r - 1) * sin(ang))
                        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                    }
                    p.closeSubpath()
                    ctx.stroke(p, with: .color(col), lineWidth: 0.4)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: – Scan logic
    private func startScan() {
        scanPhase  = .scanning
        sweepAngle = -90
        radarPulse = true

        let degsPerTick = 360.0 / (scanSecs * 30.0)

        sweepTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                sweepAngle   += degsPerTick
                scanProgress  = (sweepAngle + 90) / 360.0

                // Random ping dot
                let ticksSinceStart = Int((sweepAngle + 90) / degsPerTick)
                if ticksSinceStart % 5 == 0 {
                    let ang    = Double.random(in: 0...(2 * .pi)) - .pi / 2
                    let radius = CGFloat.random(in: 28...(radarSize / 2 - 10))
                    pingDots.append(PingDot(angle: ang, radius: radius))
                    if pingDots.count > 14 { pingDots.removeFirst() }
                }
                // Age dots
                for i in pingDots.indices { pingDots[i].age += 0.04 }
                pingDots.removeAll { $0.age >= 1 }

                if sweepAngle >= 270 {
                    sweepTimer?.cancel()
                    finishScan()
                }
            }
    }

    private func finishScan() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            scanPhase  = .done
            headerText = "SCAN COMPLETE"
        }

        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                resultsVis = true
            }
            for i in 0..<deviceRows.count {
                try? await Task.sleep(nanoseconds: 160_000_000)
                withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                    revealCount = i + 1
                }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
    }

    // MARK: – Device data
    private func collectDeviceInfo() -> [DeviceRow] {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        let screenBounds: CGRect
        let screenScale:  CGFloat
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            screenBounds = scene.screen.bounds
            screenScale  = scene.screen.scale
        } else {
            screenBounds = CGRect(x: 0, y: 0, width: 390, height: 844)
            screenScale  = 3.0
        }
        let displayStr = "\(Int(screenBounds.width))×\(Int(screenBounds.height)) @\(Int(screenScale))x"

        var sysInfo = utsname()
        uname(&sysInfo)
        let machineID = withUnsafePointer(to: &sysInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? device.model
            }
        }
        let modelMap: [String: String] = [
            "iPhone17,1": "iPhone 16 Pro",   "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",        "iPhone17,4": "iPhone 16 Plus",
            "iPhone16,1": "iPhone 15 Pro",    "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone15,4": "iPhone 15",        "iPhone15,5": "iPhone 15 Plus",
        ]
        let modelName = modelMap[machineID] ?? device.model

        let mem    = ProcessInfo.processInfo.physicalMemory
        let memStr = String(format: "%.0f GB", Double(mem) / 1_073_741_824)

        let lang   = Locale.current.language.languageCode?.identifier.uppercased() ?? "EN"
        let region = Locale.current.region?.identifier ?? ""
        let langStr = region.isEmpty ? lang : "\(lang) – \(region)"

        let monitor = NWPathMonitor()
        var netType = "Checking…"
        monitor.pathUpdateHandler = { path in
            if      path.usesInterfaceType(.wifi)     { netType = "Wi-Fi" }
            else if path.usesInterfaceType(.cellular) { netType = "Cellular" }
            else if path.status == .satisfied         { netType = "Connected" }
            else                                      { netType = "Offline" }
        }
        monitor.start(queue: DispatchQueue(label: "onboarding.net"))
        Thread.sleep(forTimeInterval: 0.05)
        monitor.cancel()

        return [
            DeviceRow(icon: "iphone",                label: "Model",    value: modelName),
            DeviceRow(icon: "gearshape",              label: "iOS",      value: "iOS \(device.systemVersion)"),
            DeviceRow(icon: "rectangle.on.rectangle", label: "Display",  value: displayStr),
            DeviceRow(icon: "memorychip",             label: "RAM",      value: memStr),
            DeviceRow(icon: "globe",                  label: "Language", value: langStr),
            DeviceRow(icon: "wifi",                   label: "Network",  value: netType),
        ]
    }
}

// MARK: – DeviceRow model
private struct DeviceRow {
    let icon:  String
    let label: String
    let value: String
}
