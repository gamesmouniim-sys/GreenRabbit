import Foundation
import Combine
import UIKit
import AppTrackingTransparency
import AdSupport

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

#if canImport(AppLovinSDK)
import AppLovinSDK
#endif

@MainActor
final class AdsService: NSObject, ObservableObject {
    static let shared = AdsService()

    enum Placement: String {
        case appOpenLaunch = "app_open_launch"
        case uiInteraction = "ui_interaction"
        case homeAllFeatures = "home_all_features"
        case homeAimColors = "home_aim_colors"
        case homeRAM = "home_ram"
        case homeInvisibleBall = "home_invisible_ball"
        case trainingAllGamesStart = "training_all_games_start"
        case trainingFlicksStart = "training_game_flicks_start"
        case trainingFinishWin = "training_game_finish_win"
        case trainingFinishLose = "training_game_finish_lose"
        case learningAllButtons = "learning_all_buttons"
        case learningMarkComplete = "learning_mark_complete"
        case deviceRecommendedSensi = "device_recommended_sensi"
    }

    enum AdType {
        case openApp
        case interstitial
        case rewarded
    }

    enum Provider: String {
        case admob
        case applovin
        case none
    }

    @Published private(set) var config: HostedAdsPayload?
    @Published private(set) var isConfigured = false
    @Published private(set) var didLoadRemoteConfig = false
    @Published var showAppOpenSplash = false

    private let configURL = URL(string: "https://drive.google.com/uc?export=download&id=1IfFAHHGM8Rv8mVoLLwNh4rXqj527F2LZ")!
    private let configCacheKey = "ads.hosted.config.cache"
    private let clickCounterKey = "ads.interstitial.click.counter"
    private let attPromptKey = "ads.att.requested"

    private var bootstrapTask: Task<Void, Never>?
    private var lastBackgroundDate: Date?
    private var lastOpenAppDisplayDate: Date?
    private let openAppCooldown: TimeInterval = 120

    private var pendingRewardAction: (() -> Void)?
    private var pendingRewardFallbackAction: (() -> Void)?
    private var pendingRewardPlacement: Placement?
    private var didEarnReward = false

    #if canImport(GoogleMobileAds)
    private var admobOpenAd: AppOpenAd?
    private var admobInterstitialAd: InterstitialAd?
    private var admobRewardedAd: RewardedAd?
    private var didStartAdMob = false
    #endif

    #if canImport(AppLovinSDK)
    private var appLovinOpenAd: MAAppOpenAd?
    private var appLovinInterstitialAd: MAInterstitialAd?
    private var appLovinRewardedAd: MARewardedAd?
    private var didStartAppLovin = false
    private var appLovinInterstitialRetryAttempt = 0.0
    private var appLovinRewardedRetryAttempt = 0.0
    private var appLovinOpenRetryAttempt = 0.0
    #endif

    private override init() {
        super.init()
        if let cachedData = UserDefaults.standard.data(forKey: configCacheKey),
           let cachedConfig = try? JSONDecoder().decode(HostedAdsPayload.self, from: cachedData) {
            config = cachedConfig
        }
    }

    var adsEnabled: Bool {
        guard let ads = config?.ads else { return false }
        return ads.AdsOk && !RevenueCatService.shared.isPro
    }

    func prepareForStartup() async -> Bool {
        let didRefresh = await refreshHostedConfiguration()
        guard didRefresh else {
            isConfigured = false
            didLoadRemoteConfig = false
            return false
        }

        startSDKsIfNeeded()
        preloadAds()
        isConfigured = true
        return true
    }

    func bootstrapIfNeeded() async {
        if let bootstrapTask {
            await bootstrapTask.value
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }
            _ = await self.prepareForStartup()
        }

        bootstrapTask = task
        await task.value
    }

    @discardableResult
    func refreshHostedConfiguration() async -> Bool {
        do {
            let (data, _) = try await URLSession.shared.data(from: configURL)
            let payload = try JSONDecoder().decode(HostedAdsPayload.self, from: data)
            config = payload
            UserDefaults.standard.set(data, forKey: configCacheKey)
            didLoadRemoteConfig = true
            return true
        } catch {
            didLoadRemoteConfig = false
            print("[Ads] Failed to fetch hosted config: \(error.localizedDescription)")
            return false
        }
    }

    func noteDidEnterBackground() {
        lastBackgroundDate = Date()
    }

    func handleAppDidBecomeActive(onboardingCompleted: Bool) async {
        await bootstrapIfNeeded()

        guard onboardingCompleted, adsEnabled else { return }
        guard placementEnabled(.appOpenLaunch) else { return }

        if let lastOpenAppDisplayDate,
           Date().timeIntervalSince(lastOpenAppDisplayDate) < openAppCooldown {
            return
        }

        if let lastBackgroundDate,
           Date().timeIntervalSince(lastBackgroundDate) < 15 {
            return
        }

        showAppOpenSplash = true

        if await showOpenAppAdIfAvailable() {
            lastOpenAppDisplayDate = Date()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                self.showAppOpenSplash = false
            }
        }
    }

    func registerInteraction(for placement: Placement) {
        guard adsEnabled else { return }
        guard placementEnabled(placement) else { return }

        let nextCount = UserDefaults.standard.integer(forKey: clickCounterKey) + 1
        UserDefaults.standard.set(nextCount, forKey: clickCounterKey)

        let threshold = max(config?.ads.ClickNumber ?? 5, 1)
        guard nextCount >= threshold else { return }

        UserDefaults.standard.set(0, forKey: clickCounterKey)
        Task { await self.showInterstitialIfAvailable(for: placement) }
    }

    func presentRewardedIfAvailable(
        for placement: Placement,
        rewardAction: @escaping () -> Void,
        fallbackAction: @escaping () -> Void
    ) {
        Task {
            await bootstrapIfNeeded()

            guard adsEnabled, placementEnabled(placement) else {
                rewardAction()
                return
            }

            pendingRewardPlacement = placement
            pendingRewardAction = rewardAction
            pendingRewardFallbackAction = fallbackAction
            didEarnReward = false

            let shown = await showRewardedAdIfAvailable(for: placement)
            if !shown {
                clearPendingRewardState()
                fallbackAction()
            }
        }
    }

    func requestTrackingPermissionFromUIIfNeeded() {
        Task {
            await requestTrackingPermissionIfNeeded()
        }
    }

    func requestTrackingPermissionBeforeProceeding() async {
        await requestTrackingPermissionIfNeeded()
    }

    private func requestTrackingPermissionIfNeeded() async {
        guard !UserDefaults.standard.bool(forKey: attPromptKey) else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            UserDefaults.standard.set(true, forKey: attPromptKey)
            return
        }

        try? await Task.sleep(nanoseconds: 500_000_000)

        _ = await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        UserDefaults.standard.set(true, forKey: attPromptKey)
    }

    private func startSDKsIfNeeded() {
        startAdMobIfNeeded()
        startAppLovinIfNeeded()
    }

    private func preloadAds() {
        loadOpenAppAd()
        loadInterstitialAd()
        loadRewardedAd()
    }

    private func provider(for type: AdType) -> Provider {
        guard let settings = config?.ads.settings else { return .none }

        switch type {
        case .openApp:
            return Provider(rawValue: settings.openads.lowercased()) ?? .none
        case .interstitial:
            return Provider(rawValue: settings.inters.lowercased()) ?? .none
        case .rewarded:
            return Provider(rawValue: settings.rewards.lowercased()) ?? .none
        }
    }

    private func placementEnabled(_ placement: Placement) -> Bool {
        switch placement {
        case .appOpenLaunch:
            return true
        case .uiInteraction, .homeAllFeatures, .trainingAllGamesStart, .trainingFinishWin, .trainingFinishLose, .learningAllButtons, .learningMarkComplete:
            return provider(for: .interstitial) != .none
        case .homeAimColors, .homeRAM, .homeInvisibleBall, .trainingFlicksStart, .deviceRecommendedSensi:
            return provider(for: .rewarded) != .none
        }
    }

    private func clearPendingRewardState() {
        pendingRewardAction = nil
        pendingRewardFallbackAction = nil
        pendingRewardPlacement = nil
        didEarnReward = false
    }

    private func loadOpenAppAd() {
        guard adsEnabled else { return }

        switch provider(for: .openApp) {
        case .admob:
            loadAdMobOpenAd()
        case .applovin:
            loadAppLovinOpenAd()
        case .none:
            break
        }
    }

    private func loadInterstitialAd() {
        guard adsEnabled else { return }

        switch provider(for: .interstitial) {
        case .admob:
            loadAdMobInterstitial()
        case .applovin:
            loadAppLovinInterstitial()
        case .none:
            break
        }
    }

    private func loadRewardedAd() {
        guard adsEnabled else { return }

        switch provider(for: .rewarded) {
        case .admob:
            loadAdMobRewarded()
        case .applovin:
            loadAppLovinRewarded()
        case .none:
            break
        }
    }

    private func showOpenAppAdIfAvailable() async -> Bool {
        switch provider(for: .openApp) {
        case .admob:
            return showAdMobOpenAd()
        case .applovin:
            return showAppLovinOpenAd()
        case .none:
            return false
        }
    }

    private func showInterstitialIfAvailable(for placement: Placement) async {
        switch provider(for: .interstitial) {
        case .admob:
            _ = showAdMobInterstitial(for: placement)
        case .applovin:
            _ = showAppLovinInterstitial(for: placement)
        case .none:
            break
        }
    }

    private func showRewardedAdIfAvailable(for placement: Placement) async -> Bool {
        switch provider(for: .rewarded) {
        case .admob:
            return showAdMobRewarded(for: placement)
        case .applovin:
            return showAppLovinRewarded(for: placement)
        case .none:
            return false
        }
    }

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}

// MARK: - Hosted Config

struct HostedAdsPayload: Codable {
    let ads: HostedAdsConfig

    static let disabledDefault = HostedAdsPayload(
        ads: HostedAdsConfig(
            AdsOk: false,
            ClickNumber: 5,
            Promotion: false,
            appImageLink: "",
            appLink: "",
            admob: .init(
                openAdsIds: "",
                bannerIds: [],
                interIds: [],
                nativeIds: [],
                rewardIds: []
            ),
            applovin: .init(
                sdk_key: "8RHCMxxZPei--AGwtM3E6OEev0RW51t-s1RrGEr0puTkrPT7XC7AEHoaUa2FCmJ3PTAJSVW2AeHBgIoA4MpNS-",
                bannerId: "",
                openAdsIds: "",
                interId: "",
                nativeId: "",
                rewardId: ""
            ),
            settings: .init(
                openads: "none",
                banners: "none",
                inters: "none",
                natives: "none",
                rewards: "none"
            )
        )
    )
}

struct HostedAdsConfig: Codable {
    let AdsOk: Bool
    let ClickNumber: Int
    let Promotion: Bool
    let appImageLink: String
    let appLink: String
    let admob: HostedAdMobConfig
    let applovin: HostedAppLovinConfig
    let settings: HostedAdsNetworkSettings
}

struct HostedAdMobConfig: Codable {
    let openAdsIds: String
    let bannerIds: [String]
    let interIds: [String]
    let nativeIds: [String]
    let rewardIds: [String]
}

struct HostedAppLovinConfig: Codable {
    let sdk_key: String
    let bannerId: String
    let openAdsIds: String
    let interId: String
    let nativeId: String
    let rewardId: String
}

struct HostedAdsNetworkSettings: Codable {
    let openads: String
    let banners: String
    let inters: String
    let natives: String
    let rewards: String
}

// MARK: - Google Mobile Ads

#if canImport(GoogleMobileAds)
extension AdsService: FullScreenContentDelegate {
    private func startAdMobIfNeeded() {
        guard !didStartAdMob else { return }
        didStartAdMob = true
        MobileAds.shared.start(completionHandler: nil)
    }

    private func loadAdMobOpenAd() {
        guard let unitID = config?.ads.admob.openAdsIds, !unitID.isEmpty else { return }

        Task {
            do {
                let ad = try await AppOpenAd.load(with: unitID, request: Request())
                ad.fullScreenContentDelegate = self
                admobOpenAd = ad
            } catch {
                print("[Ads] AdMob open ad load failed: \(error.localizedDescription)")
            }
        }
    }

    private func loadAdMobInterstitial() {
        guard let unitID = config?.ads.admob.interIds.first, !unitID.isEmpty else { return }

        Task {
            do {
                let ad = try await InterstitialAd.load(with: unitID, request: Request())
                ad.fullScreenContentDelegate = self
                admobInterstitialAd = ad
            } catch {
                print("[Ads] AdMob interstitial load failed: \(error.localizedDescription)")
            }
        }
    }

    private func loadAdMobRewarded() {
        guard let unitID = config?.ads.admob.rewardIds.first, !unitID.isEmpty else { return }

        Task {
            do {
                let ad = try await RewardedAd.load(with: unitID, request: Request())
                ad.fullScreenContentDelegate = self
                admobRewardedAd = ad
            } catch {
                print("[Ads] AdMob rewarded load failed: \(error.localizedDescription)")
            }
        }
    }

    private func showAdMobOpenAd() -> Bool {
        guard let ad = admobOpenAd else {
            loadAdMobOpenAd()
            return false
        }

        ad.present(from: rootViewController())
        admobOpenAd = nil
        return true
    }

    private func showAdMobInterstitial(for placement: Placement) -> Bool {
        guard let ad = admobInterstitialAd else {
            loadAdMobInterstitial()
            return false
        }

        ad.present(from: rootViewController())
        admobInterstitialAd = nil
        print("[Ads] Showing AdMob interstitial for \(placement.rawValue)")
        return true
    }

    private func showAdMobRewarded(for placement: Placement) -> Bool {
        guard let ad = admobRewardedAd else {
            loadAdMobRewarded()
            return false
        }

        ad.present(from: rootViewController()) { [weak self] in
            guard let self else { return }
            self.didEarnReward = true
            self.pendingRewardAction?()
            self.clearPendingRewardState()
        }
        admobRewardedAd = nil
        print("[Ads] Showing AdMob rewarded for \(placement.rawValue)")
        return true
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        showAppOpenSplash = false
        loadOpenAppAd()
        loadInterstitialAd()
        loadRewardedAd()
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        print("[Ads] AdMob present failed: \(error.localizedDescription)")
        showAppOpenSplash = false

        if pendingRewardAction != nil {
            let fallback = pendingRewardFallbackAction
            clearPendingRewardState()
            fallback?()
        }

        loadOpenAppAd()
        loadInterstitialAd()
        loadRewardedAd()
    }
}
#else
extension AdsService {
    private func startAdMobIfNeeded() {}
    private func loadAdMobOpenAd() {}
    private func loadAdMobInterstitial() {}
    private func loadAdMobRewarded() {}
    private func showAdMobOpenAd() -> Bool { false }
    private func showAdMobInterstitial(for placement: Placement) -> Bool { false }
    private func showAdMobRewarded(for placement: Placement) -> Bool { false }
}
#endif

// MARK: - AppLovin MAX

#if canImport(AppLovinSDK)
extension AdsService: MAAdDelegate, MARewardedAdDelegate {
    private func startAppLovinIfNeeded() {
        guard !didStartAppLovin else { return }
        guard let sdkKey = config?.ads.applovin.sdk_key, !sdkKey.isEmpty else { return }

        didStartAppLovin = true

        let initConfig = ALSdkInitializationConfiguration(sdkKey: sdkKey) { builder in
            builder.mediationProvider = ALMediationProviderMAX
        }

        ALSdk.shared().initialize(with: initConfig) { _ in
            self.loadAppLovinOpenAd()
            self.loadAppLovinInterstitial()
            self.loadAppLovinRewarded()
        }
    }

    private func loadAppLovinOpenAd() {
        guard let unitID = config?.ads.applovin.openAdsIds, !unitID.isEmpty else { return }

        if appLovinOpenAd == nil {
            let ad = MAAppOpenAd(adUnitIdentifier: unitID)
            ad.delegate = self
            appLovinOpenAd = ad
        }

        appLovinOpenAd?.load()
    }

    private func loadAppLovinInterstitial() {
        guard let unitID = config?.ads.applovin.interId, !unitID.isEmpty else { return }

        if appLovinInterstitialAd == nil {
            let ad = MAInterstitialAd(adUnitIdentifier: unitID)
            ad.delegate = self
            appLovinInterstitialAd = ad
        }

        appLovinInterstitialAd?.load()
    }

    private func loadAppLovinRewarded() {
        guard let unitID = config?.ads.applovin.rewardId, !unitID.isEmpty else { return }

        if appLovinRewardedAd == nil {
            let ad = MARewardedAd.shared(withAdUnitIdentifier: unitID)
            ad.delegate = self
            appLovinRewardedAd = ad
        }

        appLovinRewardedAd?.load()
    }

    private func showAppLovinOpenAd() -> Bool {
        guard let ad = appLovinOpenAd, ad.isReady else {
            loadAppLovinOpenAd()
            return false
        }

        ad.show()
        return true
    }

    private func showAppLovinInterstitial(for placement: Placement) -> Bool {
        guard let ad = appLovinInterstitialAd, ad.isReady else {
            loadAppLovinInterstitial()
            return false
        }

        ad.show()
        return true
    }

    private func showAppLovinRewarded(for placement: Placement) -> Bool {
        guard let ad = appLovinRewardedAd, ad.isReady else {
            loadAppLovinRewarded()
            return false
        }

        ad.show()
        return true
    }

    func didLoad(_ ad: MAAd) {
        if ad.adUnitIdentifier == config?.ads.applovin.interId {
            appLovinInterstitialRetryAttempt = 0
        } else if ad.adUnitIdentifier == config?.ads.applovin.rewardId {
            appLovinRewardedRetryAttempt = 0
        } else if ad.adUnitIdentifier == config?.ads.applovin.openAdsIds {
            appLovinOpenRetryAttempt = 0
        }
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        if adUnitIdentifier == config?.ads.applovin.interId {
            appLovinInterstitialRetryAttempt += 1
            let delay = pow(2.0, min(6.0, appLovinInterstitialRetryAttempt))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { self.loadAppLovinInterstitial() }
        } else if adUnitIdentifier == config?.ads.applovin.rewardId {
            appLovinRewardedRetryAttempt += 1
            let delay = pow(2.0, min(6.0, appLovinRewardedRetryAttempt))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { self.loadAppLovinRewarded() }
        } else if adUnitIdentifier == config?.ads.applovin.openAdsIds {
            appLovinOpenRetryAttempt += 1
            let delay = pow(2.0, min(6.0, appLovinOpenRetryAttempt))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { self.loadAppLovinOpenAd() }
        }

        print("[Ads] AppLovin load failed for \(adUnitIdentifier): \(error.message)")
    }

    func didDisplay(_ ad: MAAd) {}
    func didClick(_ ad: MAAd) {}

    func didHide(_ ad: MAAd) {
        showAppOpenSplash = false

        if ad.adUnitIdentifier == config?.ads.applovin.interId {
            loadAppLovinInterstitial()
        } else if ad.adUnitIdentifier == config?.ads.applovin.rewardId {
            loadAppLovinRewarded()
            if !didEarnReward {
                clearPendingRewardState()
            }
        } else if ad.adUnitIdentifier == config?.ads.applovin.openAdsIds {
            loadAppLovinOpenAd()
        }
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        print("[Ads] AppLovin present failed: \(error.message)")
        showAppOpenSplash = false

        if ad.adUnitIdentifier == config?.ads.applovin.rewardId {
            let fallback = pendingRewardFallbackAction
            clearPendingRewardState()
            fallback?()
            loadAppLovinRewarded()
        } else if ad.adUnitIdentifier == config?.ads.applovin.interId {
            loadAppLovinInterstitial()
        } else if ad.adUnitIdentifier == config?.ads.applovin.openAdsIds {
            loadAppLovinOpenAd()
        }
    }

    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        didEarnReward = true
        pendingRewardAction?()
        clearPendingRewardState()
    }
}
#else
extension AdsService {
    private func startAppLovinIfNeeded() {}
    private func loadAppLovinOpenAd() {}
    private func loadAppLovinInterstitial() {}
    private func loadAppLovinRewarded() {}
    private func showAppLovinOpenAd() -> Bool { false }
    private func showAppLovinInterstitial(for placement: Placement) -> Bool { false }
    private func showAppLovinRewarded(for placement: Placement) -> Bool { false }
}
#endif
