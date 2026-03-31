import SwiftUI

// MARK: - AuraDraggableFloatingOverlay
//
// Floats the "armed features" button over ALL tabs.
// • Drag freely — releases snap to the nearest edge (left / right / top / bottom)
// • Never docks all the way to the very top or bottom — stays inside visible area
// • Feature panel slides out from the button in the direction away from the edge

struct AuraDraggableFloatingOverlay: View {
    @ObservedObject var settings: AppSettings
    @EnvironmentObject var lm : LocalizationManager
    @EnvironmentObject var ads: AdsService

    @State private var snapEdge   : SnapEdge = .left
    @State private var pos        : CGPoint  = CGPoint(x: 54, y: 380)
    @State private var dragOffset : CGSize   = .zero
    @State private var showMenu   : Bool     = false

    // Button is 58 pt diameter → half = 29 pt
    private let btnHalf   : CGFloat = 29
    private let edgeInset : CGFloat = 8    // gap between button edge and screen edge
    // Safe vertical band — clear of status bar (top) and tab bar (bottom)
    private let topSafe   : CGFloat = 110
    private let botSafe   : CGFloat = 130  // subtracted from screen height

    enum SnapEdge { case left, right, top, bottom }

    // ─── Live button center during drag ───────────────────────────────────
    private func livePos(_ size: CGSize) -> CGPoint {
        CGPoint(
            x: (pos.x + dragOffset.width) .clamped(btnHalf, size.width  - btnHalf),
            y: (pos.y + dragOffset.height).clamped(topSafe, size.height - botSafe)
        )
    }

    // ─── Snap to nearest edge ──────────────────────────────────────────────
    private func snap(_ raw: CGPoint, size: CGSize) -> (SnapEdge, CGPoint) {
        let clampedX : CGFloat = raw.x.clamped(btnHalf + edgeInset,
                                               size.width  - btnHalf - edgeInset)
        let clampedY : CGFloat = raw.y.clamped(topSafe, size.height - botSafe)

        let dLeft   = raw.x
        let dRight  = size.width  - raw.x
        let dTop    = raw.y
        let dBottom = size.height - raw.y
        let minD    = min(dLeft, dRight, dTop, dBottom)

        switch minD {
        case dLeft:
            return (.left,   CGPoint(x: btnHalf + edgeInset, y: clampedY))
        case dRight:
            return (.right,  CGPoint(x: size.width - btnHalf - edgeInset, y: clampedY))
        case dTop:
            return (.top,    CGPoint(x: clampedX, y: topSafe))
        default:
            return (.bottom, CGPoint(x: clampedX, y: size.height - botSafe))
        }
    }

    // ─── Panel anchor — centred away from the snapped edge ────────────────
    private func panelCenter(in size: CGSize) -> CGPoint {
        let pw : CGFloat = 248
        let ph : CGFloat = 310  // conservative height estimate
        let gap: CGFloat = 10
        let safeMinX = pw / 2 + 8
        let safeMaxX = size.width  - pw / 2 - 8
        let safeMinY = ph / 2 + topSafe
        let safeMaxY = size.height - ph / 2 - botSafe + 40

        switch snapEdge {
        case .left:
            let x = min(safeMaxX, pos.x + btnHalf + gap + pw / 2)
            let y = pos.y.clamped(safeMinY, safeMaxY)
            return CGPoint(x: x, y: y)
        case .right:
            let x = max(safeMinX, pos.x - btnHalf - gap - pw / 2)
            let y = pos.y.clamped(safeMinY, safeMaxY)
            return CGPoint(x: x, y: y)
        case .top:
            let x = pos.x.clamped(safeMinX, safeMaxX)
            let y = min(safeMaxY, pos.y + btnHalf + gap + ph / 2)
            return CGPoint(x: x, y: y)
        case .bottom:
            let x = pos.x.clamped(safeMinX, safeMaxX)
            let y = max(safeMinY, pos.y - btnHalf - gap - ph / 2)
            return CGPoint(x: x, y: y)
        }
    }

    // ─── Panel slide transition (towards/away from the edge) ──────────────
    private var panelTransition: AnyTransition {
        let e: SwiftUI.Edge
        switch snapEdge {
        case .left:   e = .leading
        case .right:  e = .trailing
        case .top:    e = .top
        case .bottom: e = .bottom
        }
        let slide = AnyTransition.move(edge: e).combined(with: .opacity)
        return .asymmetric(insertion: slide, removal: slide)
    }

    // ─── Body ─────────────────────────────────────────────────────────────
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let live = livePos(size)

            ZStack(alignment: .topLeading) {
                // Feature panel — appears away from the docked edge
                if showMenu {
                    FloatingFeaturePanel(settings: settings) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            showMenu = false
                        }
                    }
                    .frame(width: 248)
                    .position(panelCenter(in: size))
                    .transition(panelTransition)
                    .zIndex(1)
                }

                // Floating button
                AuraFloatingMenuButton(isExpanded: showMenu) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showMenu.toggle()
                    }
                }
                .position(live)
                .gesture(
                    DragGesture(minimumDistance: 5, coordinateSpace: .local)
                        .onChanged { v in
                            // Close panel while dragging for clarity
                            if showMenu { withAnimation { showMenu = false } }
                            dragOffset = v.translation
                        }
                        .onEnded { v in
                            let raw = CGPoint(x: pos.x + v.translation.width,
                                             y: pos.y + v.translation.height)
                            let (newEdge, snapped) = snap(raw, size: size)
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) {
                                snapEdge    = newEdge
                                pos         = snapped
                                dragOffset  = .zero
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                )
                .zIndex(2)
            }
            .onAppear {
                // Default: left edge, vertically centred
                if pos == CGPoint(x: 54, y: 380) {
                    pos = CGPoint(x: btnHalf + edgeInset, y: size.height * 0.45)
                }
            }
        }
        .ignoresSafeArea()
        // Whole overlay is transparent to taps except over the button/panel
        .allowsHitTesting(showMenu || true)   // always allow — ZStack is clear background
    }
}

// MARK: - CGFloat clamping helper (local)
private extension CGFloat {
    func clamped(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        Swift.max(lo, Swift.min(hi, self))
    }
}
