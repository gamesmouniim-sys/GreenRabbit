import SwiftUI
import Combine
import Network

struct DeviceInfo {
    let model: String
    let systemVersion: String
    let language: String
    let screenBounds: CGRect
    let screenScale: CGFloat
    let batteryLevel: Float
    let batteryState: String
    let storageTotal: String
    let storageUsed: String
    let memoryEstimate: String
    let networkType: String
}

@MainActor
final class DeviceInfoService: ObservableObject {
    @Published var deviceInfo: DeviceInfo?
    @Published var pingEstimate: String = "—"
    @Published var isLoadingPing: Bool = false
    @Published var networkType: String = "Unknown"

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "network-monitor")

    init() {
        startNetworkMonitor()
    }

    func fetchDeviceInfo() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        let device = UIDevice.current
        let batteryLevel = device.batteryLevel
        let batteryState: String = {
            switch device.batteryState {
            case .charging: return "Charging"
            case .full:     return "Full"
            case .unplugged: return "Unplugged"
            default:        return "Unknown"
            }
        }()

        // Use key window scene for screen info (iOS 16+ safe)
        let screenBounds: CGRect
        let screenScale: CGFloat
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            screenBounds = scene.screen.bounds
            screenScale  = scene.screen.scale
        } else {
            screenBounds = CGRect(x: 0, y: 0, width: 390, height: 844)
            screenScale  = 3.0
        }

        let (total, used) = storageInfo()
        let memory = ProcessInfo.processInfo.physicalMemory
        let memString = String(format: "%.1f GB", Double(memory) / 1_073_741_824)

        deviceInfo = DeviceInfo(
            model: modelName(),
            systemVersion: device.systemVersion,
            language: Locale.current.language.languageCode?.identifier ?? "en",
            screenBounds: screenBounds,
            screenScale: screenScale,
            batteryLevel: batteryLevel,
            batteryState: batteryState,
            storageTotal: total,
            storageUsed: used,
            memoryEstimate: memString,
            networkType: networkType
        )
    }

    func estimatePing() {
        isLoadingPing = true
        pingEstimate = "..."

        Task { @MainActor in
            let start = CFAbsoluteTimeGetCurrent()
            var request = URLRequest(url: URL(string: "https://www.apple.com")!)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 5

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                let elapsed = CFAbsoluteTimeGetCurrent() - start
                let ms = Int(elapsed * 1000)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    pingEstimate = "\(ms) ms"
                } else {
                    pingEstimate = "~\(ms) ms"
                }
            } catch {
                pingEstimate = "N/A"
            }
            isLoadingPing = false
        }
    }

    // MARK: - Device Sensi Preset

    func getDeviceSensiPreset() -> DeviceSensiPreset {
        let name = modelName()
        return DeviceInfoService.sensiDatabase[name]
            ?? fallbackPreset(modelName: name)
    }

    private func fallbackPreset(modelName: String) -> DeviceSensiPreset {
        // Estimate from screen scale
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            let scale = scene.screen.scale
            if scale >= 3.0 {
                // OLED / high-density
                return DeviceSensiPreset(deviceName: modelName, viceDPI: 460,
                    general: 155, redDot: 140, twoXScope: 125, fourXScope: 110, sniper: 95, freeLook: 15)
            }
        }
        // Standard LCD
        return DeviceSensiPreset(deviceName: modelName, viceDPI: 326,
            general: 95, redDot: 85, twoXScope: 75, fourXScope: 65, sniper: 53, freeLook: 11)
    }

    // MARK: - Sensi Database (loaded from SensiDatabase.json in app bundle)

    static let sensiDatabase: [String: DeviceSensiPreset] = {
        guard
            let url    = Bundle.main.url(forResource: "SensiDatabase", withExtension: "json"),
            let data   = try? Data(contentsOf: url),
            let presets = try? JSONDecoder().decode([DeviceSensiPreset].self, from: data)
        else { return [:] }
        return Dictionary(uniqueKeysWithValues: presets.map { ($0.deviceName, $0) })
    }()

    // MARK: - Legacy presets (keep for backward compat)

    func generateRecommendedSensi() -> [RecommendedSensi] {
        let screenBounds: CGRect
        let scale: CGFloat
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            screenBounds = scene.screen.bounds
            scale = scene.screen.scale
        } else {
            screenBounds = CGRect(x: 0, y: 0, width: 390, height: 844)
            scale = 3.0
        }

        let diagonal = sqrt(pow(screenBounds.width, 2) + pow(screenBounds.height, 2))
        let memory = ProcessInfo.processInfo.physicalMemory
        let isHighEnd = memory > 4_000_000_000

        let baseSensi = diagonal < 850 ? 60.0 : (diagonal < 1000 ? 50.0 : 42.0)
        let scaleFactor = scale >= 3 ? 0.95 : 1.05

        return [
            RecommendedSensi(
                name: "Balanced",
                phoneSensi: (baseSensi * scaleFactor).rounded(),
                adsSensi: (baseSensi * scaleFactor * 0.7).rounded(),
                scopeSensi: (baseSensi * scaleFactor * 0.4).rounded(),
                description: "Well-rounded for all weapon types"
            ),
            RecommendedSensi(
                name: "Aggressive",
                phoneSensi: (baseSensi * scaleFactor * 1.2).rounded(),
                adsSensi: (baseSensi * scaleFactor * 0.85).rounded(),
                scopeSensi: (baseSensi * scaleFactor * 0.5).rounded(),
                description: "Fast close-range combat"
            ),
            RecommendedSensi(
                name: "Sniper Focus",
                phoneSensi: (baseSensi * scaleFactor * 0.85).rounded(),
                adsSensi: (baseSensi * scaleFactor * 0.55).rounded(),
                scopeSensi: (baseSensi * scaleFactor * 0.3).rounded(),
                description: "Precision for long-range engagements"
            ),
            RecommendedSensi(
                name: isHighEnd ? "Pro Player" : "Optimized",
                phoneSensi: isHighEnd ? 55 : 48,
                adsSensi: isHighEnd ? 40 : 35,
                scopeSensi: isHighEnd ? 25 : 22,
                description: isHighEnd
                    ? "Tournament-grade competitive settings"
                    : "Tuned for your device performance tier"
            ),
        ]
    }

    // MARK: - Private Helpers

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            let type: String
            if path.usesInterfaceType(.wifi)          { type = "Wi-Fi" }
            else if path.usesInterfaceType(.cellular) { type = "Cellular" }
            else if path.usesInterfaceType(.wiredEthernet) { type = "Wired" }
            else { type = path.status == .satisfied ? "Connected" : "No Connection" }
            Task { @MainActor [weak self] in self?.networkType = type }
        }
        monitor.start(queue: monitorQueue)
    }

    private func modelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        return mapModel(machine)
    }

    private func mapModel(_ identifier: String) -> String {
        let mapping: [String: String] = [
            // iPhone 16
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            // iPhone 15
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            // iPhone 14
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            // iPhone 13
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            // iPhone 12
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            // iPhone 11
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            // iPhone XS / XR / X
            "iPhone11,2": "iPhone XS",
            "iPhone11,4": "iPhone XS Max",
            "iPhone11,6": "iPhone XS Max",
            "iPhone11,8": "iPhone XR",
            "iPhone10,3": "iPhone X",
            "iPhone10,6": "iPhone X",
            // iPhone 8 / 7
            "iPhone10,1": "iPhone 8",
            "iPhone10,4": "iPhone 8",
            "iPhone10,2": "iPhone 8 Plus",
            "iPhone10,5": "iPhone 8 Plus",
            "iPhone9,1":  "iPhone 7",
            "iPhone9,3":  "iPhone 7",
            "iPhone9,2":  "iPhone 7 Plus",
            "iPhone9,4":  "iPhone 7 Plus",
            // iPhone SE
            "iPhone14,6": "iPhone SE (3rd generation)",
            "iPhone12,8": "iPhone SE (2nd generation)",
            "iPhone8,4":  "iPhone SE",
            // Simulator
            "x86_64": "Simulator",
            "arm64":  "Simulator",
        ]
        return mapping[identifier] ?? identifier
    }

    private func storageInfo() -> (String, String) {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ) else { return ("—", "—") }

        let total = (attrs[.systemSize]     as? Int64) ?? 0
        let free  = (attrs[.systemFreeSize] as? Int64) ?? 0
        let used  = total - free

        let fmt: (Int64) -> String = { bytes in
            String(format: "%.1f GB", Double(bytes) / 1_073_741_824)
        }
        return (fmt(total), fmt(used))
    }
}
