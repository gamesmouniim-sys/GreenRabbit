import SwiftUI
import Combine

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Power State
    @Published var isPoweredOn: Bool = false

    // MARK: - Sensi Setup Toggles
    @Published var phoneSensiEnabled: Bool = false
    @Published var hudMobileEnabled: Bool = false
    @Published var phoneDPIEnabled: Bool = false
    @Published var gunSensiEnabled: Bool = false

    // MARK: - Aim Cross Toggles
    @Published var basicAimEnabled: Bool = false
    @Published var aimSetupEnabled: Bool = false
    @Published var aimColorsEnabled: Bool = false
    @Published var aimSettingsEnabled: Bool = false

    // MARK: - Trick Key Toggles
    @Published var ballPaintEnabled: Bool = false
    @Published var ballSetupEnabled: Bool = false
    @Published var invisibleBallEnabled: Bool = false

    // MARK: - Optimize Game
    @Published var deleteJunkEnabled: Bool = false
    @Published var silentModeEnabled: Bool = false

    // MARK: - Device Overlay
    @Published var overlaySettings = DeviceOverlaySettings()

    // MARK: - Feature Settings
    @Published var crosshairSettings = CrosshairSettings()
    @Published var sensitivitySettings = SensitivitySettings()
    @Published var projectileSettings = ProjectileSettings()
    @Published var hudSettings = HUDSettings()
    @Published var renderScale: RenderScalePreset = .high

    // MARK: - Training State
    @Published var selectedGame: TrainingGameMode = .speedTap
    @Published var currentSession = TrainingSession()
    @Published var bestScores = BestScore()

    // MARK: - Computed
    var hasAnyFeatureEnabled: Bool {
        phoneSensiEnabled || hudMobileEnabled || phoneDPIEnabled || gunSensiEnabled ||
        basicAimEnabled || aimSetupEnabled || aimColorsEnabled || aimSettingsEnabled ||
        ballPaintEnabled || ballSetupEnabled || invisibleBallEnabled ||
        overlaySettings.showFPS || overlaySettings.showBatteryTemp ||
        overlaySettings.showRAM || overlaySettings.showPing || overlaySettings.showDPI
    }

    var activeFeatureSummary: [(String, String)] {
        var features: [(String, String)] = []
        if phoneSensiEnabled { features.append(("Mobile Sensi", "speedometer")) }
        if hudMobileEnabled { features.append(("HUD Mobile", "rectangle.split.3x3")) }
        if phoneDPIEnabled { features.append(("Mobile DPI", "viewfinder")) }
        if gunSensiEnabled { features.append(("Gun Sensi", "scope")) }
        if basicAimEnabled { features.append(("Standard Aim", "plus.viewfinder")) }
        if aimSetupEnabled { features.append(("Expert Aim", "slider.horizontal.below.rectangle")) }
        if aimColorsEnabled { features.append(("Aim Colors", "paintpalette.fill")) }
        if aimSettingsEnabled { features.append(("Aim Settings", "gearshape.fill")) }
        if ballPaintEnabled { features.append(("Ball Color", "paintbrush.fill")) }
        if ballSetupEnabled { features.append(("Ball Config", "circle.dashed")) }
        if invisibleBallEnabled { features.append(("Hide Ball", "eye.slash.fill")) }
        if overlaySettings.showFPS { features.append(("FPS", "gauge.high")) }
        if overlaySettings.showBatteryTemp { features.append(("Battery Temp", "thermometer.medium")) }
        if overlaySettings.showRAM { features.append(("RAM", "memorychip")) }
        if overlaySettings.showPing { features.append(("Ping", "wifi")) }
        if overlaySettings.showDPI { features.append(("Device DPI", "rectangle.dashed")) }
        return features
    }

    var hasOverlayEnabled: Bool {
        overlaySettings.showFPS || overlaySettings.showBatteryTemp ||
        overlaySettings.showRAM || overlaySettings.showPing || overlaySettings.showDPI
    }

    // MARK: - Persistence
    private let settingsKey = "com.darkaura.settings"

    init() { loadSettings() }

    func saveSettings() {
        let data = SettingsData(
            phoneSensiEnabled: phoneSensiEnabled,
            hudMobileEnabled: hudMobileEnabled,
            phoneDPIEnabled: phoneDPIEnabled,
            gunSensiEnabled: gunSensiEnabled,
            basicAimEnabled: basicAimEnabled,
            aimSetupEnabled: aimSetupEnabled,
            aimColorsEnabled: aimColorsEnabled,
            aimSettingsEnabled: aimSettingsEnabled,
            ballPaintEnabled: ballPaintEnabled,
            ballSetupEnabled: ballSetupEnabled,
            invisibleBallEnabled: invisibleBallEnabled,
            deleteJunkEnabled: deleteJunkEnabled,
            silentModeEnabled: silentModeEnabled,
            overlaySettings: overlaySettings,
            crosshairSettings: crosshairSettings,
            sensitivitySettings: sensitivitySettings,
            projectileSettings: projectileSettings,
            hudSettings: hudSettings,
            renderScale: renderScale,
            bestScores: bestScores
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) else { return }
        phoneSensiEnabled = decoded.phoneSensiEnabled
        hudMobileEnabled = decoded.hudMobileEnabled
        phoneDPIEnabled = decoded.phoneDPIEnabled
        gunSensiEnabled = decoded.gunSensiEnabled
        basicAimEnabled = decoded.basicAimEnabled
        aimSetupEnabled = decoded.aimSetupEnabled
        aimColorsEnabled = decoded.aimColorsEnabled
        aimSettingsEnabled = decoded.aimSettingsEnabled
        ballPaintEnabled = decoded.ballPaintEnabled
        ballSetupEnabled = decoded.ballSetupEnabled
        invisibleBallEnabled = decoded.invisibleBallEnabled
        deleteJunkEnabled = decoded.deleteJunkEnabled
        silentModeEnabled = decoded.silentModeEnabled
        overlaySettings = decoded.overlaySettings
        crosshairSettings = decoded.crosshairSettings
        sensitivitySettings = decoded.sensitivitySettings
        projectileSettings = decoded.projectileSettings
        hudSettings = decoded.hudSettings
        renderScale = decoded.renderScale
        bestScores = decoded.bestScores
    }

    func resetSession() {
        currentSession = TrainingSession(mode: selectedGame, timeRemaining: selectedGame.roundDuration)
    }

    func endSession() {
        currentSession.isActive = false
        bestScores.update(mode: selectedGame, score: currentSession.score)
        saveSettings()
    }
}

// MARK: - Persistence Model
private struct SettingsData: Codable {
    let phoneSensiEnabled: Bool
    let hudMobileEnabled: Bool
    let phoneDPIEnabled: Bool
    let gunSensiEnabled: Bool
    let basicAimEnabled: Bool
    let aimSetupEnabled: Bool
    let aimColorsEnabled: Bool
    let aimSettingsEnabled: Bool
    let ballPaintEnabled: Bool
    let ballSetupEnabled: Bool
    let invisibleBallEnabled: Bool
    var deleteJunkEnabled: Bool = false
    var silentModeEnabled: Bool = false
    let overlaySettings: DeviceOverlaySettings
    let crosshairSettings: CrosshairSettings
    let sensitivitySettings: SensitivitySettings
    let projectileSettings: ProjectileSettings
    let hudSettings: HUDSettings
    let renderScale: RenderScalePreset
    let bestScores: BestScore
}
