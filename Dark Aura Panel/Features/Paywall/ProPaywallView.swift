import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Paywall  (single donation offer)

struct ProPaywallView: View {
    @EnvironmentObject var rc: RevenueCatService
    @Environment(\.dismiss) private var dismiss

    var onProUnlocked: (() -> Void)? = nil

    private let privacyURL = URL(string: "https://games-apps-store.blogspot.com/p/privacy-policy.html")!
    private let termsURL   = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // MARK: Animations
    @State private var iconScale:      CGFloat = 0.5
    @State private var iconOpacity:    Double  = 0
    @State private var glowPulse                = false
    @State private var matrixOffset:   CGFloat = 0
    @State private var showCustomerCenter       = false
    @State private var cardAppear               = false

    // MARK: Benefits
    private let benefits: [(icon: String, text: String)] = [
        ("nosign",                     "Remove all ads forever"),
        ("figure.run",                 "All Premium training modes"),
        ("scope",                      "Premium aim tools & crosshair"),
        ("cpu",                        "Full device overlay stats"),
        ("gearshape.fill",             "All locked features unlocked"),
        ("heart.fill",                 "Support the developers ❤️"),
    ]

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────
            Color(red: 0.02, green: 0.04, blue: 0.02).ignoresSafeArea()
            matrixRain
            neonVignette

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    closeButton

                    // ── Icon ──────────────────────────────────────
                    rabbitHero
                        .padding(.top, 8)

                    // ── Headline ──────────────────────────────────
                    headlineBlock
                        .padding(.top, 24)

                    // ── Donation card ────────────────────────────
                    donationCard
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    // ── Benefits ─────────────────────────────────
                    benefitsList
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    // Clearance so content isn't hidden behind sticky footer
                    Color.clear.frame(height: 200)
                }
            }
            // ── Sticky footer: CTA + links ────────────────────────
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    // Blur separator
                    Rectangle()
                        .fill(AuraColors.accent.opacity(0.08))
                        .frame(height: 0.6)

                    VStack(spacing: 0) {
                        ctaButton
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        footerLinks
                            .padding(.top, 12)
                            .padding(.bottom, 28)
                    }
                    .background(
                        Color(red: 0.02, green: 0.04, blue: 0.02)
                            .opacity(0.97)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { startAnimations() }
        .sheet(isPresented: $showCustomerCenter) {
            NavigationStack {
                CustomerCenterView()
                    .onRestoreCompleted { rc.apply(customerInfo: $0) }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { !(rc.errorMessage ?? "").isEmpty },
            set: { if !$0 { rc.clearError() } }
        )) {
            Button("OK", role: .cancel) { rc.clearError() }
        } message: {
            Text(rc.errorMessage ?? "")
        }
    }

    // MARK: – Close
    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: – Rabbit hero
    private var rabbitHero: some View {
        ZStack {
            // Outer pulse rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(AuraColors.accent.opacity(glowPulse ? 0.12 - Double(i)*0.03 : 0.05), lineWidth: 1)
                    .frame(width: CGFloat(130 + i*28), height: CGFloat(130 + i*28))
                    .scaleEffect(glowPulse ? 1.06 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.8 + Double(i)*0.3).repeatForever(autoreverses: true).delay(Double(i)*0.2),
                        value: glowPulse
                    )
            }

            // Icon container
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AuraColors.accent.opacity(0.22), Color.black.opacity(0.0)],
                            center: .center, startRadius: 0, endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 110)

                Group {
                    if let uiImg = Self.loadAppIcon() {
                        Image(uiImage: uiImg).resizable().scaledToFill()
                    } else {
                        ZStack {
                            Color(red: 0.04, green: 0.08, blue: 0.04)
                            Image(systemName: "hare.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(AuraColors.accent)
                        }
                    }
                }
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AuraColors.accentGradient, lineWidth: 2)
                )
                .shadow(color: AuraColors.accentGlow.opacity(glowPulse ? 0.75 : 0.35), radius: glowPulse ? 24 : 12)
            }

            // PREMIUM badge
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9, weight: .black))
                        Text("PREMIUM")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .tracking(1)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AuraColors.accentGradient)
                            .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 6)
                    )
                    .offset(x: 10, y: -10)
                }
                Spacer()
            }
            .frame(width: 100, height: 100)
        }
        .scaleEffect(iconScale)
        .opacity(iconOpacity)
    }

    // MARK: – Headline
    private var headlineBlock: some View {
        VStack(spacing: 10) {
            // Top label
            Text("ONE-TIME DONATION")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(AuraColors.accentSecondary)
                .tracking(3)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(AuraColors.accentSecondary.opacity(0.1))
                        .overlay(Capsule().stroke(AuraColors.accentSecondary.opacity(0.3), lineWidth: 0.8))
                )

            Text("DONATE &\nUNLOCK PREMIUM")
                .font(.system(size: 30, weight: .black, design: .monospaced))
                .foregroundStyle(AuraColors.accentGradient)
                .multilineTextAlignment(.center)
                .tracking(1.5)
                .shadow(color: AuraColors.accentGlow.opacity(0.4), radius: 12)

            Text("Help keep the Rabbit running.\nGet all Premium features — forever.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AuraColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.horizontal, 24)
    }

    // MARK: – Donation card
    private var donationCard: some View {
        ZStack {
            // Card BG
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AuraColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AuraColors.accentGradient, lineWidth: 1.2)
                )
                .shadow(color: AuraColors.accentGlow.opacity(0.15), radius: 16)

            // Scanline
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AuraColors.scanline)

            VStack(spacing: 8) {
                Text("LIFETIME ACCESS")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(AuraColors.textTertiary)
                    .tracking(2.5)

                // Price
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(rc.donationPackage?.localizedPriceString ?? "$2.99")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundStyle(AuraColors.accentGradient)
                        .shadow(color: AuraColors.accentGlow.opacity(0.5), radius: 10)

                    Text("/ once")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(AuraColors.textTertiary)
                        .padding(.bottom, 8)
                }

                Text("Pay once · Never again · All features unlocked")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(AuraColors.textTertiary)
            }
            .padding(.vertical, 24)
        }
        .offset(y: cardAppear ? 0 : 30)
        .opacity(cardAppear ? 1 : 0)
    }

    // MARK: – Benefits list
    private var benefitsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(benefits.enumerated()), id: \.offset) { idx, benefit in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AuraColors.accent.opacity(0.13))
                            .frame(width: 36, height: 36)
                        Image(systemName: benefit.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AuraColors.accent)
                            .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 4)
                    }

                    Text(benefit.text)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AuraColors.accent)
                        .shadow(color: AuraColors.accentGlow.opacity(0.5), radius: 4)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .background(
                    idx % 2 == 0
                        ? AuraColors.accent.opacity(0.03)
                        : Color.clear
                )

                if idx < benefits.count - 1 {
                    Rectangle()
                        .fill(AuraColors.cardBorder)
                        .frame(height: 0.6)
                        .padding(.leading, 68)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AuraColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AuraColors.cardBorder, lineWidth: 0.8)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: – CTA button
    private var ctaButton: some View {
        Button {
            guard !rc.isLoading, let pkg = rc.donationPackage else { return }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            Task {
                await rc.purchase(package: pkg)
                if rc.isPro {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onProUnlocked?()
                    dismiss()
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AuraColors.accentGradient)
                    .shadow(color: AuraColors.accentGlow.opacity(0.55), radius: 18)

                // Shine shimmer
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .padding(1)

                if rc.isLoading {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(1.1)
                } else {
                    VStack(spacing: 3) {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            Text("DONATE & UNLOCK PREMIUM")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.black)
                                .tracking(0.5)
                        }
                        Text(rc.donationPackage.map { "One-time \($0.localizedPriceString)" } ?? "One-time payment")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
        }
        .buttonStyle(.plain)
        .disabled(rc.isLoading || rc.donationPackage == nil)
        .opacity(rc.donationPackage == nil ? 0.55 : 1.0)
    }

    // MARK: – Footer
    private var footerLinks: some View {
        VStack(spacing: 12) {
            Text("One-time purchase · Lifetime access · No recurring charges")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Button("Restore Purchases") {
                    Task { await rc.restorePurchases() }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AuraColors.accent.opacity(0.8))
                .buttonStyle(.plain)
                .disabled(rc.isLoading)

                Link("Privacy", destination: privacyURL)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))

                Link("Terms", destination: termsURL)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            if rc.canShowCustomerCenter {
                Button("Manage Purchase") {
                    showCustomerCenter = true
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.45))
                .buttonStyle(.plain)
            }

            Text("Payment charged to your Apple ID on confirmation.\nThis is a one-time purchase with no subscription.")
                .font(.system(size: 9))
                .foregroundColor(AuraColors.textTertiary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.horizontal, 24)
    }

    // MARK: – Animated matrix rain background
    private var matrixRain: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { _ in
            Canvas { ctx, size in
                let cols  = Int(size.width / 18)
                let green = Color(red: 0.05, green: 0.95, blue: 0.35)
                for col in 0..<cols {
                    let x   = CGFloat(col) * 18 + 9
                    let off = matrixOffset + CGFloat(col * 137 % 200)
                    let y   = off.truncatingRemainder(dividingBy: size.height)
                    // Fading trail
                    for t in 0..<5 {
                        let ty    = y - CGFloat(t * 16)
                        let alpha = (1.0 - Double(t) * 0.2) * 0.12
                        let chars = ["1","0","▲","◆","·","∇","×"]
                        let ch    = chars[(col + t) % chars.count]
                        ctx.draw(
                            Text(ch)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(green.opacity(alpha)),
                            at: CGPoint(x: x, y: ty)
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                matrixOffset += 600
            }
        }
    }

    // MARK: – Edge vignette
    private var neonVignette: some View {
        ZStack {
            // Top + bottom dark fade
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.04, blue: 0.02).opacity(0.95), .clear,
                         .clear, Color(red: 0.02, green: 0.04, blue: 0.02).opacity(0.95)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Radial center clear (so content is visible)
            RadialGradient(
                colors: [Color(red: 0.02, green: 0.04, blue: 0.02).opacity(0.0),
                         Color(red: 0.02, green: 0.04, blue: 0.02).opacity(0.6)],
                center: .center, startRadius: 100, endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    // MARK: – App icon loader
    /// Loads the actual compiled app icon from the bundle, with named-image fallbacks.
    private static func loadAppIcon() -> UIImage? {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let lastName = files.last,
           let img = UIImage(named: lastName) {
            return img
        }
        return UIImage(named: "AppIcon") ?? UIImage(named: "RabbitIcon")
    }

    // MARK: – Start animations
    private func startAnimations() {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.65).delay(0.1)) {
            iconScale = 1.0; iconOpacity = 1.0
        }
        glowPulse = true
        withAnimation(.easeOut(duration: 0.55).delay(0.3)) {
            cardAppear = true
        }
        Task { await rc.fetchOfferings() }
    }
}

// MARK: - Pro Lock Overlay (kept for compatibility)

struct ProLockOverlay: View {
    let label: String
    @State private var showPaywall = false
    @EnvironmentObject var rc: RevenueCatService

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showPaywall = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AuraColors.accent.opacity(0.35), lineWidth: 1)
                    )
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AuraColors.accent)
                    Text(label)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(AuraColors.accent)
                        .tracking(1.5)
                    Text("TAP TO UNLOCK")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(AuraColors.textTertiary)
                        .tracking(2)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            ProPaywallView().environmentObject(rc)
        }
    }
}

#Preview {
    ProPaywallView()
        .environmentObject(RevenueCatService.shared)
}
