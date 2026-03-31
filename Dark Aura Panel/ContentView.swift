import SwiftUI
import StoreKit

struct ContentView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var lm      = LocalizationManager.shared
    @EnvironmentObject var rc: RevenueCatService
    @EnvironmentObject var ads: AdsService
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @State private var selectedTab: AuraTab = .home
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showPromotion = false
    @State private var queuedPaywallAfterPromotion = false
    @State private var onboardingDone: Bool = UserDefaults.standard.bool(forKey: "onboarding_completed")
    @State private var appWasInBackground = false
    @State private var didCheckStartupPromotion = false
    @State private var startupReady = false
    @State private var startupFailed = false
    @State private var isPreparingStartup = false
    @State private var isRetryingStartup = false

    var body: some View {
        ZStack {
            if !startupReady {
                StartupLoadingView(
                    isRetryState: startupFailed,
                    isRetrying: isRetryingStartup,
                    onRetry: {
                        Task { await prepareStartupIfNeeded(force: true) }
                    }
                )
                .transition(.opacity)
            } else if !onboardingDone {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.5)) { onboardingDone = true }
                    UserDefaults.standard.set(true, forKey: "onboarding_completed")
                    queuedPaywallAfterPromotion = !rc.isPro
                    schedulePromotionOrPaywall()
                }
                .environmentObject(lm)
                .zIndex(100)
                .transition(.opacity)
            } else {
                mainApp
                    .transition(.opacity)
            }
        }
        .environmentObject(lm)
        .environment(\.layoutDirection, lm.language.isRTL ? .rightToLeft : .leftToRight)
        .task {
            await prepareStartupIfNeeded()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                appWasInBackground = true
                ads.noteDidEnterBackground()
            }
            if newPhase == .active && appWasInBackground && onboardingDone && startupReady {
                appWasInBackground = false
                Task {
                    await ads.handleAppDidBecomeActive(onboardingCompleted: onboardingDone)
                }
                if !UserDefaults.standard.bool(forKey: "standby_review_shown") {
                    UserDefaults.standard.set(true, forKey: "standby_review_shown")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        requestReview()
                    }
                }
            }
        }
        .overlay {
            if ads.showAppOpenSplash {
                ZStack {
                    Color.black.ignoresSafeArea()

                    VStack(spacing: 14) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AuraColors.accent)

                        Text("Sponsored message loading…")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Please wait a moment.")
                            .font(.system(size: 12))
                            .foregroundColor(AuraColors.textTertiary)
                    }
                    .padding(28)
                }
                .transition(.opacity)
                .zIndex(300)
            }

            if showPromotion {
                PromotionPopupView(
                    imageURL: promotionImageURL,
                    onDownload: openPromotionLink,
                    onClose: dismissPromotion
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(400)
            }
        }
    }

    // MARK: – Main app shell
    @ViewBuilder
    private var mainApp: some View {
        ZStack(alignment: .bottom) {
            // ── Tab content — pushed down by topChrome, up by tab bar ──
            Group {
                switch selectedTab {
                case .home:
                    HomeView(settings: settings, selectedTab: $selectedTab)
                        .environmentObject(rc)
                case .training:
                    TrainingView(settings: settings)
                        .environmentObject(rc)
                case .deviceInfos:
                    DeviceInfosView()
                        .environmentObject(rc)
                case .learning:
                    LearningView(settings: settings, selectedTab: $selectedTab)
                        .environmentObject(rc)
                case .settings:
                    // Settings opens as a sheet; fall back to home view
                    HomeView(settings: settings, selectedTab: $selectedTab)
                        .environmentObject(rc)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── Custom tab bar ──
            AuraBottomTabBar(selectedTab: $selectedTab, onSettingsTap: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    showSettings = true
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            })

            // ── Draggable armed-features button (all tabs) ──
            if settings.isPoweredOn {
                AuraDraggableFloatingOverlay(settings: settings)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
                .environmentObject(rc)
        }
        .fullScreenCover(isPresented: $showSettings) {
            AppSettingsMenu(isPresented: $showSettings)
                .environmentObject(rc)
                .environmentObject(lm)
        }
    }

}

private extension ContentView {
    var promotionImageURL: URL? {
        guard let raw = ads.config?.ads.appImageLink, !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    var promotionAppURL: URL? {
        guard let raw = ads.config?.ads.appLink, !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    func scheduleStartupPromotionIfNeeded() {
        guard onboardingDone, !didCheckStartupPromotion else { return }
        didCheckStartupPromotion = true
        queuedPaywallAfterPromotion = false
        schedulePromotionOrPaywall()
    }

    func schedulePromotionOrPaywall() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if shouldShowPromotionPopup {
                showPromotion = true
            } else if queuedPaywallAfterPromotion {
                showPaywall = true
                queuedPaywallAfterPromotion = false
            }
        }
    }

    var shouldShowPromotionPopup: Bool {
        guard onboardingDone else { return false }
        guard ads.config?.ads.Promotion == true else { return false }
        return promotionAppURL != nil
    }

    func dismissPromotion() {
        showPromotion = false
        if queuedPaywallAfterPromotion {
            queuedPaywallAfterPromotion = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showPaywall = true
            }
        }
    }

    func openPromotionLink() {
        guard let url = promotionAppURL else {
            dismissPromotion()
            return
        }
        UIApplication.shared.open(url)
        dismissPromotion()
    }

    func prepareStartupIfNeeded(force: Bool = false) async {
        guard !isPreparingStartup else { return }
        if startupReady && !force { return }

        isPreparingStartup = true
        isRetryingStartup = force
        startupFailed = false

        let prepared = await ads.prepareForStartup()

        isPreparingStartup = false
        isRetryingStartup = false
        startupReady = prepared
        startupFailed = !prepared

        guard prepared else { return }

        await ads.handleAppDidBecomeActive(onboardingCompleted: onboardingDone)
        scheduleStartupPromotionIfNeeded()
    }
}

#Preview {
    ContentView()
        .environmentObject(RevenueCatService.shared)
        .environmentObject(AdsService.shared)
}
