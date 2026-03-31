import Foundation

enum LessonService {
    static let lessons: [LessonItem] = [

        LessonItem(
            id: 1,
            icon: "brain.head.profile",
            title: "The Psychology of Aim",
            level: "Beginner",
            duration: "6 min",
            description: "Your mental state directly impacts your physical precision. Fear, tilt, and overconfidence cause muscle tension that distorts fine motor control. High performers learn to enter a 'flow state' — calm focus with zero self-judgment. The best aimers treat every shot as neutral data: feedback, not failure.",
            tips: [
                "Breathe out slowly before engaging — it lowers heart rate and steady hands",
                "Never chase kills when tilted; reset your mental state first",
                "Use positive self-talk: 'next shot' replaces 'I missed'",
                "Short sessions beat long grinding — quality over quantity"
            ],
            practiceMode: .speedTap,
            quiz: [
                QuizQuestion(id: 1, question: "What is 'flow state' in the context of aiming?", options: ["Sprinting while shooting", "Calm, focused performance with no self-judgment", "Using high sensitivity settings", "Shooting enemies from behind"], correctIndex: 1, explanation: "Flow state is a calm mental zone where focus is sharp and self-criticism disappears — the ideal mental state for precision."),
                QuizQuestion(id: 2, question: "What physical effect does tilt/anger have on aiming?", options: ["It increases accuracy through adrenaline", "It has no measurable effect", "It causes muscle tension that distorts fine motor control", "It speeds up reaction time"], correctIndex: 2, explanation: "Emotional stress causes muscles to tighten, reducing the micro-precision needed for accurate aim."),
                QuizQuestion(id: 3, question: "Which training approach is most effective?", options: ["Grinding for 5+ hours daily", "Short focused sessions with quality intent", "Only playing ranked matches", "Avoiding all aim training"], correctIndex: 1, explanation: "Short, intentional sessions with full focus produce faster improvement than exhausting marathon sessions.")
            ]
        ),

        LessonItem(
            id: 2,
            icon: "eye.circle.fill",
            title: "Reading Enemy Patterns",
            level: "Beginner",
            duration: "7 min",
            description: "Great aimers shoot at where enemies ARE, not where they were. Enemy players have predictable behaviors — peek timings, route preferences, post-kill repositioning habits. Learning to predict these patterns means your crosshair is pre-aimed before the enemy appears, turning reaction time from 300ms to near-zero.",
            tips: [
                "Watch where you died from repeatedly — enemies love proven positions",
                "After missing a shot, expect the enemy to take cover then re-peek within 1-2 seconds",
                "Players almost always move toward loot after a kill",
                "Pre-aim corners at head height — it eliminates the flick entirely"
            ],
            practiceMode: .sniperZeroing,
            quiz: [
                QuizQuestion(id: 1, question: "What does 'pre-aiming' mean?", options: ["Aiming after seeing an enemy", "Placing crosshair at predicted enemy position before they appear", "Using ADS at all times", "Shooting randomly in enemy direction"], correctIndex: 1, explanation: "Pre-aiming positions your crosshair at the expected enemy location before they're visible, reducing reaction time requirements."),
                QuizQuestion(id: 2, question: "What typically happens after a player misses a shot at an enemy?", options: ["The enemy always retreats permanently", "The enemy often takes cover then re-peeks within 1-2 seconds", "Nothing changes", "The enemy always pushes aggressively"], correctIndex: 1, explanation: "Most players instinctively take cover after being shot at, then re-peek to continue the fight — a predictable pattern you can exploit."),
                QuizQuestion(id: 3, question: "Why should crosshairs be at head height by default?", options: ["It looks better visually", "It eliminates or minimizes the flick distance to land headshots", "It only applies to snipers", "It only matters in close range"], correctIndex: 1, explanation: "Keeping your crosshair at head height means minimal adjustment is needed to land high-damage headshots on any enemy.")
            ]
        ),

        LessonItem(
            id: 3,
            icon: "iphone.radiowaves.left.and.right",
            title: "Device & Touch Optimization",
            level: "Beginner",
            duration: "5 min",
            description: "Your hardware is part of your aim system. Screen protectors add touch latency, dirty screens cause micro-drifts, and phone cases affect grip stability. Display refresh rate, touch sampling rate, and resolution all affect how responsive your aim feels. Optimizing these factors gives you a measurable competitive edge without changing your skill.",
            tips: [
                "Remove matte screen protectors — they add 10-20ms of touch latency",
                "Clean your screen before sessions to remove oils that cause drift",
                "Enable high-performance mode or game mode in device settings",
                "A stable grip with both hands beats aggressive one-handed play"
            ],
            practiceMode: .zoneLock,
            quiz: [
                QuizQuestion(id: 1, question: "What is one effect of matte screen protectors?", options: ["They improve accuracy", "They add 10-20ms of touch latency", "They increase screen brightness", "They have no effect on gameplay"], correctIndex: 1, explanation: "Matte screen protectors add a measurable touch latency of 10-20ms, which is significant in high-speed combat scenarios."),
                QuizQuestion(id: 2, question: "Why does a dirty screen affect aiming?", options: ["It makes the game look blurry", "Oils and debris cause micro-drifts in touch registration", "It has no effect", "It affects only visual clarity"], correctIndex: 1, explanation: "Oils and particles on the screen interfere with capacitive touch sensors, causing slight drift and inaccurate touch registration."),
                QuizQuestion(id: 3, question: "What grip style is most stable for mobile aiming?", options: ["One-handed grip", "Holding phone with fingertips only", "Stable two-handed grip", "Holding from the bottom edge"], correctIndex: 2, explanation: "A two-handed grip distributes weight and provides more anchor points, resulting in steadier aim and more precise micro-movements.")
            ]
        ),

        LessonItem(
            id: 4,
            icon: "bolt.fill",
            title: "Recoil Management Science",
            level: "Intermediate",
            duration: "8 min",
            description: "Every weapon has a recoil pattern — a predictable path the barrel travels when fired. Counter-recoil means moving your aim in the opposite direction at the exact right speed. Players who master this land more shots in sustained fights without needing a new target for each bullet. It's a physical skill built through repetition.",
            tips: [
                "Start by learning one weapon's recoil pattern completely before moving to another",
                "Fire in bursts of 3-5 rounds for medium range — it's more accurate than full spray",
                "Slower fire rate weapons are easier to control — train there first",
                "Vertical recoil is easier to counter than horizontal kick"
            ],
            practiceMode: .memoryGrid,
            quiz: [
                QuizQuestion(id: 1, question: "What does counter-recoil mean?", options: ["Switching weapons during fire", "Moving your aim opposite to the barrel's kick to keep it on target", "Only firing single shots", "Using attachments to reduce recoil"], correctIndex: 1, explanation: "Counter-recoil is the active technique of compensating for a weapon's kick by moving your aim in the opposite direction."),
                QuizQuestion(id: 2, question: "Why should you master one weapon's recoil before learning others?", options: ["Other weapons don't have recoil", "Each weapon has a unique pattern — mastering one builds muscle memory for that specific motion", "It doesn't matter — all weapons spray the same", "Recoil only applies to snipers"], correctIndex: 1, explanation: "Every weapon has a unique recoil fingerprint. Deeply mastering one pattern builds the muscle memory and mental framework to learn others faster."),
                QuizQuestion(id: 3, question: "What burst size is most accurate for medium range?", options: ["Single shots only", "Full-auto spray", "Bursts of 3-5 rounds", "It doesn't matter"], correctIndex: 2, explanation: "Bursts of 3-5 rounds allow the weapon to partially reset between groupings, maintaining tighter spread compared to full-auto fire.")
            ]
        ),

        LessonItem(
            id: 5,
            icon: "ear.fill",
            title: "Sound-Based Targeting",
            level: "Intermediate",
            duration: "8 min",
            description: "Your ears are pre-aiming tools. Footsteps, reload clicks, bush rustles, and gunshot echoes all encode direction and distance. Elite players aim their ears before aiming their crosshair — processing audio information lets you pre-position crosshair 0.5-1 second before visual confirmation. Sound is data, and ignoring it is throwing away a free information advantage.",
            tips: [
                "Use headphones — spatial audio is crucial and speakers flatten 3D sound",
                "Classify sounds immediately: enemy or environment?",
                "Reload sounds from enemies mean a ~2-second vulnerability window — push then",
                "Distant gunfire tells you where third-party threats are coming from"
            ],
            practiceMode: .phantomRush,
            quiz: [
                QuizQuestion(id: 1, question: "Why do reload sounds from enemies create an opportunity?", options: ["They sound satisfying", "The enemy cannot shoot during reload — roughly 2 seconds of vulnerability", "Reloads make enemies move slower", "They indicate the enemy is low on health"], correctIndex: 1, explanation: "A reloading enemy cannot fire for 1.5-3 seconds depending on weapon — a precise window to push or reposition aggressively."),
                QuizQuestion(id: 2, question: "What is the best audio setup for spatial awareness?", options: ["Speakers at max volume", "Headphones or earphones with stereo audio", "Mono audio is better", "Audio doesn't matter for mobile"], correctIndex: 1, explanation: "Headphones provide left-right stereo separation that helps you precisely locate the direction of footsteps and gunshots."),
                QuizQuestion(id: 3, question: "What does distant gunfire tell you?", options: ["That the match is ending", "Direction of potential third-party threats approaching", "Nothing useful", "That enemies have full health"], correctIndex: 1, explanation: "Distant gunfire indicates active fights in that direction — potential third parties who may rotate toward you or toward valuable loot.")
            ]
        ),

        LessonItem(
            id: 6,
            icon: "tuningfork",
            title: "Micro-Adjustment Technique",
            level: "Advanced",
            duration: "9 min",
            description: "The difference between a good aimer and an elite one is often micro-adjustments — the tiny corrections after the initial flick. Raw speed gets your crosshair to the target; micro-adjustments land it precisely. This requires a relaxed thumb, not a tense one. Tension kills micro-precision. Think of your thumb as a suspension system, not a hammer.",
            tips: [
                "After your initial flick, immediately relax thumb pressure for the fine correction",
                "Lower your ADS sensitivity specifically for scope adjustments",
                "Practice overshoot correction: flick past target, then gently drag back",
                "Micro-adjustments are invisible to others but add 15-25% accuracy"
            ],
            practiceMode: .neuralArc,
            quiz: [
                QuizQuestion(id: 1, question: "What kills micro-adjustment precision more than anything?", options: ["Low sensitivity settings", "Thumb tension and grip pressure during correction", "Not enough aim training", "Playing on an older device"], correctIndex: 1, explanation: "Muscle tension in your thumb prevents the fine, small movements needed for precision correction after an initial flick."),
                QuizQuestion(id: 2, question: "What is the correct thumb state for micro-adjustments?", options: ["Firm and pressing down hard", "Rigid and locked in position", "Relaxed, like a suspension system absorbing movement", "Lifted off the screen between shots"], correctIndex: 2, explanation: "A relaxed thumb allows fluid, tiny corrections. Tension creates rigid, jerky movements that overshoot or undershoot the target."),
                QuizQuestion(id: 3, question: "What sensitivity should you use specifically for scoped corrections?", options: ["Same as hip-fire sensitivity", "Higher than hip-fire", "Lower than hip-fire for better control", "No sensitivity setting affects scoped play"], correctIndex: 2, explanation: "ADS and scope sensitivity should be lower than hip-fire to allow fine-grained control when zoomed in on targets.")
            ]
        ),

        LessonItem(
            id: 7,
            icon: "metronome.fill",
            title: "Rhythm & Burst Discipline",
            level: "Advanced",
            duration: "10 min",
            description: "Uncontrolled fire is wasted ammo and given-away position. Rhythm-based firing — timed bursts synchronized with target movement cycles — creates consistent hit rates that random spraying never achieves. Top players develop an internal metronome: a subconscious tempo for when to fire, when to pause, and when to reposition.",
            tips: [
                "Fire when target is stationary or at direction-change moments",
                "Count your bullets — knowing when you're close to reload prevents 'click' moments",
                "Use predictive leading: fire slightly ahead of a strafing target",
                "Pause fire when you lose visual confirmation — you're just burning ammo"
            ],
            practiceMode: .pulseStrike,
            quiz: [
                QuizQuestion(id: 1, question: "When is the best time to fire at a strafing target?", options: ["Continuously throughout the strafe", "At direction-change moments when the target briefly slows", "Never — always wait for them to stop", "Only when ADS is fully zoomed"], correctIndex: 1, explanation: "A strafing player momentarily decelerates at each direction change — the brief window where they're slowest and easiest to hit."),
                QuizQuestion(id: 2, question: "What does 'predictive leading' mean?", options: ["Aiming at where the enemy currently is", "Firing slightly ahead of the enemy's movement direction", "Using a different weapon lead", "Aiming at the ground"], correctIndex: 1, explanation: "Predictive leading compensates for bullet travel and target movement — you fire at the predicted future position, not the current position."),
                QuizQuestion(id: 3, question: "Why should you pause fire when losing visual confirmation?", options: ["To save ammo for reload", "Firing without visual confirmation wastes ammo and reveals position without results", "It doesn't matter — keep firing", "To trigger enemy panic"], correctIndex: 1, explanation: "Firing blindly wastes ammunition and gives enemies your exact position via sound cues — strategic pausing prevents both problems.")
            ],
            isPremium: true
        ),

        LessonItem(
            id: 8,
            icon: "figure.run.circle.fill",
            title: "Endurance & Consistency",
            level: "Expert",
            duration: "11 min",
            description: "Skill in a single clip means nothing if you can't replicate it for two hours. Fatigue is the invisible enemy — hand cramps, eye strain, decision fatigue, and attention drift all degrade performance over time. Elite mobile players build physical endurance alongside game sense. Small habits compound into massive consistency advantages over a long session.",
            tips: [
                "Stretch fingers and wrists every 30 minutes — treat them like athlete equipment",
                "Eye fatigue reduces reaction time by up to 20% — take dark breaks",
                "Decision fatigue hits after 60-90 minutes — this is when to stop ranked, not grind harder",
                "Hydration measurably affects fine motor control — drink water during sessions"
            ],
            practiceMode: .dodgeShoot,
            quiz: [
                QuizQuestion(id: 1, question: "How much can eye fatigue reduce reaction time?", options: ["0-5%", "5-10%", "Up to 20%", "It has no measurable effect"], correctIndex: 2, explanation: "Research shows eye fatigue can reduce reaction time by up to 20% — a significant performance drop that accumulates over long sessions."),
                QuizQuestion(id: 2, question: "When is the worst time to push ranked matches?", options: ["After a warm-up session", "In the first 30 minutes of play", "After 60-90 minutes when decision fatigue sets in", "Early in the day"], correctIndex: 2, explanation: "Decision fatigue peaks at 60-90 minutes of play — your judgment, risk assessment, and split-second decisions all degrade significantly."),
                QuizQuestion(id: 3, question: "Why does hydration affect aiming performance?", options: ["It has no connection", "Dehydration causes muscle cramps and reduces fine motor precision", "It only affects stamina for physical sports", "Hydration only affects vision"], correctIndex: 1, explanation: "Even mild dehydration (1-2%) measurably reduces fine motor control and cognitive speed — both critical for precise mobile aiming.")
            ]
        ),
    ]
}
