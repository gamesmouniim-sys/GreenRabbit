import SwiftUI

// MARK: - Crosshair Settings
struct CrosshairSettings: Codable, Equatable {
    var style: Int = 0           // 0=cross, 1=dot, 2=circle, 3=crossDot
    var size: Double = 8
    var thickness: Double = 2
    var gap: Double = 4
    var opacity: Double = 1.0
    var color: CodableColor = CodableColor(r: 0.05, g: 0.95, b: 0.35)
    var glowEnabled: Bool = true
    var outlineEnabled: Bool = true
    var centerDot: Bool = true
    var animateRecoil: Bool = false
}

// MARK: - Sensitivity Settings
struct SensitivitySettings: Codable, Equatable {
    var phoneSensi: Double = 50
    var gunSensi: [String: Double] = [
        "AR": 50, "SMG": 55, "Sniper": 30, "Shotgun": 60, "Pistol": 50
    ]
    var adsMultiplier: Double = 0.7
    var scopeMultiplier: Double = 0.4
}

// MARK: - Projectile Settings
struct ProjectileSettings: Codable, Equatable {
    var color: CodableColor = CodableColor(r: 1, g: 0.3, b: 0)
    var trailEnabled: Bool = true
    var trailLength: Double = 0.5
    var hitSparkEnabled: Bool = true
    var invisible: Bool = false
}

// MARK: - HUD Settings
struct HUDSettings: Codable, Equatable {
    var layout: Int = 0  // 0=default, 1=claw, 2=thumbs, 3=custom
    var buttonScale: Double = 1.0
    var reticleOffset: CGFloat = 0
}

// MARK: - Device Overlay Settings
struct DeviceOverlaySettings: Codable, Equatable {
    var showFPS: Bool = false
    var showBatteryTemp: Bool = false
    var showRAM: Bool = false
    var showPing: Bool = false
    var showDPI: Bool = false
}

// MARK: - Render Scale Preset
enum RenderScalePreset: Int, Codable, CaseIterable, Identifiable {
    case low = 0, medium, high, ultra
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .ultra: return "Ultra"
        }
    }
    var scale: CGFloat {
        switch self {
        case .low: return 0.6
        case .medium: return 0.8
        case .high: return 1.0
        case .ultra: return 1.2
        }
    }
}

// MARK: - Training Game Mode
enum TrainingGameMode: String, CaseIterable, Identifiable, Codable {
    // Green Rabbit Vol.1 — core modes
    case speedTap       = "Speed Tap"
    case sniperZeroing  = "Sniper Zeroing"
    case dodgeShoot     = "Dodge & Shoot"
    case memoryGrid     = "Memory Grid"
    // Green Rabbit Vol.2 — new advanced modes
    case phantomRush    = "Phantom Rush"
    case neuralArc      = "Neural Arc"
    case zoneLock       = "Zone Lock"
    case pulseStrike    = "Pulse Strike"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .speedTap:         return "hand.tap.fill"
        case .sniperZeroing:    return "binoculars.fill"
        case .dodgeShoot:       return "figure.run"
        case .memoryGrid:       return "square.grid.3x3.fill"
        case .phantomRush:      return "eye.slash.fill"
        case .neuralArc:        return "point.3.connected.trianglepath.dotted"
        case .zoneLock:         return "circle.dashed.inset.filled"
        case .pulseStrike:      return "waveform.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .speedTap:         return "Max taps per second under pressure"
        case .sniperZeroing:    return "Long-range precision with wind drift"
        case .dodgeShoot:       return "Dodge obstacles and hit moving targets"
        case .memoryGrid:       return "Memorize & repeat flashing sequences"
        case .phantomRush:      return "Hit ghost targets during their brief flash"
        case .neuralArc:        return "Tap numbered nodes in exact sequence"
        case .zoneLock:         return "Track & tap inside a drifting zone"
        case .pulseStrike:      return "Time your shot to the pulse ring"
        }
    }

    var roundDuration: TimeInterval {
        switch self {
        case .speedTap:         return 15
        case .sniperZeroing:    return 60
        case .dodgeShoot:       return 35
        case .memoryGrid:       return 60
        case .phantomRush:      return 20
        case .neuralArc:        return 45
        case .zoneLock:         return 30
        case .pulseStrike:      return 25
        }
    }

    var isNew: Bool { true }

    var volume: Int {
        switch self {
        case .speedTap, .sniperZeroing, .dodgeShoot, .memoryGrid: return 1
        case .phantomRush, .neuralArc, .zoneLock, .pulseStrike:   return 2
        }
    }

    var difficulty: String {
        switch self {
        case .speedTap:         return "Easy"
        case .sniperZeroing:    return "Expert"
        case .dodgeShoot:       return "Hard"
        case .memoryGrid:       return "Medium"
        case .phantomRush:      return "Hard"
        case .neuralArc:        return "Expert"
        case .zoneLock:         return "Medium"
        case .pulseStrike:      return "Hard"
        }
    }

    /// Modes that require a Premium subscription
    var isPremium: Bool {
        switch self {
        case .dodgeShoot, .pulseStrike: return true
        default:                        return false
        }
    }
}

// MARK: - Training Session
struct TrainingSession: Codable, Equatable {
    var mode: TrainingGameMode = .speedTap
    var score: Int = 0
    var hits: Int = 0
    var misses: Int = 0
    var headshots: Int = 0
    var combo: Int = 0
    var maxCombo: Int = 0
    var totalTargets: Int = 0
    var reactionTimes: [Double] = []
    var isActive: Bool = false
    var timeRemaining: TimeInterval = 45

    var accuracy: Double {
        let total = hits + misses
        guard total > 0 else { return 0 }
        return Double(hits) / Double(total) * 100
    }

    var headshotRatio: Double {
        guard hits > 0 else { return 0 }
        return Double(headshots) / Double(hits) * 100
    }

    var averageReaction: Double {
        guard !reactionTimes.isEmpty else { return 0 }
        return reactionTimes.reduce(0, +) / Double(reactionTimes.count)
    }

    var isWin: Bool { score >= 500 }
}

// MARK: - Quiz Question
struct QuizQuestion: Identifiable, Codable {
    let id: Int
    let question: String
    let options: [String]   // exactly 4
    let correctIndex: Int   // 0-3
    let explanation: String
}

// MARK: - Lesson Item
struct LessonItem: Identifiable, Codable {
    let id: Int
    let icon: String            // SF Symbol name
    let title: String
    let level: String
    let duration: String
    let description: String
    let tips: [String]
    let practiceMode: TrainingGameMode
    let quiz: [QuizQuestion]    // 3 questions shown after reading
    var isCompleted: Bool = false
    var isPremium: Bool   = false
}

// MARK: - Best Score
struct BestScore: Codable {
    var scores: [String: Int] = [:]

    func best(for mode: TrainingGameMode) -> Int {
        scores[mode.rawValue] ?? 0
    }

    mutating func update(mode: TrainingGameMode, score: Int) {
        let current = scores[mode.rawValue] ?? 0
        if score > current { scores[mode.rawValue] = score }
    }
}

// MARK: - Recommended Sensi
struct RecommendedSensi: Identifiable {
    let id = UUID()
    let name: String
    let phoneSensi: Double
    let adsSensi: Double
    let scopeSensi: Double
    let description: String
}

// MARK: - Device Sensi Preset (ffsensi.com data)
struct DeviceSensiPreset: Identifiable, Codable {
    var id: String { deviceName }
    let deviceName: String
    let viceDPI: Int
    let general: Int
    let redDot: Int
    let twoXScope: Int
    let fourXScope: Int
    let sniper: Int
    let freeLook: Int

    var shareText: String {
        """
📱 Free Fire Sensitivity — \(deviceName)
━━━━━━━━━━━━━━━━━━━━━
Vice DPI:    \(viceDPI)
General:     \(general)
Red Dot:     \(redDot)
2X Scope:    \(twoXScope)
4X Scope:    \(fourXScope)
Sniper:      \(sniper)
Free Look:   \(freeLook)
━━━━━━━━━━━━━━━━━━━━━
🎮 Dark Aura Panel — Green Rabbit
"""
    }
}

// MARK: - Codable Color Helper
struct CodableColor: Codable, Equatable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double = 1.0

    var color: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }

    static let red = CodableColor(r: 1, g: 0.2, b: 0.25)
    static let green = CodableColor(r: 0.15, g: 0.85, b: 0.4)
    static let cyan = CodableColor(r: 0, g: 0.9, b: 1)
    static let yellow = CodableColor(r: 1, g: 0.9, b: 0)
    static let white = CodableColor(r: 1, g: 1, b: 1)
    static let orange = CodableColor(r: 1, g: 0.5, b: 0)
}
