import SwiftUI

// Tab order (left → right): Scan | Train | HOME (center) | Learn | Settings
enum AuraTab: Int, CaseIterable, Identifiable {
    case deviceInfos, training, home, learning, settings
    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .deviceInfos: return "iphone.radiowaves.left.and.right"
        case .training:    return "scope"
        case .home:        return "square.grid.2x2.fill"
        case .learning:    return "graduationcap.fill"
        case .settings:    return "slider.horizontal.3"
        }
    }

    var label: String {
        switch self {
        case .deviceInfos: return "Scan"
        case .training:    return "Train"
        case .home:        return "Home"
        case .learning:    return "Learn"
        case .settings:    return "Settings"
        }
    }

    /// Whether this tab navigates to a content view (false = fires an action)
    var isNavigation: Bool { self != .settings }
}

struct AuraBottomTabBar: View {
    @Binding var selectedTab: AuraTab
    var onSettingsTap: () -> Void = {}

    @EnvironmentObject private var ads: AdsService

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AuraTab.allCases) { tab in
                if tab == .settings {
                    // ── Settings: action button, never "selected" ──
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSettingsTap()
                    } label: {
                        tabItemView(tab: tab, active: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.label)
                } else {
                    // ── Navigation tab ─────────────────────────────
                    Button {
                        guard selectedTab != tab else { return }
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        ads.registerInteraction(for: .uiInteraction)
                    } label: {
                        tabItemView(tab: tab, active: selectedTab == tab)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.label)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
        .background(
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.02, green: 0.06, blue: 0.03))
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.3))
                // Top neon green hairline
                VStack {
                    LinearGradient(
                        colors: [
                            AuraColors.accent.opacity(0.0),
                            AuraColors.accent.opacity(0.55),
                            AuraColors.accent.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    Spacer()
                }
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: – Tab item layout
    @ViewBuilder
    private func tabItemView(tab: AuraTab, active: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                // Glow behind active icon
                if active {
                    Circle()
                        .fill(AuraColors.accent.opacity(0.14))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)
                }

                // Home tab gets a special pill background when active
                if tab == .home && active {
                    Capsule()
                        .fill(AuraColors.accent.opacity(0.18))
                        .frame(width: 48, height: 30)
                        .overlay(
                            Capsule()
                                .stroke(AuraColors.accent.opacity(0.4), lineWidth: 0.8)
                        )
                }

                Image(systemName: tab.icon)
                    .font(.system(
                        size: tab == .home ? 21 : 19,
                        weight: active ? .bold : .regular
                    ))
                    .foregroundColor(
                        active
                            ? AuraColors.accent
                            : tab == .settings
                                ? AuraColors.textSecondary
                                : AuraColors.textTertiary
                    )
                    .scaleEffect(active ? 1.15 : 1.0)
                    .shadow(
                        color: active ? AuraColors.accentGlow.opacity(0.75) : .clear,
                        radius: 6
                    )
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: active)
            }
            .frame(width: 44, height: 30)

            // Label
            Text(tab.label)
                .font(.system(
                    size: 9,
                    weight: active ? .semibold : .regular,
                    design: .monospaced
                ))
                .foregroundColor(
                    active
                        ? AuraColors.accent
                        : tab == .settings
                            ? AuraColors.textSecondary
                            : AuraColors.textTertiary
                )

            // Active dot indicator
            Capsule()
                .fill(active ? AuraColors.accent : .clear)
                .frame(width: active ? 18 : 0, height: 2)
                .shadow(color: active ? AuraColors.accentGlow : .clear, radius: 4)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: active)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
    }
}
