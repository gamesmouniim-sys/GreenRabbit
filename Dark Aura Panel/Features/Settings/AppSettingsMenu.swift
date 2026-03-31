import SwiftUI
import StoreKit

struct AppSettingsMenu: View {
    @EnvironmentObject var lm: LocalizationManager
    @EnvironmentObject var rc: RevenueCatService
    @Environment(\.requestReview) private var requestReview
    @Binding var isPresented: Bool

    @State private var showPaywall     = false

    private let privacyURL = URL(string: "https://games-apps-store.blogspot.com/p/privacy-policy.html")!

    var body: some View {
        ZStack {
            AuraColors.gradientBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        if !rc.isPro {
                            proCard
                        }

                        languageSection

                        settingsActions
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 140)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView()
                .environmentObject(rc)
        }
        .environment(\.layoutDirection, lm.language.isRTL ? .rightToLeft : .leftToRight)
    }

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AuraColors.accent)

                Text(lm.t(.settings))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.82))
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(Color.black.opacity(0.55))
    }

    private var proCard: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AuraColors.accent, AuraColors.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: AuraColors.accentGlow.opacity(0.5), radius: 8)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("BECOME PREMIUM")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)

                    Text("Unlock Premium aim, training & all features forever")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AuraColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.72))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(lm.t(.language), icon: "globe")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(AppLanguage.allCases) { lang in
                    languageTile(lang)
                }
            }
        }
    }

    private func languageTile(_ lang: AppLanguage) -> some View {
        let isSelected = lm.language == lang

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                lm.language = lang
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Text(lang.flag)
                    .font(.system(size: 20))

                Text(lang.nativeName)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AuraColors.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AuraColors.accent.opacity(0.16) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? AuraColors.accent.opacity(0.45) : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var settingsActions: some View {
        VStack(alignment: .leading, spacing: 24) {

            // ── General ──
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("GENERAL", icon: "slider.horizontal.3")

                VStack(spacing: 10) {
                    ShareLink(
                        item: AppConstants.appStoreURL,
                        subject: Text("Dark Aura Panel — Green Rabbit"),
                        message: Text(lm.t(.shareMessage))
                    ) {
                        actionRowContent(icon: "square.and.arrow.up", label: lm.t(.shareApp))
                    }
                    .buttonStyle(.plain)

                    Link(destination: privacyURL) {
                        actionRowContent(icon: "lock.shield.fill", label: lm.t(.privacyPolicy))
                    }
                    .buttonStyle(.plain)

                    actionRow(icon: "star.fill", label: lm.t(.rateApp), iconColor: Color(red: 1, green: 0.8, blue: 0)) {
                        requestReview()
                    }
                }
            }
        }
    }

    private func actionRow(
        icon: String,
        label: String,
        iconColor: Color = AuraColors.accent,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            actionRowContent(icon: icon, label: label, iconColor: iconColor)
        }
        .buttonStyle(.plain)
    }

    private func actionRowContent(
        icon: String,
        label: String,
        iconColor: Color = AuraColors.accent
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AuraColors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AuraColors.accent)
            Text(text)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(AuraColors.accent)
                .tracking(1.2)
        }
    }
}

// Share functionality is handled by SwiftUI's native ShareLink (iOS 16+),
// which correctly anchors popovers on iPad and works on all Apple platforms.
