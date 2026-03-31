import Foundation

// MARK: - Supported Languages
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english    = "en"
    case portuguese = "pt"
    case spanish    = "es"
    case arabic     = "ar"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .english:    return "🇺🇸"
        case .portuguese: return "🇧🇷"
        case .spanish:    return "🇪🇸"
        case .arabic:     return "🇸🇦"
        }
    }

    var nativeName: String {
        switch self {
        case .english:    return "English"
        case .portuguese: return "Português"
        case .spanish:    return "Español"
        case .arabic:     return "العربية"
        }
    }

    var isRTL: Bool { self == .arabic }
}

// MARK: - All localised string keys
enum LK: String {
    // ── Home ──
    case trainingArmed, standby
    case sensiSetup, aimCross, trickKey, deviceOverlay
    case phoneSensi, phoneSensiSub
    case hudMobile, hudMobileSub
    case phoneDPI, phoneDPISub
    case gunSensi, gunSensiSub
    case basicAim, basicAimSub
    case aimSetup, aimSetupSub
    case aimColors, aimColorsSub
    case aimSettings, aimSettingsSub
    case ballPaint, ballPaintSub
    case ballSetup, ballSetupSub
    case invisibleBall, invisibleBallSub
    case fps, fpsSub
    case batteryTemp, batteryTempSub
    case ram, ramSub
    case ping, pingSub
    case deviceDPI, deviceDPISub
    case enableFeatureFirst

    // ── Training ──
    case training
    case featuresActive, powerOnFromHome
    case score, time, exit
    case activeFeatures, noFeaturesActive

    // ── Device Info ──
    case deviceInfos, recommendedSensi, generateSensi

    // ── Learning ──
    case learning, markComplete, completed

    // ── Settings ──
    case settings, language, shareApp, privacyPolicy, rateApp, close
    case shareMessage

    // ── Floating Panel ──
    case sensiSetupGroup, aimCrossGroup, trickKeyGroup, deviceInfoGroup
}
