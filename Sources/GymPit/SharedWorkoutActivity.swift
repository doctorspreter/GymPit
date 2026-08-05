import ActivityKit
import AppIntents
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var revision: Int
        var routineName: String
        var exerciseIDString: String
        var exerciseName: String
        var setText: String
        var setDetailText: String
        var progressText: String
        var elapsedText: String
        var workoutStartedAt: Date?
        var actionTitle: String
        var restEndDate: Date?
    }

    var planIDString: String
}

enum WorkoutActivitySnapshot {
    static func contentState(for plan: WorkoutPlan, restEndDate: Date? = nil) -> WorkoutActivityAttributes.ContentState? {
        guard plan.isWorkoutStarted else { return nil }
        let language = AppLanguage.current
        let activeExercise = plan.activeExercise
        guard let exercise = activeExercise ?? plan.completedExercises.last ?? plan.exercises.first else { return nil }

        let completedSets = exercise.completedSetsCount
        let totalSets = max(1, exercise.sets.count)
        let restEndDate = restEndDate.flatMap { $0 > Date() ? $0 : nil }
        let nextSetNumber = min(completedSets + 1, totalSets)
        let nextSet = activeExercise?.sets.first { !$0.isLogged }
        let displaySet = nextSet ?? exercise.sets.last

        return WorkoutActivityAttributes.ContentState(
            revision: WorkoutActivitySharedState.nextRevision(),
            routineName: plan.name,
            exerciseIDString: nextSet == nil ? "" : exercise.id.uuidString,
            exerciseName: exercise.localizedName(language: language),
            setText: nextSet == nil ? language.ui("Ziel erreicht") : "\(language.ui("Satz")) \(nextSetNumber)/\(totalSets)",
            setDetailText: displaySet.map { "\($0.reps)x \($0.weight.formattedWeight(unit: .current))" } ?? "-",
            progressText: plan.progressSummary(language: language),
            elapsedText: "\(Int(plan.actualDurationMinutes.rounded(.down))) min",
            workoutStartedAt: plan.workoutStartedAt,
            actionTitle: language.ui("Satz erledigt"),
            restEndDate: restEndDate
        )
    }
}

enum WorkoutActivitySharedState {
    private static let revisionKey = "gympit_live_activity_revision_v1"

    static func nextRevision() -> Int {
        let current = GymPitSharedStorage.defaults.integer(forKey: revisionKey)
        let next = current + 1
        GymPitSharedStorage.defaults.set(next, forKey: revisionKey)
        UserDefaults.standard.set(next, forKey: revisionKey)
        return next
    }

    static func loadPlan() -> WorkoutPlan? {
        guard let data = GymPitSharedStorage.data(forKey: WorkoutPersistenceKeys.plan) else { return nil }
        return try? JSONDecoder().decode(WorkoutPlan.self, from: data)
    }

    static func savePlan(_ plan: WorkoutPlan) {
        guard let data = try? JSONEncoder().encode(plan) else { return }
        GymPitSharedStorage.set(data, forKey: WorkoutPersistenceKeys.plan)
    }

    static func completeNextSet(exerciseIDString: String) -> WorkoutPlan? {
        guard let exerciseID = UUID(uuidString: exerciseIDString),
              var plan = loadPlan(),
              let exerciseIndex = plan.exercises.firstIndex(where: { $0.id == exerciseID }),
              !plan.completedExerciseIDs.contains(exerciseID),
              let setIndex = plan.exercises[exerciseIndex].sets.firstIndex(where: { !$0.isLogged }) else {
            return nil
        }

        plan.isWorkoutStarted = true
        plan.currentExerciseID = exerciseID
        plan.exercises[exerciseIndex].sets[setIndex].isLogged = true
        let exercise = plan.exercises[exerciseIndex]
        if exercise.sets.allSatisfy(\.isLogged) {
            if !plan.completedExerciseIDs.contains(exerciseID) {
                plan.completedExerciseIDs.append(exerciseID)
            }
            plan.currentExerciseID = plan.openExercises.first?.id
            plan.isCompletedSectionExpanded = false
            GymPitSharedStorage.set(nil as Date?, forKey: WorkoutPersistenceKeys.restEndDate)
        } else {
            GymPitSharedStorage.set(Date().addingTimeInterval(TimeInterval(exercise.restSeconds)), forKey: WorkoutPersistenceKeys.restEndDate)
        }
        savePlan(plan)
        return plan
    }

    static func skipRest(exerciseIDString: String) -> WorkoutPlan? {
        guard let exerciseID = UUID(uuidString: exerciseIDString),
              var plan = loadPlan(),
              plan.exercises.contains(where: { $0.id == exerciseID }),
              !plan.completedExerciseIDs.contains(exerciseID) else {
            return nil
        }

        plan.isWorkoutStarted = true
        plan.currentExerciseID = exerciseID
        GymPitSharedStorage.set(nil as Date?, forKey: WorkoutPersistenceKeys.restEndDate)
        savePlan(plan)
        return plan
    }

}

struct SkipWorkoutRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause überspringen"
    static var description = IntentDescription("Beendet die aktuelle Pause und macht den nächsten Satz bereit.")
    static var openAppWhenRun = false

    @Parameter(title: "Übung")
    var exerciseIDString: String

    init() {
        exerciseIDString = ""
    }

    init(exerciseIDString: String) {
        self.exerciseIDString = exerciseIDString
    }

    func perform() async throws -> some IntentResult {
        let plan = WorkoutActivitySharedState.skipRest(exerciseIDString: exerciseIDString)
        await WorkoutLiveActivityIntentUpdater.update(using: plan, restEndDate: nil)
        return .result()
    }
}

struct CompleteNextWorkoutSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Satz erledigt"
    static var description = IntentDescription("Markiert den nächsten offenen Satz als erledigt.")
    static var openAppWhenRun = false

    @Parameter(title: "Übung")
    var exerciseIDString: String

    init() {
        exerciseIDString = ""
    }

    init(exerciseIDString: String) {
        self.exerciseIDString = exerciseIDString
    }

    func perform() async throws -> some IntentResult {
        let plan = WorkoutActivitySharedState.completeNextSet(exerciseIDString: exerciseIDString)
        await WorkoutLiveActivityIntentUpdater.update(using: plan, restEndDate: GymPitSharedStorage.date(forKey: WorkoutPersistenceKeys.restEndDate))
        return .result()
    }
}

enum WorkoutLiveActivityIntentUpdater {
    static func update(using plan: WorkoutPlan?, restEndDate: Date?) async {
        guard let plan, let state = WorkoutActivitySnapshot.contentState(for: plan, restEndDate: restEndDate) else {
            for activity in Activity<WorkoutActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            return
        }

        let content = ActivityContent(state: state, staleDate: restEndDate)
        for activity in Activity<WorkoutActivityAttributes>.activities {
            await activity.update(content)
        }
    }
}
