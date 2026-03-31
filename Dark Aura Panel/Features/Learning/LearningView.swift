import SwiftUI

struct LearningView: View {
    @ObservedObject var settings: AppSettings
    @Binding var selectedTab: AuraTab
    @EnvironmentObject var rc: RevenueCatService
    @State private var openLesson  : LessonItem? = nil
    @State private var completed   : Set<Int>    = []
    @State private var showPaywall : Bool         = false

    private var total    : Int { LessonService.lessons.count }
    private var progress : Double { total > 0 ? Double(completed.count) / Double(total) : 0 }

    var body: some View {
        ZStack {
            AuraColors.gradientBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    headerPanel
                    ForEach(LessonService.lessons) { lesson in
                        lessonCard(lesson)
                    }
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showPaywall) {
            ProPaywallView().environmentObject(rc)
        }
        .sheet(item: $openLesson) { lesson in
            LessonDetailView(
                lesson: lesson,
                isCompleted: completed.contains(lesson.id),
                onComplete: {
                    withAnimation { _ = completed.insert(lesson.id) }
                },
                onPractice: { mode in
                    openLesson = nil
                    settings.selectedGame = mode
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    AdsService.shared.registerInteraction(for: .learningAllButtons)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = .training
                        }
                    }
                }
            )
        }
    }

    // MARK: - Header

    private var headerPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AuraColors.accentGradient)
                    .frame(width: 3, height: 22)
                    .shadow(color: AuraColors.accentGlow, radius: 6)
                Text("ACADEMY")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(3)
                Spacer()
                if !rc.isPro {
                    AuraPremiumButton {
                        showPaywall = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                } else {
                    Text("\(completed.count)/\(total)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(AuraColors.accent)
                        .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 4)
                }
            }
            Text("MASTER THE SCIENCE BEHIND ELITE AIM")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(AuraColors.textTertiary)
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 11)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(AuraColors.accentGradient)
                        .frame(width: geo.size.width * progress)
                        .shadow(color: AuraColors.accentGlow.opacity(0.6), radius: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 2)
        }
        .padding(.top, 16)
    }

    // MARK: - Lesson card

    @ViewBuilder
    private func lessonCard(_ lesson: LessonItem) -> some View {
        let isComplete = completed.contains(lesson.id)
        let isLocked   = lesson.isPremium && !rc.isPro
        let levelCol   = levelColor(lesson.level)

        Button {
            if isLocked {
                showPaywall = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                return
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            AdsService.shared.registerInteraction(for: .learningAllButtons)
            openLesson = lesson
        } label: {
            HStack(spacing: 14) {
                // Icon / number badge
                ZStack {
                    Circle()
                        .fill(isLocked
                              ? AuraColors.proGold.opacity(0.10)
                              : isComplete ? AuraColors.accent.opacity(0.18) : AuraColors.accent.opacity(0.08))
                        .frame(width: 46, height: 46)
                        .overlay(Circle().stroke(isLocked
                                                 ? AuraColors.proGold.opacity(0.4)
                                                 : isComplete ? AuraColors.accent.opacity(0.5) : AuraColors.accent.opacity(0.15), lineWidth: 1))

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AuraColors.proGold)
                    } else if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(AuraColors.accent)
                            .shadow(color: AuraColors.accentGlow, radius: 5)
                    } else {
                        Image(systemName: lesson.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AuraColors.accent.opacity(0.85))
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(lesson.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isLocked ? AuraColors.textSecondary : .white)
                            .multilineTextAlignment(.leading)
                        if isLocked {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill").font(.system(size: 7, weight: .black))
                                Text("PRO").font(.system(size: 7, weight: .black, design: .monospaced)).tracking(1)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(AuraColors.proGold)
                                .shadow(color: AuraColors.proGold.opacity(0.4), radius: 4))
                        }
                        Spacer()
                    }
                    HStack(spacing: 8) {
                        Text(lesson.level.uppercased())
                            .font(.system(size: 7, weight: .heavy, design: .monospaced))
                            .foregroundColor(levelCol)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(levelCol.opacity(0.14)))
                        HStack(spacing: 3) {
                            Image(systemName: "clock").font(.system(size: 8))
                            Text(lesson.duration).font(.system(size: 9, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(AuraColors.textTertiary)
                        HStack(spacing: 3) {
                            Image(systemName: "questionmark.circle").font(.system(size: 8))
                            Text("\(lesson.quiz.count)Q").font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(AuraColors.accentSecondary)
                    }
                }

                Image(systemName: isLocked ? "chevron.right" : isComplete ? "checkmark.seal.fill" : "chevron.right")
                    .font(.system(size: isComplete && !isLocked ? 16 : 12, weight: .bold))
                    .foregroundColor(isLocked ? AuraColors.proGold.opacity(0.6) : isComplete ? AuraColors.accent : AuraColors.textTertiary)
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isLocked ? Color(red: 0.07, green: 0.06, blue: 0.03) : AuraColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isLocked
                                    ? AuraColors.proGold.opacity(0.3)
                                    : isComplete ? AuraColors.accent.opacity(0.25) : AuraColors.cardBorder,
                                    lineWidth: isLocked ? 1.0 : isComplete ? 1.0 : 0.7)
                    )
            )
            .shadow(color: isLocked ? AuraColors.proGold.opacity(0.05) : isComplete ? AuraColors.accentGlow.opacity(0.05) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }

    private func levelColor(_ level: String) -> Color {
        switch level {
        case "Beginner":     return AuraColors.greenPositive
        case "Intermediate": return AuraColors.yellowWarning
        case "Advanced":     return Color(red: 1.0, green: 0.5, blue: 0.1)
        case "Expert":       return AuraColors.redChip
        default:             return AuraColors.textSecondary
        }
    }
}

// MARK: - Lesson Detail View (full-screen sheet)

private struct LessonDetailView: View {
    let lesson      : LessonItem
    let isCompleted : Bool
    let onComplete  : () -> Void
    let onPractice  : (TrainingGameMode) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phase         : LessonPhase = .reading
    @State private var currentQ      : Int = 0
    @State private var selectedAnswer: Int? = nil
    @State private var answerRevealed: Bool = false
    @State private var quizScore     : Int = 0   // correct answers
    @State private var quizDone      : Bool = false

    enum LessonPhase { case reading, quiz, result }

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.04, blue: 0.02).ignoresSafeArea()
            terminalLines.ignoresSafeArea()

            VStack(spacing: 0) {
                detailHeader
                switch phase {
                case .reading: readingContent
                case .quiz:    quizContent
                case .result:  resultContent
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background lines
    private var terminalLines: some View {
        Canvas { ctx, sz in
            let col = Color(red: 0.05, green: 0.95, blue: 0.35).opacity(0.025)
            var y: CGFloat = 0
            while y <= sz.height { var p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: sz.width, y: y)); ctx.stroke(p, with: .color(col), lineWidth: 0.3); y += 28 }
        }
    }

    // MARK: - Header
    @ViewBuilder private var detailHeader: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AuraColors.textTertiary)
                    .padding(9)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(lesson.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(phase == .reading ? "LESSON" : phase == .quiz ? "QUIZ — Q\(currentQ + 1) / \(lesson.quiz.count)" : "RESULTS")
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundColor(AuraColors.accent)
                    .tracking(1.5)
            }

            Spacer()

            // Phase indicator dots
            HStack(spacing: 5) {
                phaseIndicator(active: phase == .reading, icon: "doc.text.fill")
                phaseIndicator(active: phase == .quiz,    icon: "questionmark")
                phaseIndicator(active: phase == .result,  icon: "star.fill")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.5))
        Divider().background(AuraColors.accent.opacity(0.12))
    }

    private func phaseIndicator(active: Bool, icon: String) -> some View {
        ZStack {
            Circle()
                .fill(active ? AuraColors.accent.opacity(0.2) : Color.white.opacity(0.04))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(active ? AuraColors.accent.opacity(0.7) : Color.white.opacity(0.1), lineWidth: active ? 1.0 : 0.6))
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(active ? AuraColors.accent : AuraColors.textTertiary)
        }
    }

    // MARK: - Reading content
    private var readingContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Lesson icon + meta
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AuraColors.accent.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: lesson.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(AuraColors.accent)
                            .shadow(color: AuraColors.accentGlow, radius: 6)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.level.uppercased())
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                            .foregroundColor(AuraColors.yellowWarning)
                        Text(lesson.title)
                            .font(.system(size: 17, weight: .black))
                            .foregroundColor(.white)
                    }
                }

                // Main content
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("LESSON")
                    Text(lesson.description)
                        .font(.system(size: 13.5, weight: .regular, design: .default))
                        .foregroundColor(AuraColors.textSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Key tips
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("KEY TAKEAWAYS")
                    ForEach(Array(lesson.tips.enumerated()), id: \.offset) { i, tip in
                        HStack(alignment: .top, spacing: 10) {
                            Text("0\(i + 1)")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundColor(AuraColors.accentSecondary)
                                .padding(.top, 1)
                            Text(tip)
                                .font(.system(size: 12.5))
                                .foregroundColor(AuraColors.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AuraColors.accentSecondary.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AuraColors.accentSecondary.opacity(0.15), lineWidth: 0.7))
                        )
                    }
                }

                // CTA to quiz
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { phase = .quiz }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 16))
                        Text("START QUIZ  ·  \(lesson.quiz.count) QUESTIONS")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .tracking(0.5)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 18).padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AuraColors.accentGradient)
                            .shadow(color: AuraColors.accentGlow.opacity(0.4), radius: 12)
                    )
                }
                .buttonStyle(.plain)

                Spacer(minLength: 40)
            }
            .padding(20)
        }
    }

    // MARK: - Quiz content
    private var quizContent: some View {
        let q = lesson.quiz[currentQ]
        return VStack(spacing: 0) {
            // Progress
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.05))
                    Rectangle()
                        .fill(AuraColors.accentGradient)
                        .frame(width: geo.size.width * CGFloat(currentQ + 1) / CGFloat(lesson.quiz.count))
                        .animation(.easeInOut(duration: 0.35), value: currentQ)
                }
            }
            .frame(height: 3)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Question number
                    Text("QUESTION \(currentQ + 1) OF \(lesson.quiz.count)")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundColor(AuraColors.textTertiary)
                        .tracking(2)
                        .padding(.top, 24)

                    // Question text
                    Text(q.question)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Options
                    VStack(spacing: 10) {
                        ForEach(0..<q.options.count, id: \.self) { i in
                            optionButton(index: i, text: q.options[i], correctIndex: q.correctIndex)
                        }
                    }

                    // Explanation (after answer)
                    if answerRevealed {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(AuraColors.yellowWarning)
                                Text("EXPLANATION")
                                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                    .foregroundColor(AuraColors.yellowWarning)
                                    .tracking(1.5)
                            }
                            Text(q.explanation)
                                .font(.system(size: 13))
                                .foregroundColor(AuraColors.textSecondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AuraColors.yellowWarning.opacity(0.07))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AuraColors.yellowWarning.opacity(0.2), lineWidth: 0.8))
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                        // Next / Finish button
                        Button {
                            advanceQuiz()
                        } label: {
                            HStack(spacing: 8) {
                                Text(currentQ < lesson.quiz.count - 1 ? "NEXT QUESTION" : "SEE RESULTS")
                                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                    .tracking(0.5)
                                Image(systemName: currentQ < lesson.quiz.count - 1 ? "arrow.right" : "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AuraColors.accentGradient)
                                    .shadow(color: AuraColors.accentGlow.opacity(0.4), radius: 10)
                            )
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private func optionButton(index: Int, text: String, correctIndex: Int) -> some View {
        let isSelected = selectedAnswer == index
        let isCorrect  = index == correctIndex
        let showResult = answerRevealed

        let bgColor: Color = {
            guard showResult else {
                return isSelected ? AuraColors.accent.opacity(0.15) : Color.white.opacity(0.04)
            }
            if isCorrect { return AuraColors.accent.opacity(0.15) }
            if isSelected { return AuraColors.redChip.opacity(0.15) }
            return Color.white.opacity(0.03)
        }()

        let borderColor: Color = {
            guard showResult else {
                return isSelected ? AuraColors.accent.opacity(0.6) : Color.white.opacity(0.08)
            }
            if isCorrect { return AuraColors.accent.opacity(0.7) }
            if isSelected { return AuraColors.redChip.opacity(0.6) }
            return Color.white.opacity(0.05)
        }()

        Button {
            guard !answerRevealed else { return }
            selectedAnswer = index
            withAnimation(.spring(response: 0.25)) {
                answerRevealed = true
                if index == correctIndex { quizScore += 1 }
            }
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
        } label: {
            HStack(spacing: 12) {
                // Option letter
                Text(["A", "B", "C", "D"][index])
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(showResult && isCorrect ? AuraColors.accent : (isSelected ? (showResult ? AuraColors.redChip : AuraColors.accent) : AuraColors.textTertiary))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(bgColor.opacity(2)))

                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(showResult ? (isCorrect ? .white : (isSelected ? AuraColors.redChip.opacity(0.8) : AuraColors.textTertiary)) : .white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Spacer()

                if showResult {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : ""))
                        .font(.system(size: 16))
                        .foregroundColor(isCorrect ? AuraColors.accent : AuraColors.redChip)
                        .opacity(isCorrect || isSelected ? 1 : 0)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(bgColor)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(borderColor, lineWidth: 1.0))
            )
        }
        .buttonStyle(.plain)
        .disabled(answerRevealed)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: answerRevealed)
    }

    // MARK: - Result content
    private var resultContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // Score circle
                ZStack {
                    Circle()
                        .stroke(AuraColors.accent.opacity(0.15), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: CGFloat(quizScore) / CGFloat(lesson.quiz.count))
                        .stroke(AuraColors.accentGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: AuraColors.accentGlow.opacity(0.5), radius: 8)
                    VStack(spacing: 2) {
                        Text("\(quizScore)/\(lesson.quiz.count)")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text("CORRECT")
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                            .foregroundColor(AuraColors.textTertiary)
                            .tracking(2)
                    }
                }

                // Grade label
                let perfect = quizScore == lesson.quiz.count
                VStack(spacing: 6) {
                    Text(perfect ? "PERFECT SCORE" : quizScore >= 2 ? "LESSON PASSED" : "KEEP STUDYING")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(perfect ? AuraColors.accent : quizScore >= 2 ? AuraColors.yellowWarning : AuraColors.redChip)
                        .tracking(1.5)
                        .shadow(color: (perfect ? AuraColors.accentGlow : .clear).opacity(0.6), radius: 6)
                    Text(perfect ? "You mastered this lesson." : quizScore >= 2 ? "Solid understanding achieved." : "Review the lesson before moving on.")
                        .font(.system(size: 12))
                        .foregroundColor(AuraColors.textSecondary)
                }

                // Mark complete button (only if passed)
                if quizScore >= 2 && !isCompleted {
                    Button {
                        onComplete()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        AdsService.shared.registerInteraction(for: .learningMarkComplete)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill").font(.system(size: 14))
                            Text("MARK LESSON COMPLETE")
                                .font(.system(size: 13, weight: .heavy, design: .monospaced)).tracking(0.5)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AuraColors.accentGradient).shadow(color: AuraColors.accentGlow.opacity(0.4), radius: 10))
                    }
                    .buttonStyle(.plain)
                } else if isCompleted {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 13))
                        Text("ALREADY COMPLETED").font(.system(size: 11, weight: .heavy, design: .monospaced)).tracking(1)
                    }
                    .foregroundColor(AuraColors.accent)
                }

                // Practice CTA
                VStack(spacing: 10) {
                    Text("APPLY WHAT YOU LEARNED")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundColor(AuraColors.textTertiary)
                        .tracking(2)
                    Button {
                        onPractice(lesson.practiceMode)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: lesson.practiceMode.icon).font(.system(size: 14))
                            VStack(alignment: .leading, spacing: 1) {
                                Text("PRACTICE MODE")
                                    .font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundColor(AuraColors.textTertiary).tracking(1)
                                Text(lesson.practiceMode.rawValue)
                                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "play.fill").font(.system(size: 11, weight: .bold))
                                .foregroundColor(AuraColors.accent.opacity(0.8))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AuraColors.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AuraColors.accent.opacity(0.22), lineWidth: 1.0))
                        )
                        .foregroundColor(AuraColors.accent)
                    }
                    .buttonStyle(.plain)
                }

                // Retry quiz
                if quizScore < 2 {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            currentQ = 0; selectedAnswer = nil; answerRevealed = false; quizScore = 0
                            phase = .quiz
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise").font(.system(size: 12, weight: .bold))
                            Text("RETRY QUIZ").font(.system(size: 12, weight: .heavy, design: .monospaced)).tracking(0.5)
                        }
                        .foregroundColor(AuraColors.textSecondary)
                        .frame(maxWidth: .infinity).frame(height: 46)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.04)).overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.7)))
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers

    private func advanceQuiz() {
        if currentQ < lesson.quiz.count - 1 {
            withAnimation(.spring(response: 0.3)) {
                currentQ += 1
                selectedAnswer = nil
                answerRevealed = false
            }
        } else {
            withAnimation(.spring(response: 0.35)) { phase = .result }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack(spacing: 6) {
            Rectangle().fill(AuraColors.accent).frame(width: 2, height: 12).cornerRadius(1)
            Text(text)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(AuraColors.accent)
                .tracking(2)
        }
    }
}
