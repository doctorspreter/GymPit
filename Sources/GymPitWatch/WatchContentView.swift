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

private struct ReadyWorkoutView: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    let plan: WorkoutPlan
    private let language = AppLanguage.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Header(plan: plan)

                Button {
                    store.startWorkout()
                } label: {
                    Label(language.ui("Training starten"), systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                ExerciseList(exercises: plan.openExercises, currentExerciseID: plan.currentExerciseID)
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle(language.ui("Training"))
    }
}

private struct ActiveWorkoutView: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    let plan: WorkoutPlan
    private let language = AppLanguage.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Header(plan: plan)

                if let exercise = plan.activeExercise {
                    ActiveExerciseCard(exercise: exercise, restRemainingSeconds: store.restRemainingSeconds)

                    Button {
                        store.completeNextSet()
                    } label: {
                        Label(language.ui("Satz erledigt"), systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    if store.restRemainingSeconds > 0 {
                        Button {
                            store.skipRest()
                        } label: {
                            Label(language.ui("Pause überspringen"), systemImage: "forward.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    EmptyWatchState(
                        iconName: "checkmark.seal",
                        title: language.ui("Keine weiteren Übungen"),
                        message: language.ui("Beende das Training, damit es auf dem iPhone gespeichert wird.")
                    )
                }

                ExerciseList(exercises: store.openExercises, currentExerciseID: plan.currentExerciseID)

                Button(role: .destructive) {
                    store.endWorkout()
                } label: {
                    Label(language.ui("Training beenden"), systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle(language.ui("Aktiv"))
    }
}

private struct Header: View {
    let plan: WorkoutPlan
    private let language = AppLanguage.current

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 6)
                Text("\(Int((plan.progressFraction * 100).rounded()))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: plan.progressFraction)
                .tint(.green)

            HStack {
                Label(plan.progressSummary(language: language), systemImage: "chart.bar.fill")
                Spacer()
                Label("\(Int(plan.actualDurationMinutes.rounded(.down))) min", systemImage: "timer")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(language.ui("Training")) \(plan.name), \(plan.progressSummary(language: language))")
    }
}

private struct ActiveExerciseCard: View {
    let exercise: Exercise
    let restRemainingSeconds: Int
    private let language = AppLanguage.current

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: exercise.category.iconName)
                    .foregroundStyle(.green)
                Text(exercise.localizedName(language: language))
                    .font(.headline)
                    .lineLimit(2)
            }

            Text(nextSetText)
                .font(.title3.weight(.semibold))

            Text(setDetailText)
                .font(.caption)
                .foregroundStyle(.secondary)

            if restRemainingSeconds > 0 {
                Label(restText, systemImage: "timer")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var nextSetText: String {
        guard let index = exercise.sets.firstIndex(where: { !$0.isLogged }) else {
            return language.ui("alle Sätze erledigt")
        }
        return "\(language.ui("Satz")) \(index + 1)/\(exercise.sets.count)"
    }

    private var setDetailText: String {
        guard let set = exercise.sets.first(where: { !$0.isLogged }) ?? exercise.sets.last else { return "-" }
        let weight = set.weight > 0 ? " · \(set.weight.formattedWeight(unit: .current))" : ""
        return "\(set.reps) \(language.ui("Wdh"))\(weight)"
    }

    private var restText: String {
        let minutes = restRemainingSeconds / 60
        let seconds = restRemainingSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

private struct ExerciseList: View {
    @EnvironmentObject private var store: WatchWorkoutStore
    let exercises: [Exercise]
    let currentExerciseID: UUID?
    private let language = AppLanguage.current

    var body: some View {
        if !exercises.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(language.ui("Offen"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(exercises) { exercise in
                    Button {
                        store.select(exercise)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: exercise.id == currentExerciseID ? "circle.fill" : "circle")
                                .font(.caption2)
                                .foregroundStyle(exercise.id == currentExerciseID ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.localizedName(language: language))
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(2)
                                Text("\(exercise.completedSetsCount)/\(exercise.sets.count) \(language.ui("Sätze"))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 5)
                }
            }
        }
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
