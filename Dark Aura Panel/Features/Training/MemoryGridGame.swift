import SwiftUI
import Combine

// MARK: - Memory Grid Game
// Cells in a 3×4 grid flash in a sequence. The player must reproduce the
// sequence by tapping the same cells in order. Each correct round adds one
// more cell to the sequence. Wrong tap = combo reset & -50 pts.
// 60-second round, Medium difficulty.

struct MemoryGridGame: View {
    @ObservedObject var settings: AppSettings

    // MARK: - Grid constants
    private let cols = 3
    private let rows = 4
    private var cellCount: Int { cols * rows }

    // MARK: - Phase
    private enum Phase {
        case showing     // flashing the sequence to the player
        case input       // player tapping cells
        case feedback    // brief correct / wrong flash
    }

    // MARK: - State
    @State private var sequence        : [Int]  = []    // cells to memorise
    @State private var playerInput     : [Int]  = []    // cells tapped so far
    @State private var highlightedCell : Int?   = nil   // currently flashing cell
    @State private var wrongCell       : Int?   = nil   // wrongly tapped cell
    @State private var correctFlash    : Bool   = false // green flash overlay
    @State private var phase           : Phase  = .showing
    @State private var roundNumber     : Int    = 1
    @State private var showTimer       : AnyCancellable?

    var body: some View {
        GeometryReader { geo in
            let padding: CGFloat = 20
            let spacing: CGFloat = 10
            let availableW = geo.size.width - padding * 2 - spacing * CGFloat(cols - 1)
            let cellSize   = availableW / CGFloat(cols)
            let totalH     = cellSize * CGFloat(rows) + spacing * CGFloat(rows - 1)

            ZStack {
                Color(red: 0.02, green: 0.04, blue: 0.02).ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // ── Round & instruction header ──────────────
                    VStack(spacing: 6) {
                        Text("ROUND \(roundNumber)")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(AuraColors.accent)
                            .tracking(3)
                            .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 6)

                        Text(phaseLabel)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(AuraColors.textTertiary)
                            .tracking(1.5)
                            .animation(.easeInOut, value: phase)
                    }

                    // ── Progress dots ───────────────────────────
                    HStack(spacing: 6) {
                        ForEach(0..<sequence.count, id: \.self) { i in
                            Circle()
                                .fill(i < playerInput.count ? AuraColors.accent : AuraColors.textTertiary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .shadow(color: i < playerInput.count ? AuraColors.accentGlow : .clear, radius: 3)
                        }
                    }

                    // ── Grid ─────────────────────────────────────
                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack(spacing: spacing) {
                                ForEach(0..<cols, id: \.self) { col in
                                    let index = row * cols + col
                                    gridCell(index: index, size: cellSize)
                                }
                            }
                        }
                    }
                    .frame(width: geo.size.width - padding * 2, height: totalH)

                    Spacer()
                }
                .padding(.horizontal, padding)

                // ── Correct flash overlay ─────────────────────
                if correctFlash {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(AuraColors.accent.opacity(0.08))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .onAppear  { startRound() }
            .onDisappear { showTimer?.cancel() }
        }
        .ignoresSafeArea()
    }

    // MARK: - Grid cell
    @ViewBuilder
    private func gridCell(index: Int, size: CGFloat) -> some View {
        let isHighlighted = highlightedCell == index
        let isWrong       = wrongCell       == index
        let isCorrect     = phase == .input && playerInput.contains(index)

        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(cellBackground(isHighlighted: isHighlighted, isWrong: isWrong, isCorrect: isCorrect))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(cellBorder(isHighlighted: isHighlighted, isWrong: isWrong, isCorrect: isCorrect), lineWidth: 1.2)

            // Cell index label (subtle)
            if phase == .input && !isCorrect {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(AuraColors.textTertiary.opacity(0.25))
            }

            if isHighlighted {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: AuraColors.accentGlow, radius: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isHighlighted ? 0.92 : 1.0)
        .shadow(color: isHighlighted ? AuraColors.accentGlow.opacity(0.6) : .clear, radius: 10)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHighlighted)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isWrong)
        .onTapGesture {
            guard phase == .input else { return }
            handleCellTap(index: index)
        }
    }

    private func cellBackground(isHighlighted: Bool, isWrong: Bool, isCorrect: Bool) -> Color {
        if isHighlighted { return AuraColors.accent.opacity(0.35) }
        if isWrong       { return AuraColors.redChip.opacity(0.35) }
        if isCorrect     { return AuraColors.accentDim.opacity(0.2) }
        return AuraColors.cardBackground
    }

    private func cellBorder(isHighlighted: Bool, isWrong: Bool, isCorrect: Bool) -> Color {
        if isHighlighted { return AuraColors.accent.opacity(0.8) }
        if isWrong       { return AuraColors.redChip.opacity(0.8) }
        if isCorrect     { return AuraColors.accent.opacity(0.4) }
        return AuraColors.cardBorder
    }

    private var phaseLabel: String {
        switch phase {
        case .showing:  return "WATCH THE SEQUENCE…"
        case .input:    return "REPEAT THE SEQUENCE"
        case .feedback: return correctFlash ? "CORRECT!" : "WRONG!"
        }
    }

    // MARK: - Game logic

    private func startRound() {
        guard settings.currentSession.isActive else { return }
        playerInput = []
        wrongCell   = nil

        // Grow sequence by 1 each round (start with 2)
        let targetLen = roundNumber + 1
        if sequence.count < targetLen {
            sequence.append(Int.random(in: 0..<cellCount))
        }

        phase = .showing
        flashSequence(index: 0)
    }

    private func flashSequence(index: Int) {
        guard index < sequence.count else {
            // Done showing — switch to input phase
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { highlightedCell = nil; phase = .input }
            }
            return
        }

        let cell = sequence[index]
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.65) {
            guard settings.currentSession.isActive else { return }
            withAnimation(.spring(response: 0.15)) { highlightedCell = cell }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                withAnimation { highlightedCell = nil }
                flashSequence(index: index + 1)
            }
        }
    }

    private func handleCellTap(index: Int) {
        guard settings.currentSession.isActive else { return }

        let expectedIndex = playerInput.count
        guard expectedIndex < sequence.count else { return }

        playerInput.append(index)

        if index == sequence[expectedIndex] {
            // Correct tap
            withAnimation(.spring(response: 0.15)) { highlightedCell = index }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation { highlightedCell = nil }
            }

            if playerInput.count == sequence.count {
                // Completed the sequence!
                let combo   = settings.currentSession.combo + 1
                let pts     = 150 + roundNumber * 50 + combo * 20
                settings.currentSession.score    += pts
                settings.currentSession.hits     += 1
                settings.currentSession.combo     = combo
                settings.currentSession.maxCombo  = max(settings.currentSession.maxCombo, combo)

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                phase = .feedback
                withAnimation { correctFlash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation { correctFlash = false }
                    roundNumber += 1
                    startRound()
                }
            }
        } else {
            // Wrong tap
            settings.currentSession.misses += 1
            settings.currentSession.combo   = 0
            settings.currentSession.score   = max(0, settings.currentSession.score - 50)

            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.spring(response: 0.15)) { wrongCell = index }
            phase = .feedback

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation { wrongCell = nil }
                // Replay same round
                startRound()
            }
        }
    }
}
