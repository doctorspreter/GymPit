import SwiftUI

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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(language.ui("Bereit"))
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(plan.name)
                            .font(.headline)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 4)
                    ConnectionBadge(isReachable: store.isPhoneReachable)
                }

                HStack(spacing: 8) {
                    ReadyMetric(value: "\(plan.exercises.count)", title: language.ui("Übungen"))
                    ReadyMetric(value: "\(plan.exercises.reduce(0) { $0 + $1.sets.count })", title: language.ui("Sätze"))
                    ReadyMetric(value: "~\(plan.estimatedCalories)", title: "kcal")
                }

                Button {
                    store.startWorkout()
                    healthWorkout.startWorkout(named: plan.name)
                } label: {
                    Label(language.ui("Training starten"), systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Text(language.ui("Puls, aktive Kalorien und Trainingszeit werden mit Apple Health aufgezeichnet."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ExerciseQueue(exercises: plan.openExercises, currentExerciseID: plan.currentExerciseID)
            }
            .padding(.horizontal, 2)
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
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    ConnectionBadge(isReachable: store.isPhoneReachable)
                }

                Text(formattedDuration)
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.green)

                HStack(spacing: 8) {
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

                VStack(spacing: 4) {
                    HStack {
                        Text(plan.progressSummary(language: language))
                        Spacer()
                        Text("\(Int((plan.progressFraction * 100).rounded())) %")
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
            .padding(.horizontal, 4)
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
                    HStack(spacing: 7) {
                        Image(systemName: exercise.category.iconName)
                            .foregroundStyle(.green)
                        Text(exercise.localizedName(language: language))
                            .font(.headline)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }

                    if store.restRemainingSeconds > 0 {
                        RestPanel(seconds: store.restRemainingSeconds)
                    } else if let set = exercise.sets.first(where: { !$0.isLogged }),
                              let index = exercise.sets.firstIndex(where: { $0.id == set.id }) {
                        VStack(spacing: 5) {
                            Text("\(language.ui("Satz")) \(index + 1)/\(exercise.sets.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(setDescription(set))
                                .font(.title3.weight(.semibold))
                                .minimumScaleFactor(0.7)

                            NavigationLink {
                                SetEditorView(exercise: exercise, set: set)
                            } label: {
                                Label(language.ui("Anpassen"), systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                store.completeNextSet()
                            } label: {
                                Label(language.ui("Satz erledigt"), systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
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
            .padding(.horizontal, 4)
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
        VStack(spacing: 8) {
            Text(language.ui("Pause"))
                .font(.caption)
                .foregroundStyle(.orange)
            Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.orange)

            HStack(spacing: 8) {
                Button {
                    store.addRestTime(-15)
                } label: {
                    Text("−15")
                }
                .buttonStyle(.bordered)

                Button {
                    store.addRestTime(15)
                } label: {
                    Text("+15")
                }
                .buttonStyle(.bordered)
            }

            Button {
                store.skipRest()
            } label: {
                Label(language.ui("Überspringen"), systemImage: "forward.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
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
                    .font(.headline)
                ExerciseQueue(exercises: store.openExercises, currentExerciseID: plan.currentExerciseID)

                if !plan.completedExercises.isEmpty {
                    Text("\(language.ui("Erledigt")) · \(plan.completedExercises.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
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
                    .font(.headline)

                if healthWorkout.hasLiveWorkout {
                    Button {
                        healthWorkout.togglePause()
                    } label: {
                        Label(
                            healthWorkout.isPaused ? language.ui("Fortsetzen") : language.ui("Pausieren"),
                            systemImage: healthWorkout.isPaused ? "play.fill" : "pause.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    .disabled(healthWorkout.phase == .preparing || healthWorkout.phase == .ending)
                } else {
                    Button {
                        healthWorkout.startWorkout(named: plan.name)
                    } label: {
                        Label(language.ui("Health-Aufzeichnung starten"), systemImage: "heart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                Button(role: .destructive) {
                    confirmsEnd = true
                } label: {
                    Label(language.ui("Training beenden"), systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
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
            .padding(.horizontal, 4)
        }
    }
}

private struct SetEditorView: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    let set: ExerciseSet
    @State private var reps: Int
    @State private var displayWeight: Double
    private let language = AppLanguage.current

    init(exercise: Exercise, set: ExerciseSet) {
        self.exercise = exercise
        self.set = set
        _reps = State(initialValue: set.reps)
        _displayWeight = State(initialValue: WeightUnit.current.displayValue(fromKilograms: set.weight))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(exercise.localizedName(language: language))
                    .font(.headline)
                    .lineLimit(2)

                Stepper(value: $reps, in: 1...999) {
                    HStack {
                        Text(language.ui("Wdh"))
                        Spacer()
                        Text("\(reps)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.green)
                    }
                }

                Stepper(value: $displayWeight, in: 0...9999, step: weightStep) {
                    HStack {
                        Text(WeightUnit.current.symbol)
                        Spacer()
                        Text(displayWeight.formatted(.number.precision(.fractionLength(0...1))))
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.green)
                    }
                }

                Button(language.ui("Übernehmen")) {
                    store.updateCurrentSet(
                        reps: reps,
                        weight: WeightUnit.current.kilograms(fromDisplayValue: displayWeight)
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(language.ui("Satz anpassen"))
    }

    private var weightStep: Double {
        WeightUnit.current == .kilograms ? 0.5 : 1
    }
}

private struct ExerciseQueue: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    let exercises: [Exercise]
    let currentExerciseID: UUID?
    private let language = AppLanguage.current

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(exercises) { exercise in
                Button {
                    store.select(exercise)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: exercise.id == currentExerciseID ? "circle.inset.filled" : "circle")
                            .font(.caption2)
                            .foregroundStyle(exercise.id == currentExerciseID ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(exercise.localizedName(language: language))
                                .font(.caption.weight(.semibold))
                                .lineLimit(2)
                            Text("\(exercise.completedSetsCount)/\(exercise.sets.count) \(language.ui("Sätze"))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 5)
            }
        }
    }
}

private struct LiveMetric: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
            Text(unit)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ReadyMetric: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
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
