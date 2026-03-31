import SwiftUI

// MARK: - Onboarding container
struct OnboardingView: View {
    @EnvironmentObject var lm: LocalizationManager
    let onComplete: () -> Void

    @State private var page: OnboardingPage = .splash
    @State private var slideOffset: CGFloat = 0
    @State private var pageOpacity: Double  = 1

    enum OnboardingPage { case splash, language, scan }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch page {
            case .splash:
                OnboardingSplashPage { advance(to: .language) }
                    .transition(pageTransition)

            case .language:
                OnboardingLanguagePage { advance(to: .scan) }
                    .transition(pageTransition)

            case .scan:
                OnboardingScanPage { finishOnboarding() }
                    .transition(pageTransition)
            }

            // Step dots
            VStack {
                Spacer()
                stepDots
                    .padding(.bottom, 18)
            }
        }
        .environment(\.layoutDirection, lm.language.isRTL ? .rightToLeft : .leftToRight)
        .preferredColorScheme(.dark)
    }

    // MARK: – Navigation

    private func advance(to next: OnboardingPage) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            page = next
        }
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        withAnimation(.easeIn(duration: 0.35)) { onComplete() }
    }

    // MARK: – Step indicator

    private var stepDots: some View {
        HStack(spacing: 7) {
            ForEach([OnboardingPage.splash, .language, .scan], id: \.stepIndex) { p in
                Capsule()
                    .fill(page == p ? AuraColors.accent : Color.white.opacity(0.2))
                    .frame(width: page == p ? 20 : 7, height: 7)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: page == p)
            }
        }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        )
    }
}

// Identifiable step index helper
private extension OnboardingView.OnboardingPage {
    var stepIndex: Int {
        switch self {
        case .splash:   return 0
        case .language: return 1
        case .scan:     return 2
        }
    }
}
