import SwiftUI

// MARK: - Shared style

private enum WatchStyle {
    /// Solid card fill. `.thinMaterial` disappears on the OLED black background,
    /// so cards use an explicit light overlay instead.
    static let cardFill = Color.white.opacity(0.12)
    static let cardFillStrong = Color.white.opacity(0.18)
    static let cornerRadius: CGFloat = 12
    /// Keeps scrollable content clear of the page indicator dots.
    static let pageBottomInset: CGFloat = 20
}

private struct WatchCard<Content: View>: View {
    var fill: Color = WatchStyle.cardFill
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(fill, in: RoundedRectangle(cornerRadius: WatchStyle.cornerRadius, style: .continuous))
    }
}

struct WatchContentView: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    private let language = AppLanguage.current

    var body: some View {
        NavigationStack {
            Group {
                if let plan = store.plan {
                    if plan.exercises.isEmpty {
                        EmptyWatchState(
                            iconName: "list.bullet.clipboard",
                            title: language.ui("Noch keine Übungen geplant."),
                            message: language.ui("Öffne die iPhone-App und stelle dein Training zusammen.")
                        )
                    } else if plan.isWorkoutStarted {
                        ActiveWorkoutView(plan: plan)
                    } else {
                        ReadyWorkoutView(plan: plan)
                    }
                } else {
                    EmptyWatchState(
                        iconName: "iphone",
                        title: "GymPit",
                        message: language.ui("Öffne die iPhone-App, damit dein Training auf der Watch erscheint.")
                    )
                }
            }
            .toolbar {
                if store.plan?.isWorkoutStarted != true {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            store.requestState()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel(language.ui("Aktualisieren"))
                    }
                }
            }
        }
    }
}

private struct ReadyWorkoutView: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    @EnvironmentObject private var healthWorkout: WatchHealthWorkoutManager
    let plan: WorkoutPlan
    private let language = AppLanguage.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(language.ui("Bereit"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    Spacer(minLength: 4)
                    ConnectionBadge(isReachable: store.isPhoneReachable)
                }

                Text(plan.name)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    ReadyMetric(value: "\(plan.exercises.count)", title: language.ui("Übungen"))
                    ReadyMetric(value: "\(plan.exercises.reduce(0) { $0 + $1.sets.count })", title: language.ui("Sätze"))
                    ReadyMetric(value: "~\(plan.estimatedCalories)", title: "kcal")
                }

                Button {
                    store.startWorkout()
                    healthWorkout.startWorkout(named: plan.name)
                } label: {
                    Label(language.ui("Training starten"), systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Text(language.ui("Puls, aktive Kalorien und Trainingszeit werden mit Apple Health aufgezeichnet."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(language.ui("Übungen"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                ExerciseQueue(exercises: plan.openExercises, currentExerciseID: plan.currentExerciseID)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .navigationTitle(language.ui("Training"))
    }
}

private struct ActiveWorkoutView: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    @EnvironmentObject private var healthWorkout: WatchHealthWorkoutManager
    @State private var selectedPage = 1
    @State private var confirmsEnd = false
    let plan: WorkoutPlan

    var body: some View {
        TabView(selection: $selectedPage) {
            WorkoutMetricsPage(plan: plan)
                .tag(0)

            CurrentExercisePage(plan: plan)
                .tag(1)

            WorkoutQueuePage(plan: plan)
                .tag(2)

            WorkoutControlsPage(plan: plan, confirmsEnd: $confirmsEnd)
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            AppLanguage.current.ui("Training wirklich beenden?"),
            isPresented: $confirmsEnd,
            titleVisibility: .visible
        ) {
            Button(AppLanguage.current.ui("Training beenden"), role: .destructive) {
                finishWorkout()
            }
            Button(AppLanguage.current.ui("Abbrechen"), role: .cancel) {}
        }
    }

    private func finishWorkout() {
        if healthWorkout.hasLiveWorkout {
            healthWorkout.endWorkout { summary in
                store.endWorkout(summary: summary)
            }
        } else {
            store.endWorkout()
        }
    }
}

private struct WorkoutMetricsPage: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    @EnvironmentObject private var healthWorkout: WatchHealthWorkoutManager
    let plan: WorkoutPlan
    private let language = AppLanguage.current

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Text(plan.name)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    ConnectionBadge(isReachable: store.isPhoneReachable)
                }

                Text(formattedDuration)
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(.green)

                HStack(spacing: 6) {
                    LiveMetric(
                        icon: "heart.fill",
                        color: .red,
                        value: healthWorkout.heartRate > 0 ? "\(Int(healthWorkout.heartRate.rounded()))" : "--",
                        unit: "BPM"
                    )
                    LiveMetric(
                        icon: "flame.fill",
                        color: .orange,
                        value: "\(Int(healthWorkout.activeCalories.rounded()))",
                        unit: "KCAL"
                    )
                }

                VStack(spacing: 5) {
                    HStack {
                        Text(plan.progressSummary(language: language))
                        Spacer(minLength: 4)
                        Text("\(Int((plan.progressFraction * 100).rounded())) %")
                            .monospacedDigit()
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    ProgressView(value: plan.progressFraction)
                        .tint(.green)
                }

                if healthWorkout.isPaused {
                    Label(language.ui("Training pausiert"), systemImage: "pause.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.yellow)
                } else if case .failed = healthWorkout.phase {
                    Label(language.ui("Health-Aufzeichnung aus"), systemImage: "heart.slash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, WatchStyle.pageBottomInset)
        }
    }

    private var formattedDuration: String {
        let healthSeconds = Int(healthWorkout.elapsedSeconds.rounded(.down))
        let seconds = healthSeconds > 0
            ? healthSeconds
            : Int(max(0, plan.actualDurationMinutes * 60).rounded(.down))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct CurrentExercisePage: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    let plan: WorkoutPlan
    private let language = AppLanguage.current

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let exercise = plan.activeExercise {
                    let isResting = store.restRemainingSeconds > 0
                    // The rest timer owns the whole screen: dropping the header
                    // is what keeps "Skip" clear of the page indicator dots.
                    if !isResting {
                        HStack(spacing: 6) {
                            Image(systemName: exercise.category.iconName)
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(exercise.localizedName(language: language))
                                .font(.headline)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                        }
                    }

                    if isResting {
                        RestPanel(seconds: store.restRemainingSeconds)
                    } else if let set = exercise.sets.first(where: { !$0.isLogged }),
                              let index = exercise.sets.firstIndex(where: { $0.id == set.id }) {
                        VStack(spacing: 8) {
                            WatchCard {
                                VStack(spacing: 2) {
                                    Text("\(language.ui("Satz")) \(index + 1)/\(exercise.sets.count)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(setDescription(set))
                                        .font(.title3.weight(.semibold))
                                        .minimumScaleFactor(0.6)
                                        .lineLimit(1)
                                }
                            }

                            Button {
                                store.completeNextSet()
                            } label: {
                                Label(language.ui("Satz erledigt"), systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)

                            NavigationLink {
                                SetEditorView(exercise: exercise, set: set)
                            } label: {
                                Label(language.ui("Anpassen"), systemImage: "slider.horizontal.3")
                                    .frame(maxWidth: .infinity, minHeight: 36)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if !exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Label(exercise.notes, systemImage: "note.text")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    EmptyWatchState(
                        iconName: "checkmark.seal",
                        title: language.ui("Keine weiteren Übungen"),
                        message: language.ui("Beende das Training, damit es gespeichert wird.")
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, WatchStyle.pageBottomInset)
        }
    }

    private func setDescription(_ set: ExerciseSet) -> String {
        let weight = set.weight > 0 ? " × \(set.weight.formattedWeight(unit: .current))" : ""
        return "\(set.reps) \(language.ui("Wdh"))\(weight)"
    }
}

private struct RestPanel: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    let seconds: Int
    private let language = AppLanguage.current

    var body: some View {
        VStack(spacing: 6) {
            Text(language.ui("Pause"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange)
            Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(.orange)

            HStack(spacing: 6) {
                RestAdjustButton(title: "−15") { store.addRestTime(-15) }
                RestAdjustButton(title: "+15") { store.addRestTime(15) }
            }

            Button {
                store.skipRest()
            } label: {
                Label(language.ui("Überspringen"), systemImage: "forward.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 38)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
    }
}

private struct RestAdjustButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.monospacedDigit())
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
    }
}

private struct WorkoutQueuePage: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    let plan: WorkoutPlan
    private let language = AppLanguage.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(language.ui("Übungen"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ExerciseQueue(exercises: store.openExercises, currentExerciseID: plan.currentExerciseID)

                if !plan.completedExercises.isEmpty {
                    Text("\(language.ui("Erledigt")) · \(plan.completedExercises.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, WatchStyle.pageBottomInset)
        }
    }
}

private struct WorkoutControlsPage: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    @EnvironmentObject private var healthWorkout: WatchHealthWorkoutManager
    let plan: WorkoutPlan
    @Binding var confirmsEnd: Bool
    private let language = AppLanguage.current

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(language.ui("Steuerung"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if healthWorkout.hasLiveWorkout {
                    Button {
                        healthWorkout.togglePause()
                    } label: {
                        Label(
                            healthWorkout.isPaused ? language.ui("Fortsetzen") : language.ui("Pausieren"),
                            systemImage: healthWorkout.isPaused ? "play.fill" : "pause.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    .disabled(healthWorkout.phase == .preparing || healthWorkout.phase == .ending)
                } else {
                    Button {
                        healthWorkout.startWorkout(named: plan.name)
                    } label: {
                        Label(language.ui("Health-Aufzeichnung starten"), systemImage: "heart.fill")
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                Button(role: .destructive) {
                    confirmsEnd = true
                } label: {
                    Label(language.ui("Training beenden"), systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.bordered)

                Label(
                    store.isPhoneReachable ? language.ui("iPhone verbunden") : language.ui("Offline · wird später synchronisiert"),
                    systemImage: store.isPhoneReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

                if case .failed(let message) = healthWorkout.phase {
                    Text(message)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, WatchStyle.pageBottomInset)
        }
    }
}

// MARK: - Set editor

private struct SetEditorView: View {
    private enum Field: Hashable {
        case reps
        case weight
    }

    @EnvironmentObject private var store: WatchWorkoutStore
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    let set: ExerciseSet
    @State private var reps: Double
    @State private var displayWeight: Double
    @FocusState private var focus: Field?
    private let language = AppLanguage.current
    private let unit = WeightUnit.current

    init(exercise: Exercise, set: ExerciseSet) {
        self.exercise = exercise
        self.set = set
        _reps = State(initialValue: Double(set.reps))
        _displayWeight = State(initialValue: WeightUnit.current.displayValue(fromKilograms: set.weight))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(exercise.localizedName(language: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ValueTuner(
                    title: language.ui("Wdh"),
                    display: "\(Int(reps.rounded()))",
                    isFocused: focus == .reps,
                    onDecrement: { adjustReps(-1) },
                    onIncrement: { adjustReps(1) }
                )
                .focusable()
                .focused($focus, equals: .reps)
                .digitalCrownRotation(
                    $reps,
                    from: 1,
                    through: 999,
                    by: 1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )

                ValueTuner(
                    title: unit.symbol,
                    display: displayWeight.formatted(.number.precision(.fractionLength(0...2))),
                    isFocused: focus == .weight,
                    onDecrement: { adjustWeight(-weightStep) },
                    onIncrement: { adjustWeight(weightStep) }
                )
                .focusable()
                .focused($focus, equals: .weight)
                .digitalCrownRotation(
                    $displayWeight,
                    from: 0,
                    through: 9999,
                    by: weightStep,
                    sensitivity: .low,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )

                Text("\(language.ui("Schritt")) · \(WeightIncrement.label(kilograms: exercise.weightIncrement, unit: unit))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button {
                    store.updateCurrentSet(
                        reps: Int(reps.rounded()),
                        weight: unit.kilograms(fromDisplayValue: displayWeight)
                    )
                    dismiss()
                } label: {
                    Label(language.ui("Übernehmen"), systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .navigationTitle(language.ui("Satz anpassen"))
        .onAppear { focus = .reps }
    }

    private func adjustReps(_ delta: Double) {
        focus = .reps
        reps = min(999, max(1, (reps + delta).rounded()))
    }

    /// Moves to the next value the machine can be set to. A weight that sits
    /// off the grid (say 57.5 on a 5 kg stack) snaps to 60 up / 55 down rather
    /// than jumping a full step past the nearest notch.
    private func adjustWeight(_ delta: Double) {
        focus = .weight
        let epsilon = weightStep / 100
        let notches = delta > 0
            ? ((displayWeight + epsilon) / weightStep).rounded(.down) + 1
            : ((displayWeight - epsilon) / weightStep).rounded(.up) - 1
        displayWeight = min(9999, max(0, notches * weightStep))
    }

    /// The machine's own step, converted into the unit shown. Both the ± buttons
    /// and the Digital Crown use it, so the watch can only produce weights the
    /// machine can actually be set to.
    private var weightStep: Double {
        let step = unit.displayValue(fromKilograms: exercise.weightIncrement)
        return step > 0 ? step : 1
    }
}

/// Big centred value with a ± button on each side. Replaces `Stepper`, whose
/// label wraps unreadably at watch widths.
private struct ValueTuner: View {
    let title: String
    let display: String
    let isFocused: Bool
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isFocused ? Color.green : Color.secondary)
                .lineLimit(1)

            HStack(spacing: 6) {
                TunerButton(icon: "minus", action: onDecrement)

                Text(display)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)

                TunerButton(icon: "plus", action: onIncrement)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: WatchStyle.cornerRadius, style: .continuous)
                .fill(isFocused ? WatchStyle.cardFillStrong : WatchStyle.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: WatchStyle.cornerRadius, style: .continuous)
                .strokeBorder(isFocused ? Color.green : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(display)")
    }
}

private struct TunerButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.bold))
                .frame(width: 38, height: 38)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(Color.white.opacity(0.22), in: Circle())
    }
}

// MARK: - Queue

private struct ExerciseQueue: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    let exercises: [Exercise]
    let currentExerciseID: UUID?
    private let language = AppLanguage.current

    var body: some View {
        VStack(spacing: 6) {
            ForEach(exercises) { exercise in
                let isCurrent = exercise.id == currentExerciseID
                Button {
                    store.select(exercise)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isCurrent ? "circle.inset.filled" : "circle")
                            .font(.caption)
                            .foregroundStyle(isCurrent ? Color.green : Color.secondary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(exercise.localizedName(language: language))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text("\(exercise.completedSetsCount)/\(exercise.sets.count) \(language.ui("Sätze"))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: WatchStyle.cornerRadius, style: .continuous)
                            .fill(isCurrent ? Color.green.opacity(0.22) : WatchStyle.cardFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: WatchStyle.cornerRadius, style: .continuous)
                            .strokeBorder(isCurrent ? Color.green : Color.clear, lineWidth: 1.5)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: WatchStyle.cornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Small pieces

private struct LiveMetric: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String

    var body: some View {
        WatchCard {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

private struct ReadyMetric: View {
    let value: String
    let title: String

    var body: some View {
        WatchCard {
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline.monospacedDigit())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
    }
}

private struct ConnectionBadge: View {
    let isReachable: Bool

    var body: some View {
        Image(systemName: isReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash")
            .font(.caption2)
            .foregroundStyle(isReachable ? .green : .secondary)
            .accessibilityLabel(isReachable ? "iPhone verbunden" : "iPhone offline")
    }
}

private struct EmptyWatchState: View {
    let iconName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.green)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
