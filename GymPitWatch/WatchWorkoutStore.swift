import Foundation
import WatchConnectivity

@MainActor
final class WatchWorkoutStore: NSObject, ObservableObject {
    @Published private(set) var plan: WorkoutPlan?
    @Published private(set) var restRemainingSeconds = 0
    @Published private(set) var isPhoneReachable = false
    @Published private(set) var lastSyncedAt: Date?

    private var restEndDate: Date?
    private var timer: Timer?

    override init() {
        super.init()
        loadLocalState()
        activateConnectivity()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    var activeExercise: Exercise? {
        plan?.activeExercise
    }

    var openExercises: [Exercise] {
        plan?.openExercises ?? []
    }

    func requestState() {
        send(command: "requestState")
    }

    func startWorkout() {
        mutatePlan { plan in
            if hasLoggedProgress(in: plan) || !plan.completedExerciseIDs.isEmpty || plan.archivedSessionID != nil {
                prepareForNextWorkout(&plan)
            }
            plan.isWorkoutStarted = true
            plan.workoutStartedAt = Date()
            plan.archivedSessionID = nil
            if plan.currentExerciseID == nil || plan.completedExerciseIDs.contains(where: { $0 == plan.currentExerciseID }) {
                plan.currentExerciseID = plan.openExercises.first?.id
            }
        }
        send(command: "startWorkout")
    }

    func select(_ exercise: Exercise) {
        mutatePlan { plan in
            guard !plan.completedExerciseIDs.contains(exercise.id) else { return }
            plan.isWorkoutStarted = true
            plan.currentExerciseID = exercise.id
        }
        send(command: "selectExercise", exerciseID: exercise.id)
    }

    func completeNextSet() {
        guard let exerciseID = activeExercise?.id else { return }
        mutatePlan { plan in
            completeNextSet(exerciseID: exerciseID, in: &plan)
        }
        send(command: "completeNextSet", exerciseID: exerciseID)
    }

    func skipRest() {
        guard let exerciseID = activeExercise?.id else { return }
        restEndDate = nil
        restRemainingSeconds = 0
        GymPitSharedStorage.set(nil as Date?, forKey: WorkoutPersistenceKeys.restEndDate)
        mutatePlan { plan in
            plan.isWorkoutStarted = true
            plan.currentExerciseID = exerciseID
        }
        send(command: "skipRest", exerciseID: exerciseID)
    }

    func endWorkout() {
        mutatePlan { plan in
            prepareForNextWorkout(&plan)
        }
        restEndDate = nil
        restRemainingSeconds = 0
        GymPitSharedStorage.set(nil as Date?, forKey: WorkoutPersistenceKeys.restEndDate)
        send(command: "endWorkout")
    }

    private func activateConnectivity() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func send(command: String, exerciseID: UUID? = nil) {
        guard WCSession.isSupported() else { return }
        var message: [String: Any] = ["command": command]
        if let exerciseID {
            message["exerciseID"] = exerciseID.uuidString
        }

        let session = WCSession.default
        guard session.activationState == .activated else { return }
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(message)
        }
    }

    private func handleStatePayload(_ payload: [String: Any]) {
        guard payload["type"] as? String == "state",
              let data = payload["planData"] as? Data,
              let incomingPlan = try? JSONDecoder().decode(WorkoutPlan.self, from: data) else { return }

        plan = incomingPlan
        GymPitSharedStorage.set(data, forKey: WorkoutPersistenceKeys.plan)

        if let timestamp = payload["restEndTimestamp"] as? Double, timestamp > 0 {
            restEndDate = Date(timeIntervalSince1970: timestamp)
            GymPitSharedStorage.set(restEndDate, forKey: WorkoutPersistenceKeys.restEndDate)
        } else {
            restEndDate = nil
            GymPitSharedStorage.set(nil as Date?, forKey: WorkoutPersistenceKeys.restEndDate)
        }

        lastSyncedAt = Date()
        updateRestRemaining()
    }

    private func loadLocalState() {
        if let data = GymPitSharedStorage.data(forKey: WorkoutPersistenceKeys.plan),
           let savedPlan = try? JSONDecoder().decode(WorkoutPlan.self, from: data) {
            plan = savedPlan
        }
        restEndDate = GymPitSharedStorage.date(forKey: WorkoutPersistenceKeys.restEndDate)
        updateRestRemaining()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRestRemaining()
            }
        }
    }

    private func updateRestRemaining() {
        guard let restEndDate, restEndDate > Date() else {
            restRemainingSeconds = 0
            self.restEndDate = nil
            return
        }
        restRemainingSeconds = Int(restEndDate.timeIntervalSinceNow.rounded(.up))
    }

    private func mutatePlan(_ mutation: (inout WorkoutPlan) -> Void) {
        guard var updatedPlan = plan else { return }
        mutation(&updatedPlan)
        plan = updatedPlan
        if let data = try? JSONEncoder().encode(updatedPlan) {
            GymPitSharedStorage.set(data, forKey: WorkoutPersistenceKeys.plan)
        }
        lastSyncedAt = Date()
        updateRestRemaining()
    }

    private func completeNextSet(exerciseID: UUID, in plan: inout WorkoutPlan) {
        guard let exerciseIndex = plan.exercises.firstIndex(where: { $0.id == exerciseID }),
              !plan.completedExerciseIDs.contains(exerciseID),
              let setIndex = plan.exercises[exerciseIndex].sets.firstIndex(where: { !$0.isLogged }) else { return }

        plan.isWorkoutStarted = true
        plan.currentExerciseID = exerciseID
        plan.exercises[exerciseIndex].sets[setIndex].isLogged = true

        let exercise = plan.exercises[exerciseIndex]
        if exercise.sets.allSatisfy(\.isLogged) {
            restEndDate = nil
            restRemainingSeconds = 0
            GymPitSharedStorage.set(nil as Date?, forKey: WorkoutPersistenceKeys.restEndDate)
            if !plan.completedExerciseIDs.contains(exerciseID) {
                plan.completedExerciseIDs.append(exerciseID)
            }
            plan.currentExerciseID = plan.openExercises.first?.id
            plan.isCompletedSectionExpanded = false
        } else {
            restEndDate = Date().addingTimeInterval(TimeInterval(exercise.restSeconds))
            GymPitSharedStorage.set(restEndDate, forKey: WorkoutPersistenceKeys.restEndDate)
        }

        if plan.isFinished {
            plan.isWorkoutStarted = false
            restEndDate = nil
            restRemainingSeconds = 0
            GymPitSharedStorage.set(nil as Date?, forKey: WorkoutPersistenceKeys.restEndDate)
        }
    }

    private func hasLoggedProgress(in plan: WorkoutPlan) -> Bool {
        plan.exercises.contains { exercise in
            exercise.sets.contains(where: \.isLogged)
        }
    }

    private func prepareForNextWorkout(_ plan: inout WorkoutPlan) {
        plan.currentExerciseID = plan.exercises.first?.id
        plan.completedExerciseIDs = []
        plan.isCompletedSectionExpanded = false
        plan.archivedSessionID = nil
        plan.isWorkoutStarted = false
        plan.workoutStartedAt = nil
        plan.exercises = plan.exercises.map { exercise in
            var updated = exercise
            updated.sets = updated.sets.map {
                ExerciseSet(id: $0.id, type: $0.type, reps: $0.reps, weight: $0.weight, rpe: $0.rpe, isLogged: false)
            }
            return updated
        }
    }
}

extension WatchWorkoutStore: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            isPhoneReachable = session.isReachable
            requestState()
            handleStatePayload(session.applicationContext)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isPhoneReachable = session.isReachable
            if session.isReachable {
                requestState()
            }
        }
    }

#if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
#endif

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            handleStatePayload(applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handleStatePayload(message)
        }
    }
}
