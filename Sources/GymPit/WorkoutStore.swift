import Foundation
import UserNotifications

@MainActor
final class WorkoutRestTimerState: ObservableObject {
    @Published private(set) var remainingSeconds = 0

    func update(remainingSeconds: Int) {
        let normalizedValue = max(0, remainingSeconds)
        guard normalizedValue != self.remainingSeconds else { return }
        self.remainingSeconds = normalizedValue
    }
}

struct WorkoutCSVImportSummary: Equatable {
    let imported: Int
    let skipped: Int
    let rows: Int
}

struct WorkoutDataArchive: Codable {
    let format: String
    let version: Int
    let exportedAt: Date
    let sessions: [WorkoutSession]
    let routines: [WorkoutPlan]
    let defaultRoutineID: UUID?
}

struct WorkoutDataImportSummary: Equatable {
    let sessions: WorkoutCSVImportSummary
    let routinesImported: Int
    let routinesSkipped: Int
}

enum WorkoutDataArchiveCodec {
    private static let format = "gympit-data"

    static func export(
        sessions: [WorkoutSession],
        routines: [WorkoutPlan],
        defaultRoutineID: UUID?
    ) throws -> Data {
        let archive = WorkoutDataArchive(
            format: format,
            version: 1,
            exportedAt: Date(),
            sessions: sessions,
            routines: routines,
            defaultRoutineID: defaultRoutineID
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(archive)
    }

    static func importArchive(from data: Data) throws -> WorkoutDataArchive {
        let archive = try JSONDecoder().decode(WorkoutDataArchive.self, from: data)
        guard archive.format == format, archive.version == 1 else {
            throw WorkoutDataArchiveError.unsupportedFormat
        }
        return archive
    }
}

enum WorkoutDataArchiveError: LocalizedError {
    case unsupportedFormat

    var errorDescription: String? {
        "Die Datei ist kein unterstützter GymPit-Datenexport."
    }
}

struct ExerciseWeightIncrease: Equatable {
    let date: Date
    let weight: Double
}

struct ExerciseWeightUsage: Equatable {
    let weight: Double
    let consecutiveWorkouts: Int
}

enum WorkoutCSVError: LocalizedError {
    case invalidEncoding
    case missingColumns

    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            "Die CSV-Datei konnte nicht als Text gelesen werden."
        case .missingColumns:
            "Die CSV-Datei enthält nicht die erwarteten Trainings-Spalten."
        }
    }
}

enum WorkoutCSVCodec {
    private static let headers = [
        "training_id",
        "training_date",
        "training_name",
        "duration_minutes",
        "calories",
        "training_notes",
        "exercise_id",
        "catalog_id",
        "exercise_name",
        "category",
        "exercise_notes",
        "set_id",
        "set_index",
        "set_type",
        "reps",
        "weight",
        "rpe"
    ]

    static func export(_ sessions: [WorkoutSession]) -> String {
        var rows = [headers]

        for session in sessions {
            for exercise in session.exercises {
                for (setIndex, set) in exercise.sets.enumerated() {
                    rows.append([
                        session.id.uuidString,
                        dateFormatter.string(from: session.date),
                        session.planName,
                        String(session.durationMinutes),
                        String(session.calories),
                        session.notes,
                        exercise.id.uuidString,
                        exercise.catalogID,
                        exercise.name,
                        exercise.category.rawValue,
                        exercise.notes,
                        set.id.uuidString,
                        String(setIndex + 1),
                        set.type.rawValue,
                        String(set.reps),
                        String(set.weight),
                        set.rpe.map(String.init) ?? ""
                    ])
                }
            }
        }

        return rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\n")
    }

    static func importSessions(from data: Data) throws -> [WorkoutSession] {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
            throw WorkoutCSVError.invalidEncoding
        }

        let rows = parse(text)
        guard let header = rows.first else { return [] }
        let columnIndex = columnIndex(for: header)
        guard headers.allSatisfy({ columnIndex[$0] != nil }) else {
            throw WorkoutCSVError.missingColumns
        }

        var sessionBuilders: [UUID: SessionBuilder] = [:]
        var sessionOrder: [UUID] = []

        for row in rows.dropFirst() where !row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            let sessionID = uuid(value("training_id", in: row, using: columnIndex))
            if sessionBuilders[sessionID] == nil {
                sessionOrder.append(sessionID)
                sessionBuilders[sessionID] = SessionBuilder(
                    id: sessionID,
                    planName: value("training_name", in: row, using: columnIndex),
                    date: date(value("training_date", in: row, using: columnIndex)),
                    notes: value("training_notes", in: row, using: columnIndex),
                    durationMinutes: double(value("duration_minutes", in: row, using: columnIndex)),
                    calories: int(value("calories", in: row, using: columnIndex))
                )
            }

            let exerciseID = uuid(value("exercise_id", in: row, using: columnIndex))
            let set = WorkoutSessionSet(
                id: uuid(value("set_id", in: row, using: columnIndex)),
                type: WorkoutSetType(rawValue: value("set_type", in: row, using: columnIndex)) ?? .normal,
                reps: int(value("reps", in: row, using: columnIndex)),
                weight: double(value("weight", in: row, using: columnIndex)),
                rpe: optionalInt(value("rpe", in: row, using: columnIndex))
            )

            sessionBuilders[sessionID]?.append(
                set,
                toExerciseID: exerciseID,
                catalogID: value("catalog_id", in: row, using: columnIndex),
                name: value("exercise_name", in: row, using: columnIndex),
                category: DeviceCategory(rawValue: value("category", in: row, using: columnIndex)) ?? .freeWeights,
                notes: value("exercise_notes", in: row, using: columnIndex)
            )
        }

        return sessionOrder.compactMap { sessionBuilders[$0]?.session }
    }

    static func signature(for session: WorkoutSession) -> String {
        [
            String(Int(session.date.timeIntervalSince1970.rounded())),
            session.planName,
            String(session.totalSets),
            String(Int((session.totalVolume * 10).rounded()))
        ].joined(separator: "|")
    }

    private static var dateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private static func date(_ value: String) -> Date {
        if let date = dateFormatter.date(from: value) {
            return date
        }

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        return fallbackFormatter.date(from: value) ?? Date()
    }

    private static func uuid(_ value: String) -> UUID {
        UUID(uuidString: value.trimmingCharacters(in: .whitespacesAndNewlines)) ?? UUID()
    }

    private static func int(_ value: String) -> Int {
        Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private static func optionalInt(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : Int(trimmed)
    }

    private static func double(_ value: String) -> Double {
        Double(value.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private static func value(_ header: String, in row: [String], using columnIndex: [String: Int]) -> String {
        guard let index = columnIndex[header], row.indices.contains(index) else { return "" }
        return row[index]
    }

    private static func columnIndex(for header: [String]) -> [String: Int] {
        var result: [String: Int] = [:]
        for (index, name) in header.enumerated() {
            let normalizedName = normalizedHeaderName(name)
            if !normalizedName.isEmpty, result[normalizedName] == nil {
                result[normalizedName] = index
            }
        }
        return result
    }

    private static func normalizedHeaderName(_ name: String) -> String {
        name
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{feff}")))
            .lowercased()
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }

        return value
    }

    private static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        let normalizedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let characters = Array(normalizedText)
        var index = 0

        func finishField() {
            row.append(field)
            field = ""
        }

        func finishRow() {
            finishField()
            rows.append(row)
            row = []
        }

        while index < characters.count {
            let character = characters[index]
            if isQuoted {
                if character == "\"" {
                    let nextIndex = index + 1
                    if nextIndex < characters.count, characters[nextIndex] == "\"" {
                        field.append("\"")
                        index += 1
                    } else {
                        isQuoted = false
                    }
                } else {
                    field.append(character)
                }
            } else if character == "\"" {
                isQuoted = true
            } else {
                switch character {
                case ",":
                    finishField()
                case "\n":
                    finishRow()
                case "\r":
                    finishRow()
                    let nextIndex = index + 1
                    if nextIndex < characters.count, characters[nextIndex] == "\n" {
                        index += 1
                    }
                default:
                    field.append(character)
                }
            }

            index += 1
        }

        if !field.isEmpty || !row.isEmpty {
            finishField()
            rows.append(row)
        }
        return rows.filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }
    }

    private struct SessionBuilder {
        var id: UUID
        var planName: String
        var date: Date
        var notes: String
        var durationMinutes: Double
        var calories: Int
        var exercises: [WorkoutSessionExercise] = []

        var session: WorkoutSession {
            WorkoutSession(
                id: id,
                planName: planName.isEmpty ? "Training" : planName,
                date: date,
                notes: notes,
                durationMinutes: durationMinutes,
                calories: calories,
                exercises: exercises
            )
        }

        mutating func append(
            _ set: WorkoutSessionSet,
            toExerciseID exerciseID: UUID,
            catalogID: String,
            name: String,
            category: DeviceCategory,
            notes: String
        ) {
            if let index = exercises.firstIndex(where: { $0.id == exerciseID }) {
                exercises[index].sets.append(set)
            } else {
                exercises.append(
                    WorkoutSessionExercise(
                        id: exerciseID,
                        catalogID: catalogID.isEmpty ? exerciseID.uuidString : catalogID,
                        name: name.isEmpty ? "Übung" : name,
                        category: category,
                        notes: notes,
                        deviceSettings: .empty,
                        sets: [set]
                    )
                )
            }
        }
    }
}

/// A single status row. The text is already translated; `isError` and `isIdle`
/// replace the previous comparisons against German strings, which failed in
/// every other language.
struct StatusMessage: Equatable {
    var text: String
    var isError = false
    /// Nothing has happened yet, so the interface does not show the row.
    var isIdle = false

    static func info(_ text: String) -> StatusMessage {
        StatusMessage(text: text)
    }

    static func error(_ text: String) -> StatusMessage {
        StatusMessage(text: text, isError: true)
    }

    static func idle(_ text: String) -> StatusMessage {
        StatusMessage(text: text, isIdle: true)
    }
}

@MainActor
final class WorkoutStore: ObservableObject {
    @Published private(set) var plan: WorkoutPlan {
        didSet {
            syncActiveRoutineFromPlan()
            save()
            updateLiveActivity()
            PhoneWatchConnectivityController.shared.publish(
                plan: plan,
                restEndDate: GymPitSharedStorage.date(forKey: WorkoutPersistenceKeys.restEndDate)
            )
        }
    }
    @Published private(set) var routines: [WorkoutPlan] = [] {
        didSet { saveRoutines() }
    }
    @Published private(set) var defaultRoutineID: UUID? = nil {
        didSet { saveDefaultRoutineID() }
    }
    @Published private(set) var history: [WorkoutSession] = [] {
        didSet { saveHistory() }
    }
    @Published private(set) var latestCompletedSession: WorkoutSession?
    @Published private(set) var pendingRoutineExercises: [Exercise] = []
    @Published private(set) var pendingRoutineSetExercises: [Exercise] = []
    let restTimerState = WorkoutRestTimerState()
    @Published private(set) var healthExportStatus: StatusMessage =
        .idle(AppLanguage.current.ui("Noch nicht übertragen"))
    @Published private(set) var isHealthExportInProgress = false
    @Published private(set) var bridgeSyncStatus: StatusMessage =
        .idle(AppLanguage.current.ui("HealthPit nicht übertragen"))

    private var isSyncingRoutine = false
    private var isBridgeFullSyncInFlight = false
    private var healthExportedSessionIDs: Set<UUID> = []
    private var healthExportSessionIDsInFlight: Set<UUID> = []

    var restRemainingSeconds: Int {
        restTimerState.remainingSeconds
    }

    var hasPendingRoutineChanges: Bool {
        !pendingRoutineExercises.isEmpty || !pendingRoutineSetExercises.isEmpty
    }

    init() {
        let loadedPlan: WorkoutPlan
        let planData = GymPitSharedStorage.data(forKey: WorkoutPersistenceKeys.plan)
        let didLoadPlan: Bool
        if let data = planData,
           let savedPlan = try? JSONDecoder().decode(WorkoutPlan.self, from: data) {
            loadedPlan = savedPlan
            didLoadPlan = true
        } else {
            loadedPlan = .sample
            didLoadPlan = false
        }

        plan = loadedPlan

        let routinesData = GymPitSharedStorage.data(forKey: WorkoutPersistenceKeys.routines)
        let didLoadRoutines: Bool
        if let data = routinesData,
           let savedRoutines = try? JSONDecoder().decode([WorkoutPlan].self, from: data),
           !savedRoutines.isEmpty {
            routines = savedRoutines
            didLoadRoutines = true
        } else {
            routines = [loadedPlan]
            didLoadRoutines = false
        }

        if !routines.contains(where: { $0.id == loadedPlan.id }) {
            routines.insert(loadedPlan, at: 0)
        }

        if let savedDefault = GymPitSharedStorage.string(forKey: WorkoutPersistenceKeys.defaultRoutineID),
           let savedDefaultID = UUID(uuidString: savedDefault),
           routines.contains(where: { $0.id == savedDefaultID }) {
            defaultRoutineID = savedDefaultID
        } else {
            defaultRoutineID = loadedPlan.id
        }

        pendingRoutineExercises = loadedPlan.exercises.filter { loadedPlan.workoutOnlyExerciseIDs.contains($0.id) && !loadedPlan.isWorkoutStarted }
        pendingRoutineSetExercises = loadedPlan.exercises.filter { exercise in
            !loadedPlan.isWorkoutStarted && exercise.sets.contains { loadedPlan.workoutOnlySetIDs.contains($0.id) }
        }

        let historyData = GymPitSharedStorage.data(forKey: WorkoutPersistenceKeys.history)
        let didLoadHistory: Bool
        if let data = historyData,
           let savedHistory = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            history = sortedHistory(savedHistory.map(sessionWithEstimatedCaloriesIfNeeded))
            didLoadHistory = true
        } else {
            history = []
            didLoadHistory = false
        }

        if let data = GymPitSharedStorage.data(forKey: WorkoutPersistenceKeys.healthExportedSessionIDs),
           let savedIDs = try? JSONDecoder().decode([UUID].self, from: data) {
            healthExportedSessionIDs = Set(savedIDs)
        }

        configureNotifications()
        if didLoadPlan || planData == nil {
            save()
        }
        if didLoadRoutines || routinesData == nil {
            saveRoutines()
        }
        if didLoadHistory || historyData == nil {
            saveHistory()
        }
        updateLiveActivity()
        // A full, idempotent upload is also entity discovery: Home Assistant
        // learns every sport and exercise dynamically from the payload. This
        // must work for every user without a preconfigured entity list.
        synchronizeBridgeEntitiesIfConnected()
    }

    func reloadPlanFromSharedStorage() {
        guard let data = GymPitSharedStorage.data(forKey: WorkoutPersistenceKeys.plan),
              let sharedPlan = try? JSONDecoder().decode(WorkoutPlan.self, from: data) else { return }

        if sharedPlan != plan {
            isSyncingRoutine = true
            plan = sharedPlan
            isSyncingRoutine = false
        }

        if let restEndDate = GymPitSharedStorage.date(forKey: WorkoutPersistenceKeys.restEndDate),
           restEndDate > Date() {
            restTimerState.update(remainingSeconds: Int(restEndDate.timeIntervalSinceNow.rounded(.up)))
        } else {
            restTimerState.update(remainingSeconds: 0)
            GymPitSharedStorage.set(nil as Date?, forKey: WorkoutPersistenceKeys.restEndDate)
        }
    }

    func renamePlan(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        plan.name = trimmed.isEmpty ? "Training" : trimmed
    }

    func renameExercise(_ exercise: Exercise, name: String) {
        guard let index = plan.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        plan.exercises[index].name = trimmed
    }

    func updateProfile(_ profile: UserProfile) {
        plan.profile = profile
    }

    func updateWorkoutNotes(_ notes: String) {
        plan.workoutNotes = notes
    }

    func updateCompletionGoal(_ goal: WorkoutCompletionGoal) {
        plan.completionGoal = normalizedCompletionGoal(goal)
    }

    @discardableResult
    func addExercise(
        from item: ExerciseCatalogItem,
        name: String? = nil,
        target: String? = nil,
        muscleDistribution: [MuscleDistributionShare]? = nil,
        metValue: Double? = nil,
        device: DeviceSettings? = nil,
        setCount: Int? = nil,
        reps: Int? = nil,
        defaultWeight: Double? = nil
    ) -> Exercise? {
        var exercise = item.makeExercise()
        if let name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                exercise.name = trimmed
            }
        }
        if let target {
            let trimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                exercise.target = trimmed
            }
        }
        if let muscleDistribution {
            exercise.customMuscleDistribution = MuscleDistributionShare.normalizedShares(muscleDistribution)
        }
        if let metValue {
            exercise.metValue = metValue
        }
        if let device {
            exercise.device = device
        }
        if setCount != nil || reps != nil || defaultWeight != nil {
            let count = max(1, min(8, setCount ?? exercise.sets.count))
            let startingReps = max(1, min(30, reps ?? exercise.sets.first?.reps ?? 12))
            let startingWeight = normalizedWeight(defaultWeight ?? exercise.sets.first?.weight ?? 0)
            exercise.sets = (0..<count).map { _ in
                ExerciseSet(id: UUID(), type: .normal, reps: startingReps, weight: startingWeight, rpe: nil, isLogged: false)
            }
        }

        plan.exercises.append(exercise)
        if plan.currentExerciseID == nil {
            plan.currentExerciseID = plan.exercises.first?.id
        }
        return exercise
    }

    @discardableResult
    func addCustomExercise(
        name: String,
        category: DeviceCategory,
        target: String,
        sets: Int,
        reps: Int,
        weight: Double,
        metValue: Double? = nil,
        iconTemplateID: String? = nil,
        device: DeviceSettings? = nil,
        usesDedicatedDevice: Bool? = nil,
        muscleDistribution: [MuscleDistributionShare]? = nil,
        workoutOnly: Bool = false
    ) -> Exercise? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        let normalizedMuscleDistribution = MuscleDistributionShare.normalizedShares(
            muscleDistribution ?? MuscleDistributionShare.defaultShares(for: category)
        )

        let exercise = Exercise(
            id: UUID(),
            catalogID: "custom-\(UUID().uuidString)",
            name: trimmedName,
            target: target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(sets) x \(reps)" : target,
            category: category,
            customMuscleDistribution: normalizedMuscleDistribution,
            metValue: metValue ?? (category == .cardio ? 6.0 : 5.0),
            device: device ?? .empty,
            notes: "",
            restSeconds: plan.profile.defaultRestSeconds,
            supersetGroup: nil,
            isFavorite: false,
            isCustom: true,
            usesDedicatedDevice: usesDedicatedDevice,
            iconTemplateID: iconTemplateID,
            sets: (0..<max(1, sets)).map { _ in
                ExerciseSet(id: UUID(), type: .normal, reps: reps, weight: normalizedWeight(weight), rpe: nil, isLogged: false)
            }
        )

        plan.exercises.append(exercise)
        if plan.currentExerciseID == nil {
            plan.currentExerciseID = exercise.id
        }
        if workoutOnly {
            markExerciseAsWorkoutOnly(exercise)
        }
        return exercise
    }

    func addWorkoutOnlyExercise(from item: ExerciseCatalogItem, target: String, setCount: Int, reps: Int, defaultWeight: Double) {
        guard let exercise = addExercise(from: item, target: target, setCount: setCount, reps: reps, defaultWeight: defaultWeight) else { return }
        markExerciseAsWorkoutOnly(exercise)
    }

    private func markExerciseAsWorkoutOnly(_ exercise: Exercise) {
        if !plan.workoutOnlyExerciseIDs.contains(exercise.id) {
            plan.workoutOnlyExerciseIDs.append(exercise.id)
        }
    }

    func deleteCustomExercise(catalogID: String) {
        guard catalogID.hasPrefix("custom-") else { return }

        func removeMatches(from routine: inout WorkoutPlan) {
            let removedIDs = Set(routine.exercises.filter { $0.catalogID == catalogID && $0.isCustom }.map(\.id))
            guard !removedIDs.isEmpty else { return }

            routine.exercises.removeAll { removedIDs.contains($0.id) }
            routine.completedExerciseIDs.removeAll { removedIDs.contains($0) }
            if let currentExerciseID = routine.currentExerciseID, removedIDs.contains(currentExerciseID) {
                routine.currentExerciseID = routine.openExercises.first?.id
            }
        }

        for index in routines.indices {
            removeMatches(from: &routines[index])
        }

        isSyncingRoutine = true
        removeMatches(from: &plan)
        isSyncingRoutine = false
        syncActiveRoutineFromPlan()
        save()
        saveRoutines()
    }

    func removeExercise(_ exercise: Exercise) {
        plan.exercises.removeAll { $0.id == exercise.id }
        plan.completedExerciseIDs.removeAll { $0 == exercise.id }
        plan.workoutOnlyExerciseIDs.removeAll { $0 == exercise.id }
        plan.workoutOnlySetIDs.removeAll { setID in
            exercise.sets.contains { $0.id == setID }
        }
        pendingRoutineExercises.removeAll { $0.id == exercise.id }
        pendingRoutineSetExercises.removeAll { $0.id == exercise.id }

        if plan.currentExerciseID == exercise.id {
            plan.currentExerciseID = plan.openExercises.first?.id
        }
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        plan.exercises.move(fromOffsets: source, toOffset: destination)
    }

    func startWorkout() {
        clearWorkoutNotifications()
        latestCompletedSession = nil
        if hasLoggedProgress || !plan.completedExerciseIDs.isEmpty || plan.archivedSessionID != nil {
            preparePlanForNextWorkout()
        }
        plan.isWorkoutStarted = true
        plan.workoutStartedAt = Date()
        plan.archivedSessionID = nil
        if plan.currentExerciseID == nil || plan.completedExerciseIDs.contains(where: { $0 == plan.currentExerciseID }) {
            plan.currentExerciseID = plan.openExercises.first?.id
        }
    }

    func endWorkout() {
        finishWorkout()
    }

    func endWorkoutFromWatch(
        workoutID: UUID?,
        durationSeconds: TimeInterval?,
        activeCalories: Double?,
        healthWorkoutSaved: Bool
    ) {
        finishWorkout(
            workoutID: workoutID,
            durationMinutes: durationSeconds.map { max(0, $0) / 60 },
            activeCalories: activeCalories,
            healthWorkoutSaved: healthWorkoutSaved
        )
    }

    private func finishWorkout(
        workoutID: UUID? = nil,
        durationMinutes: Double? = nil,
        activeCalories: Double? = nil,
        healthWorkoutSaved: Bool = false
    ) {
        let addedDuringWorkout = plan.exercises.filter { plan.workoutOnlyExerciseIDs.contains($0.id) }
        let setChangedDuringWorkout = plan.exercises.filter { exercise in
            exercise.sets.contains { plan.workoutOnlySetIDs.contains($0.id) }
        }
        if let session = archiveWorkoutIfNeeded(
            sessionID: workoutID,
            durationMinutes: durationMinutes,
            activeCalories: activeCalories,
            healthWorkoutSaved: healthWorkoutSaved
        ) {
            latestCompletedSession = session
        }
        preparePlanForNextWorkout()
        pendingRoutineExercises = addedDuringWorkout
        pendingRoutineSetExercises = setChangedDuringWorkout
        stopRestTimer()
        WorkoutLiveActivityController.shared.end()
    }

    func keepPendingWorkoutExercisesInRoutine() {
        let ids = Set(pendingRoutineExercises.map(\.id))
        plan.workoutOnlyExerciseIDs.removeAll { ids.contains($0) }
        plan.workoutOnlySetIDs.removeAll()
        pendingRoutineExercises = []
        pendingRoutineSetExercises = []
    }

    func discardPendingWorkoutExercisesFromRoutine() {
        let ids = Set(pendingRoutineExercises.map(\.id))
        let workoutOnlySetIDs = Set(plan.workoutOnlySetIDs)
        plan.exercises.removeAll { ids.contains($0.id) }
        plan.completedExerciseIDs.removeAll { ids.contains($0) }
        plan.workoutOnlyExerciseIDs.removeAll { ids.contains($0) }
        plan.exercises = plan.exercises.map { exercise in
            var updated = exercise
            updated.sets.removeAll { workoutOnlySetIDs.contains($0.id) }
            return updated
        }
        plan.workoutOnlySetIDs.removeAll()
        if let currentExerciseID = plan.currentExerciseID, ids.contains(currentExerciseID) {
            plan.currentExerciseID = plan.openExercises.first?.id
        }
        pendingRoutineExercises = []
        pendingRoutineSetExercises = []
    }

    func completeNextSet(for exerciseID: UUID) {
        completeNextSetFromNotification(exerciseID: exerciseID)
    }

    func skipRest(for exerciseID: UUID) {
        guard plan.exercises.contains(where: { $0.id == exerciseID }),
              !plan.completedExerciseIDs.contains(exerciseID) else { return }

        plan.isWorkoutStarted = true
        plan.currentExerciseID = exerciseID
        stopRestTimer()
    }

    func selectExercise(id exerciseID: UUID) {
        guard let exercise = plan.exercises.first(where: { $0.id == exerciseID }),
              !plan.completedExerciseIDs.contains(exerciseID) else { return }
        start(exercise)
    }

    func start(_ exercise: Exercise) {
        plan.isWorkoutStarted = true
        if plan.completedExerciseIDs.contains(exercise.id) {
            resetSets(for: exercise.id)
        }
        plan.currentExerciseID = exercise.id
        plan.completedExerciseIDs.removeAll { $0 == exercise.id }
    }

    func complete(_ exercise: Exercise) {
        cancelNotifications(for: exercise.id)
        if !plan.completedExerciseIDs.contains(exercise.id) {
            plan.completedExerciseIDs.append(exercise.id)
        }

        if plan.currentExerciseID == exercise.id {
            plan.currentExerciseID = plan.openExercises.first?.id
        }

        plan.isCompletedSectionExpanded = true
    }

    func reopen(_ exercise: Exercise) {
        plan.completedExerciseIDs.removeAll { $0 == exercise.id }
        resetSets(for: exercise.id)
        plan.currentExerciseID = exercise.id
    }

    func toggleCompletedSection() {
        plan.isCompletedSectionExpanded.toggle()
    }

    func updateDevice(for exercise: Exercise, settings: DeviceSettings) {
        guard let index = plan.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        plan.exercises[index].device = settings
    }

    func updateSet(_ set: ExerciseSet, in exercise: Exercise, type: WorkoutSetType, reps: Int, weight: Double, rpe: Int?, isLogged: Bool) {
        guard let exerciseIndex = plan.exercises.firstIndex(where: { $0.id == exercise.id }),
              let setIndex = plan.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == set.id }) else { return }

        let previousSet = plan.exercises[exerciseIndex].sets[setIndex]
        let updatedSet = ExerciseSet(
            id: previousSet.id,
            type: type,
            reps: reps,
            weight: normalizedWeight(weight),
            rpe: rpe,
            isLogged: isLogged
        )
        guard updatedSet != previousSet else { return }

        let wasLogged = previousSet.isLogged
        plan.exercises[exerciseIndex].sets[setIndex] = updatedSet

        if isLogged && !wasLogged {
            if plan.exercises[exerciseIndex].sets.allSatisfy(\.isLogged) {
                finishExerciseAfterAllSets(exerciseID: exercise.id)
            } else {
                startRestTimer(seconds: plan.exercises[exerciseIndex].restSeconds)
            }
        } else if !isLogged && wasLogged {
            cancelNotifications(for: exercise.id)
            stopRestTimer()
            plan.completedExerciseIDs.removeAll { $0 == exercise.id }
            plan.currentExerciseID = exercise.id
        }
    }

    func addSet(to exercise: Exercise, isLogged: Bool = false, keepExerciseCompleted: Bool = false) {
        guard let exerciseIndex = plan.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        let template = plan.exercises[exerciseIndex].sets.last
        let newSet = ExerciseSet(
            id: UUID(),
            type: .normal,
            reps: template?.reps ?? 12,
            weight: template?.weight ?? 0,
            rpe: template?.rpe,
            isLogged: isLogged
        )
        plan.exercises[exerciseIndex].sets.append(newSet)
        if !plan.workoutOnlySetIDs.contains(newSet.id) {
            plan.workoutOnlySetIDs.append(newSet.id)
        }
        if keepExerciseCompleted {
            if !plan.completedExerciseIDs.contains(exercise.id) {
                plan.completedExerciseIDs.append(exercise.id)
            }
        } else {
            plan.completedExerciseIDs.removeAll { $0 == exercise.id }
            plan.currentExerciseID = exercise.id
        }
    }

    func handleNotificationAction(_ actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        guard let exerciseID = notificationExerciseID(from: userInfo) else { return }

        switch actionIdentifier {
        case GymPitNotificationIDs.completeNextSetAction:
            completeNextSetFromNotification(exerciseID: exerciseID)
        default:
            break
        }
    }

    func updateExercise(_ exercise: Exercise, target: String, setCount: Int, reps: Int, defaultWeight: Double, metValue: Double) {
        guard let index = plan.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        let count = max(1, min(8, setCount))
        var updated = plan.exercises[index]
        updated.target = target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? exercise.target : target
        updated.metValue = metValue

        if count > updated.sets.count {
            let missing = count - updated.sets.count
            updated.sets.append(contentsOf: (0..<missing).map { _ in
                ExerciseSet(id: UUID(), type: .normal, reps: reps, weight: normalizedWeight(defaultWeight), rpe: nil, isLogged: false)
            })
        } else if count < updated.sets.count {
            updated.sets.removeLast(updated.sets.count - count)
        }

        updated.sets = updated.sets.map { set in
            ExerciseSet(
                id: set.id,
                type: set.type,
                reps: set.isLogged ? set.reps : reps,
                weight: set.isLogged ? set.weight : normalizedWeight(defaultWeight),
                rpe: set.rpe,
                isLogged: set.isLogged
            )
        }

        plan.exercises[index] = updated
    }

    func updateMuscleDistribution(_ exercise: Exercise, shares: [MuscleDistributionShare]) {
        let normalizedShares = MuscleDistributionShare.normalizedShares(shares)

        func apply(to routine: inout WorkoutPlan) {
            for index in routine.exercises.indices where routine.exercises[index].id == exercise.id || (exercise.isCustom && routine.exercises[index].catalogID == exercise.catalogID) {
                routine.exercises[index].customMuscleDistribution = normalizedShares
            }
        }

        for index in routines.indices {
            apply(to: &routines[index])
        }

        isSyncingRoutine = true
        apply(to: &plan)
        isSyncingRoutine = false
        syncActiveRoutineFromPlan()
        save()
        saveRoutines()
    }

    func updateExerciseNotes(_ exercise: Exercise, notes: String) {
        guard let index = plan.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        plan.exercises[index].notes = notes
    }

    func updateExerciseOptions(_ exercise: Exercise, restSeconds: Int, supersetGroup: Int?, isFavorite: Bool) {
        guard let index = plan.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        plan.exercises[index].restSeconds = restSeconds
        plan.exercises[index].supersetGroup = supersetGroup
        plan.exercises[index].isFavorite = isFavorite
    }

    func toggleIncreaseWeightRecommendation(for exercise: Exercise) {
        guard let index = plan.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        plan.exercises[index].shouldIncreaseWeightNextTime.toggle()
    }

    func toggleFavorite(_ exercise: Exercise) {
        guard let index = plan.exercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        plan.exercises[index].isFavorite.toggle()
    }

    func selectRoutine(_ routine: WorkoutPlan) {
        guard let selected = routines.first(where: { $0.id == routine.id }) else { return }
        isSyncingRoutine = true
        plan = selected
        isSyncingRoutine = false
        save()
        stopRestTimer()
    }

    func setDefaultRoutine(_ routine: WorkoutPlan) {
        defaultRoutineID = routine.id
        selectRoutine(routine)
    }

    func deleteRoutine(at indexSet: IndexSet) {
        guard routines.count > 1 else { return }
        let removedIDs = Set(indexSet.compactMap { routines.indices.contains($0) ? routines[$0].id : nil })
        routines.remove(atOffsets: indexSet)

        if let defaultRoutineID, removedIDs.contains(defaultRoutineID) {
            self.defaultRoutineID = routines.first?.id
        }

        if removedIDs.contains(plan.id), let replacement = routines.first(where: { $0.id == self.defaultRoutineID }) ?? routines.first {
            selectRoutine(replacement)
        }
    }

    func moveRoutine(from source: IndexSet, to destination: Int) {
        routines.move(fromOffsets: source, toOffset: destination)
    }

    func createEmptyRoutine(named name: String = "Neue Routine") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let routine = WorkoutPlan(
            id: UUID(),
            name: trimmed.isEmpty ? "Neue Routine" : trimmed,
            profile: plan.profile,
            workoutNotes: "",
            completionGoal: .allExercises,
            workoutStartedAt: nil,
            exercises: [],
            currentExerciseID: nil,
            completedExerciseIDs: [],
            isCompletedSectionExpanded: false,
            archivedSessionID: nil,
            isWorkoutStarted: false
        )
        routines.append(routine)
        selectRoutine(routine)
        stopRestTimer()
    }

    func applyTemplate(_ template: RoutineTemplate) {
        let profile = plan.profile
        plan = WorkoutPlan(
            id: UUID(),
            name: template.name,
            profile: profile,
            workoutNotes: "",
            completionGoal: .allExercises,
            workoutStartedAt: nil,
            exercises: template.catalogIDs.compactMap { ExerciseCatalog.item(for: $0)?.makeExercise() },
            currentExerciseID: nil,
            completedExerciseIDs: [],
            isCompletedSectionExpanded: false,
            archivedSessionID: nil,
            isWorkoutStarted: false
        )
    }

    func resetProgress() {
        latestCompletedSession = nil
        preparePlanForNextWorkout()
    }

    func connectAppleHealth() {
        healthExportStatus = .info(AppLanguage.current.ui("Apple Health wird verbunden..."))
        WorkoutHealthExporter.shared.requestAuthorization { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    self?.healthExportStatus = .info(AppLanguage.current.ui("Apple Health verbunden"))
                case .failure(let error):
                    self?.healthExportStatus = .error(
                        AppLanguage.current.ui(format: "Apple Health Fehler: %@", error.localizedDescription)
                    )
                }
            }
        }
    }

    func exportLatestSessionToHealth() {
        guard let session = latestCompletedSession ?? history.first else {
            healthExportStatus = .info(AppLanguage.current.ui("Kein abgeschlossenes Training vorhanden"))
            return
        }
        exportSessionToHealth(session)
    }

    func exportAllHistoricSessionsToHealth() {
        guard !isHealthExportInProgress else {
            healthExportStatus = .info(AppLanguage.current.ui("Apple-Health-Übertragung läuft bereits"))
            return
        }

        let sessions = history
        guard !sessions.isEmpty else {
            healthExportStatus = .info(AppLanguage.current.ui("Keine alten Workouts vorhanden"))
            return
        }

        let pendingSessions = sessions.filter { !healthExportedSessionIDs.contains($0.id) }
        let alreadyExported = sessions.count - pendingSessions.count
        guard !pendingSessions.isEmpty else {
            healthExportStatus = .info(
                AppLanguage.current.ui(format: "Alle Workouts sind bereits in Apple Health (%d)", sessions.count)
            )
            return
        }

        isHealthExportInProgress = true
        healthExportStatus = .info(
            AppLanguage.current.ui(format: "Apple Health: 0/%d wird übertragen...", pendingSessions.count)
        )
        exportHistoricSessions(
            pendingSessions,
            total: pendingSessions.count,
            completed: 0,
            skipped: alreadyExported,
            failed: 0
        )
    }

    func uploadAllHistoricSessionsToBridge() {
        syncAllHistoricSessionsToBridge()
    }

    func synchronizeBridgeEntitiesIfConnected() {
        guard GymPitBridgeSyncService.shared.hasSession else { return }
        syncAllHistoricSessionsToBridge()
    }

    private func syncAllHistoricSessionsToBridge() {
        guard !isBridgeFullSyncInFlight else { return }
        let sessions = history
        guard !sessions.isEmpty else {
            bridgeSyncStatus = .info(AppLanguage.current.ui("Keine Trainings vorhanden"))
            return
        }

        bridgeSyncStatus = .info(
            AppLanguage.current.ui(format: "HealthPit überträgt Trainings (%d)...", sessions.count)
        )
        isBridgeFullSyncInFlight = true
        Task {
            do {
                let summary = try await GymPitBridgeSyncService.shared.uploadAndReconcile(sessions)
                await MainActor.run {
                    isBridgeFullSyncInFlight = false
                    if summary.uploaded == 0 {
                        bridgeSyncStatus = .info(AppLanguage.current.ui("HealthPit: keine neuen Trainings"))
                    } else {
                        bridgeSyncStatus = .info("HealthPit " + bridgeSummaryText(summary))
                    }
                }
            } catch {
                await MainActor.run {
                    isBridgeFullSyncInFlight = false
                    bridgeSyncStatus = .error(
                        AppLanguage.current.ui(format: "HealthPit Fehler: %@", error.localizedDescription)
                    )
                }
            }
        }
    }

    private var hasLoggedProgress: Bool {
        plan.exercises.contains { exercise in
            exercise.sets.contains(where: \.isLogged)
        }
    }

    private func preparePlanForNextWorkout() {
        stopRestTimer()
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

    func deleteHistory(at indexSet: IndexSet) {
        let deletedSessions = indexSet.compactMap { index in
            history.indices.contains(index) ? history[index] : nil
        }
        history.remove(atOffsets: indexSet)
        deleteSessionsFromHealth(deletedSessions, total: deletedSessions.count, completed: 0, failed: 0)
        deleteSessionsFromBridge(deletedSessions)
    }

    private func deleteSessionsFromBridge(_ sessions: [WorkoutSession]) {
        guard !sessions.isEmpty else { return }
        bridgeSyncStatus = .info(
            AppLanguage.current.ui(format: "HealthPit löscht Trainings (%d)...", sessions.count)
        )
        Task {
            var failed = 0
            for session in sessions {
                do {
                    try await GymPitBridgeSyncService.shared.delete(workoutID: session.id)
                } catch {
                    failed += 1
                }
            }
            await MainActor.run {
                bridgeSyncStatus = failed == 0
                    ? .info(AppLanguage.current.ui("HealthPit: Löschung synchronisiert"))
                    : .error(AppLanguage.current.ui(format: "HealthPit: Löschungen fehlgeschlagen (%d)", failed))
            }
        }
    }

    func exportHistoryCSV() -> String {
        WorkoutCSVCodec.export(history)
    }

    func exportDataArchive() throws -> Data {
        try WorkoutDataArchiveCodec.export(
            sessions: history,
            routines: routines,
            defaultRoutineID: defaultRoutineID
        )
    }

    func importDataArchive(_ archive: WorkoutDataArchive) -> WorkoutDataImportSummary {
        let sessionSummary = importSessionsIntoHistory(archive.sessions)
        let routineSummary = importRoutines(archive.routines)
        return WorkoutDataImportSummary(
            sessions: sessionSummary,
            routinesImported: routineSummary.imported,
            routinesSkipped: routineSummary.skipped
        )
    }

    func importHistoryCSV(data: Data) throws -> WorkoutCSVImportSummary {
        let importedSessions = try WorkoutCSVCodec.importSessions(from: data)
        return importSessionsIntoHistory(importedSessions)
    }

    func importHistorySessions(_ importedSessions: [WorkoutSession]) -> WorkoutCSVImportSummary {
        importSessionsIntoHistory(importedSessions)
    }

    @discardableResult
    func addManualHistorySession(
        planName: String,
        performedAt: Date,
        durationMinutes: Double,
        calories: Int?,
        notes: String,
        exercises: [WorkoutSessionExercise]
    ) -> WorkoutSession? {
        let validExercises = exercises.filter { !$0.sets.isEmpty }
        guard !validExercises.isEmpty else { return nil }

        let trimmedName = planName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let session = sessionWithEstimatedCaloriesIfNeeded(
            WorkoutSession(
                id: UUID(),
                planName: trimmedName.isEmpty ? "Training" : trimmedName,
                date: min(performedAt, Date()),
                notes: trimmedNotes,
                durationMinutes: max(1, min(1_440, durationMinutes)),
                calories: max(0, calories ?? 0),
                exercises: validExercises
            )
        )

        history.append(session)
        sortHistoryByPerformedDate()

        if WorkoutHealthExporter.shared.isAuthorizedForAutomaticSave {
            exportSessionToHealth(session)
        } else {
            healthExportStatus = .info(AppLanguage.current.ui("Apple Health nicht verbunden"))
        }
        uploadSessionToBridge(session)

        return session
    }

    private func importSessionsIntoHistory(_ importedSessions: [WorkoutSession]) -> WorkoutCSVImportSummary {
        let existingIDs = Set(history.map(\.id))
        let existingSignatures = Set(history.map(WorkoutCSVCodec.signature(for:)))

        var newSessions: [WorkoutSession] = []
        var skipped = 0

        for session in importedSessions {
            if existingIDs.contains(session.id) || existingSignatures.contains(WorkoutCSVCodec.signature(for: session)) {
                skipped += 1
            } else {
                newSessions.append(session)
            }
        }

        if !newSessions.isEmpty {
            history.append(contentsOf: newSessions.map(sessionWithEstimatedCaloriesIfNeeded))
            sortHistoryByPerformedDate()
        }

        return WorkoutCSVImportSummary(imported: newSessions.count, skipped: skipped, rows: importedSessions.count)
    }

    private func importRoutines(_ importedRoutines: [WorkoutPlan]) -> (imported: Int, skipped: Int) {
        var existingIDs = Set(routines.map(\.id))
        var existingSignatures = Set(routines.map(routineImportSignature))
        var newRoutines: [WorkoutPlan] = []
        var skipped = 0

        for sourceRoutine in importedRoutines {
            let signature = routineImportSignature(sourceRoutine)
            guard !existingSignatures.contains(signature) else {
                skipped += 1
                continue
            }

            var routine = sourceRoutine
            if existingIDs.contains(routine.id) {
                routine.id = UUID()
            }
            existingIDs.insert(routine.id)
            existingSignatures.insert(signature)
            newRoutines.append(routine)
        }

        if !newRoutines.isEmpty {
            routines.append(contentsOf: newRoutines)
        }
        return (newRoutines.count, skipped)
    }

    private func routineImportSignature(_ routine: WorkoutPlan) -> String {
        var normalized = routine
        normalized.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(normalized) else {
            return "\(routine.name)|\(routine.exercises.map(\.catalogID).joined(separator: "|"))"
        }
        return data.base64EncodedString()
    }

    func exportHuaweiWatchData() throws -> Data {
        try HuaweiWatchSyncCodec.export(
            plan: plan,
            history: history,
            restEndDate: GymPitSharedStorage.date(forKey: WorkoutPersistenceKeys.restEndDate)
        )
    }

    func importHuaweiWatchData(_ data: Data) throws -> HuaweiWatchImportSummary {
        let importedSessions = try HuaweiWatchSyncCodec.importSessions(from: data)
        let existingIDs = Set(history.map(\.id))
        let existingSignatures = Set(history.map(WorkoutCSVCodec.signature(for:)))

        var newSessions: [WorkoutSession] = []
        var skipped = 0

        for session in importedSessions {
            if existingIDs.contains(session.id) || existingSignatures.contains(WorkoutCSVCodec.signature(for: session)) {
                skipped += 1
            } else {
                newSessions.append(session)
            }
        }

        if !newSessions.isEmpty {
            history.append(contentsOf: newSessions.map(sessionWithEstimatedCaloriesIfNeeded))
            sortHistoryByPerformedDate()
        }

        return HuaweiWatchImportSummary(imported: newSessions.count, skipped: skipped, rows: importedSessions.count)
    }

    func previousSessionExercise(for exercise: Exercise) -> WorkoutSessionExercise? {
        history
            .sorted { $0.date > $1.date }
            .compactMap { session in
                session.exercises.first { $0.catalogID == exercise.catalogID }
            }
            .first
    }

    func trainerRecommendation(for exercise: Exercise) -> TrainerRecommendation {
        let currentExercise = plan.exercises.first(where: { $0.id == exercise.id }) ?? exercise
        let completedSets = currentExercise.sets
            .filter(\.isLogged)
            .map(trainerSnapshot)
        let nextSet = currentExercise.sets
            .first(where: { !$0.isLogged })
            .map(trainerSnapshot)
        let previousSets = previousSessionExercise(for: currentExercise)?.sets.map(trainerSnapshot) ?? []

        return TrainerRecommendationEngine.recommendation(
            completedSets: completedSets,
            nextPlannedSet: nextSet,
            previousWorkoutSets: previousSets,
            defaultRestSeconds: currentExercise.restSeconds
        )
    }

    @discardableResult
    func applyTrainerRecommendation(_ recommendation: TrainerRecommendation, to exercise: Exercise) -> Bool {
        guard let exerciseIndex = plan.exercises.firstIndex(where: { $0.id == exercise.id }),
              let setIndex = plan.exercises[exerciseIndex].sets.firstIndex(where: { !$0.isLogged }) else {
            return false
        }

        plan.exercises[exerciseIndex].sets[setIndex].weight = normalizedWeight(recommendation.weightKilograms)
        plan.exercises[exerciseIndex].sets[setIndex].reps = max(1, recommendation.repetitions)

        if restRemainingSeconds > 0 {
            startRestTimer(seconds: recommendation.restSeconds)
        }
        return true
    }

    func loggedSetsMissingRPE(for exercise: Exercise) -> Int {
        let currentExercise = plan.exercises.first(where: { $0.id == exercise.id }) ?? exercise
        return currentExercise.sets.filter { set in
            guard set.isLogged, set.rpe == nil else { return false }
            let kind = trainerSetKind(set.type)
            return kind == .work || kind == .failure
        }.count
    }

    func hasOpenSet(for exercise: Exercise) -> Bool {
        plan.exercises
            .first(where: { $0.id == exercise.id })?
            .sets.contains(where: { !$0.isLogged }) ?? false
    }

    func bestWeight(for exercise: Exercise) -> Double? {
        history
            .flatMap(\.exercises)
            .filter { $0.catalogID == exercise.catalogID }
            .compactMap(\.maximumWeight)
            .max()
    }

    private func trainerSnapshot(_ set: ExerciseSet) -> TrainerSetSnapshot {
        TrainerSetSnapshot(
            kind: trainerSetKind(set.type),
            repetitions: set.reps,
            weightKilograms: set.weight,
            rpe: set.rpe
        )
    }

    private func trainerSnapshot(_ set: WorkoutSessionSet) -> TrainerSetSnapshot {
        TrainerSetSnapshot(
            kind: trainerSetKind(set.type),
            repetitions: set.reps,
            weightKilograms: set.weight,
            rpe: set.rpe
        )
    }

    private func trainerSetKind(_ type: WorkoutSetType) -> TrainerSetKind {
        switch type {
        case .normal: .work
        case .warmup: .warmup
        case .drop: .drop
        case .failure: .failure
        }
    }

    func lastWeightIncrease(for exercise: Exercise) -> ExerciseWeightIncrease? {
        var points = history
            .compactMap { session -> (date: Date, weight: Double)? in
                guard let sessionExercise = session.exercises.first(where: { $0.catalogID == exercise.catalogID }),
                      let weight = sessionExercise.maximumWeight,
                      weight > 0 else { return nil }
                return (session.date, weight)
            }
            .sorted { $0.date < $1.date }

        if exercise.completedSetsCount > 0, let weight = exercise.maximumWeight, weight > 0 {
            points.append((Date(), weight))
        }

        guard let first = points.first else { return nil }
        var bestWeight = first.weight
        var lastIncrease: ExerciseWeightIncrease?

        for point in points.dropFirst() where point.weight > bestWeight {
            bestWeight = point.weight
            lastIncrease = ExerciseWeightIncrease(date: point.date, weight: point.weight)
        }

        return lastIncrease
    }

    func latestWeightUsage(for exercise: Exercise) -> ExerciseWeightUsage? {
        var weights = history
            .compactMap { session -> (date: Date, weight: Double)? in
                guard let sessionExercise = session.exercises.first(where: { $0.catalogID == exercise.catalogID }),
                      let weight = sessionExercise.maximumWeight,
                      weight > 0 else { return nil }
                return (session.date, weight)
            }
            .sorted { $0.date < $1.date }

        if exercise.completedSetsCount > 0, let weight = exercise.maximumWeight, weight > 0 {
            weights.append((Date(), weight))
        }

        guard let latestWeight = weights.last?.weight else { return nil }
        let consecutiveWorkouts = weights.reversed().prefix {
            abs($0.weight - latestWeight) < 0.000_001
        }.count

        return ExerciseWeightUsage(weight: latestWeight, consecutiveWorkouts: consecutiveWorkouts)
    }

    func recordSummaries(for exercise: Exercise) -> [ExerciseRecordSummary] {
        let historical = historicalExercises(for: exercise)
        let loggedSets = historical.flatMap(\.sets) + exercise.sets.filter(\.isLogged).map {
            WorkoutSessionSet(id: $0.id, type: $0.type, reps: $0.reps, weight: $0.weight, rpe: $0.rpe)
        }

        let maxWeight = loggedSets.map(\.weight).max()
        let bestSetVolume = loggedSets.map { Double($0.reps) * $0.weight }.max()
        let bestOneRepMax = loggedSets
            .filter { $0.reps > 0 && $0.weight > 0 }
            .map { $0.weight * (1 + Double($0.reps) / 30) }
            .max()
        let bestHistoricalSessionVolume = historical.map(\.volume).max()
        let bestSessionVolume = max(bestHistoricalSessionVolume ?? 0, exercise.volume)

        return [
            ExerciseRecordSummary(metric: .setVolume, value: bestSetVolume),
            ExerciseRecordSummary(metric: .maxWeight, value: maxWeight),
            ExerciseRecordSummary(metric: .estimatedOneRepMax, value: bestOneRepMax),
            ExerciseRecordSummary(metric: .sessionVolume, value: bestSessionVolume > 0 ? bestSessionVolume : nil)
        ]
    }

    func trendPoints(for exercise: Exercise, scale: RecordTimeScale) -> [ExerciseTrendPoint] {
        let cutoff = scale.days.flatMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }
        var points = history.compactMap { session -> ExerciseTrendPoint? in
            guard cutoff.map({ session.date >= $0 }) ?? true,
                  let sessionExercise = session.exercises.first(where: { $0.catalogID == exercise.catalogID }) else {
                return nil
            }

            return ExerciseTrendPoint(
                id: session.id,
                date: session.date,
                volume: sessionExercise.volume,
                maxWeight: sessionExercise.maximumWeight ?? 0,
                bestSetVolume: sessionExercise.sets.map { Double($0.reps) * $0.weight }.max() ?? 0
            )
        }
        .sorted { $0.date < $1.date }

        if exercise.completedSetsCount > 0 {
            points.append(
                ExerciseTrendPoint(
                    id: exercise.id,
                    date: Date(),
                    volume: exercise.volume,
                    maxWeight: exercise.maximumWeight ?? 0,
                    bestSetVolume: exercise.sets.filter(\.isLogged).map { Double($0.reps) * $0.weight }.max() ?? 0
                )
            )
        }

        return points
    }

    func personalRecordFlags(for set: ExerciseSet, in exercise: Exercise) -> PersonalRecordFlags {
        guard set.isLogged else { return PersonalRecordFlags() }

        let historical = historicalExercises(for: exercise)
        let historicalSets = historical.flatMap(\.sets)
        let setVolume = Double(set.reps) * set.weight
        let oneRepMax = set.weight * (1 + Double(max(0, set.reps)) / 30)
        let lastLoggedSetID = exercise.sets.last(where: \.isLogged)?.id

        return PersonalRecordFlags(
            setVolume: setVolume > 0 && setVolume > (historicalSets.map { Double($0.reps) * $0.weight }.max() ?? 0),
            maxWeight: set.weight > 0 && set.weight > (historicalSets.map(\.weight).max() ?? 0),
            estimatedOneRepMax: oneRepMax > 0 && oneRepMax > (historicalSets.filter { $0.reps > 0 && $0.weight > 0 }.map { $0.weight * (1 + Double($0.reps) / 30) }.max() ?? 0),
            sessionVolume: set.id == lastLoggedSetID && exercise.volume > 0 && exercise.volume > (historical.map(\.volume).max() ?? 0)
        )
    }

    func tickRestTimer() {
        guard let restEndDate = GymPitSharedStorage.date(forKey: WorkoutPersistenceKeys.restEndDate) else {
            restTimerState.update(remainingSeconds: 0)
            return
        }

        let remaining = max(0, Int(restEndDate.timeIntervalSinceNow.rounded(.up)))
        restTimerState.update(remainingSeconds: remaining)

        if remaining == 0 {
            GymPitSharedStorage.set(nil as Date?, forKey: WorkoutPersistenceKeys.restEndDate)
            if let exerciseID = plan.currentExerciseID {
                cancelNotifications(for: exerciseID)
            }
            WorkoutLiveActivityController.shared.clearRest(for: plan)
        }
    }

    func startRestTimer(seconds: Int? = nil) {
        restTimerState.update(remainingSeconds: seconds ?? plan.profile.defaultRestSeconds)
        guard restRemainingSeconds > 0 else {
            stopRestTimer()
            return
        }

        let restEndDate = Date().addingTimeInterval(TimeInterval(restRemainingSeconds))
        GymPitSharedStorage.set(restEndDate, forKey: WorkoutPersistenceKeys.restEndDate)
        WorkoutLiveActivityController.shared.setRest(seconds: restRemainingSeconds, for: plan)
        scheduleRestReadyNotification(seconds: restRemainingSeconds)
    }

    func addRestTime(_ seconds: Int) {
        let currentEndDate = GymPitSharedStorage.date(forKey: WorkoutPersistenceKeys.restEndDate)
        let baseEndDate = currentEndDate.map { max($0, Date()) } ?? Date().addingTimeInterval(TimeInterval(restRemainingSeconds))
        let restEndDate = baseEndDate.addingTimeInterval(TimeInterval(seconds))
        restTimerState.update(remainingSeconds: Int(restEndDate.timeIntervalSinceNow.rounded(.up)))

        guard restRemainingSeconds > 0 else {
            stopRestTimer()
            return
        }

        GymPitSharedStorage.set(restEndDate, forKey: WorkoutPersistenceKeys.restEndDate)
        WorkoutLiveActivityController.shared.setRest(seconds: restRemainingSeconds, for: plan)
        scheduleRestReadyNotification(seconds: restRemainingSeconds)
    }

    func stopRestTimer() {
        restTimerState.update(remainingSeconds: 0)
        GymPitSharedStorage.set(nil as Date?, forKey: WorkoutPersistenceKeys.restEndDate)
        if let exerciseID = plan.currentExerciseID {
            cancelNotifications(for: exerciseID)
        }
        WorkoutLiveActivityController.shared.clearRest(for: plan)
    }

    func clearDeliveredWorkoutNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(plan) else { return }
        GymPitSharedStorage.set(data, forKey: WorkoutPersistenceKeys.plan)
    }

    private func saveRoutines() {
        guard let data = try? JSONEncoder().encode(routines) else { return }
        GymPitSharedStorage.set(data, forKey: WorkoutPersistenceKeys.routines)
    }

    private func saveDefaultRoutineID() {
        GymPitSharedStorage.set(defaultRoutineID?.uuidString, forKey: WorkoutPersistenceKeys.defaultRoutineID)
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        GymPitSharedStorage.set(data, forKey: WorkoutPersistenceKeys.history)
    }

    private func syncActiveRoutineFromPlan() {
        guard !isSyncingRoutine else { return }
        if let index = routines.firstIndex(where: { $0.id == plan.id }) {
            routines[index] = plan
        } else if !routines.isEmpty {
            routines.append(plan)
        }
    }

    private func uniqueExercises(_ exercises: [Exercise]) -> [Exercise] {
        var seen: Set<UUID> = []
        return exercises.filter { exercise in
            guard !seen.contains(exercise.id) else { return false }
            seen.insert(exercise.id)
            return true
        }
    }

    private func normalizedWeight(_ value: Double) -> Double {
        min(400, max(0, (value * 100).rounded() / 100))
    }

    private func resetSets(for exerciseID: UUID) {
        guard let index = plan.exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
        plan.exercises[index].sets = plan.exercises[index].sets.map {
            ExerciseSet(id: $0.id, type: $0.type, reps: $0.reps, weight: $0.weight, rpe: $0.rpe, isLogged: false)
        }
    }

    private func updateLiveActivity() {
        if plan.isWorkoutStarted {
            WorkoutLiveActivityController.shared.refresh(for: plan)
        } else {
            WorkoutLiveActivityController.shared.end()
        }
    }

    private func archiveWorkoutIfNeeded(
        sessionID requestedSessionID: UUID? = nil,
        durationMinutes measuredDurationMinutes: Double? = nil,
        activeCalories measuredActiveCalories: Double? = nil,
        healthWorkoutSaved: Bool = false
    ) -> WorkoutSession? {
        guard plan.archivedSessionID == nil else { return nil }

        let sessionID = requestedSessionID ?? UUID()
        let sessionExercises = plan.exercises.compactMap { exercise -> WorkoutSessionExercise? in
            let loggedSets = exercise.sets.filter(\.isLogged)
            guard !loggedSets.isEmpty else { return nil }

            return WorkoutSessionExercise(
                id: exercise.id,
                catalogID: exercise.catalogID,
                name: exercise.name,
                category: exercise.category,
                notes: exercise.notes,
                deviceSettings: exercise.device,
                sets: loggedSets.map {
                    let recordFlags = personalRecordFlags(for: $0, in: exercise)
                    return WorkoutSessionSet(
                        id: $0.id,
                        type: $0.type,
                        reps: $0.reps,
                        weight: $0.weight,
                        rpe: $0.rpe,
                        isPersonalRecord: recordFlags.hasAny
                    )
                }
            )
        }
        guard !sessionExercises.isEmpty else { return nil }

        let estimatedDuration = plan.exercises.reduce(0.0) { $0 + $1.estimatedMinutes(using: plan.profile) }
        let duration = if let measuredDurationMinutes, measuredDurationMinutes > 0 {
            measuredDurationMinutes
        } else if plan.actualDurationMinutes > 0 {
            plan.actualDurationMinutes
        } else {
            estimatedDuration
        }
        let calories = if let measuredActiveCalories, measuredActiveCalories > 0 {
            Int(measuredActiveCalories.rounded())
        } else {
            estimatedCaloriesForLoggedExercises()
        }
        let session = WorkoutSession(
            id: sessionID,
            planName: plan.name,
            date: Date(),
            notes: plan.workoutNotes,
            durationMinutes: duration,
            calories: calories,
            exercises: sessionExercises
        )

        history.insert(session, at: 0)
        sortHistoryByPerformedDate()
        plan.archivedSessionID = sessionID
        if healthWorkoutSaved {
            healthExportedSessionIDs.insert(sessionID)
            saveHealthExportedSessionIDs()
            healthExportStatus = .info(AppLanguage.current.ui("Apple Health verbunden"))
        } else if WorkoutHealthExporter.shared.isAuthorizedForAutomaticSave {
            exportSessionToHealth(session)
        } else {
            healthExportStatus = .info(AppLanguage.current.ui("Apple Health nicht verbunden"))
        }
        uploadSessionToBridge(session)
        return session
    }

    private func uploadSessionToBridge(_ session: WorkoutSession) {
        bridgeSyncStatus = .info(AppLanguage.current.ui("HealthPit Export läuft..."))
        Task {
            do {
                let summary = try await GymPitBridgeSyncService.shared.upload(session)
                await MainActor.run {
                    if summary.uploaded == 0 {
                        bridgeSyncStatus = .info(AppLanguage.current.ui("HealthPit: schon übertragen"))
                    } else {
                        bridgeSyncStatus = .info("HealthPit " + bridgeSummaryText(summary))
                    }
                }
            } catch {
                await MainActor.run {
                    bridgeSyncStatus = .error(
                        AppLanguage.current.ui(format: "HealthPit Fehler: %@", error.localizedDescription)
                    )
                }
            }
        }
    }

    private func bridgeSummaryText(_ summary: GymPitBridgeUploadSummary) -> String {
        let language = AppLanguage.current
        var parts: [String] = []
        if summary.created > 0 {
            parts.append(language.ui(format: "Neu: %d", summary.created))
        }
        if summary.updated > 0 {
            parts.append(language.ui(format: "Aktualisiert: %d", summary.updated))
        }
        if parts.isEmpty {
            parts.append(language.ui(format: "Übertragen: %d", summary.uploaded))
        }

        parts.append(language.ui(format: "Übungen: %d", summary.exercises))
        parts.append(language.ui(format: "Sätze: %d", summary.sets))
        if summary.volumeKg > 0 {
            parts.append(
                language.ui(format: "Volumen: %@", summary.volumeKg.formattedWeight(unit: .kilograms))
            )
        }
        return parts.joined(separator: " · ")
    }

    private func exportSessionToHealth(_ session: WorkoutSession) {
        healthExportStatus = .info(AppLanguage.current.ui("Apple Health Export läuft..."))
        saveSessionToHealthIfNeeded(session) { [weak self] result in
            switch result {
            case .success(.saved):
                self?.healthExportStatus = .info(AppLanguage.current.ui(
                    format: "Übertragen: %@, %d min, %d kcal",
                    session.planName,
                    Int(session.durationMinutes.rounded()),
                    session.calories
                ))
            case .success(.alreadyExists):
                self?.healthExportStatus = .info(
                    AppLanguage.current.ui(format: "Bereits in Apple Health: %@", session.planName)
                )
            case .failure(let error):
                self?.healthExportStatus = .error(
                    AppLanguage.current.ui(format: "Apple Health Fehler: %@", error.localizedDescription)
                )
            }
        }
    }

    private func exportHistoricSessions(
        _ sessions: [WorkoutSession],
        total: Int,
        completed: Int,
        skipped: Int,
        failed: Int
    ) {
        guard let session = sessions.first else {
            isHealthExportInProgress = false
            if failed > 0 {
                healthExportStatus = .error(AppLanguage.current.ui(
                    format: "Fertig: %d übertragen, %d bereits vorhanden, %d Fehler",
                    completed, skipped, failed
                ))
            } else if completed == 0 {
                healthExportStatus = .info(AppLanguage.current.ui(
                    format: "Keine Duplikate angelegt: %d Workouts bereits vorhanden", skipped
                ))
            } else {
                healthExportStatus = .info(AppLanguage.current.ui(
                    format: "Fertig: %d übertragen, %d bereits vorhanden", completed, skipped
                ))
            }
            return
        }

        saveSessionToHealthIfNeeded(session) { [weak self] result in
            let remaining = Array(sessions.dropFirst())
            let processed = total - remaining.count

            switch result {
            case .success(.saved):
                self?.healthExportStatus = .info(AppLanguage.current.ui(
                    format: "Apple Health: %d/%d · %d übertragen", processed, total, completed + 1
                ))
                self?.exportHistoricSessions(
                    remaining,
                    total: total,
                    completed: completed + 1,
                    skipped: skipped,
                    failed: failed
                )
            case .success(.alreadyExists):
                self?.healthExportStatus = .info(AppLanguage.current.ui(
                    format: "Apple Health: %d/%d · bereits vorhanden", processed, total
                ))
                self?.exportHistoricSessions(
                    remaining,
                    total: total,
                    completed: completed,
                    skipped: skipped + 1,
                    failed: failed
                )
            case .failure:
                self?.healthExportStatus = .error(AppLanguage.current.ui(
                    format: "Apple Health: %d/%d · Fehler", processed, total
                ))
                self?.exportHistoricSessions(
                    remaining,
                    total: total,
                    completed: completed,
                    skipped: skipped,
                    failed: failed + 1
                )
            }
        }
    }

    private func saveSessionToHealthIfNeeded(
        _ session: WorkoutSession,
        completion: @escaping (Result<WorkoutHealthSaveResult, Error>) -> Void
    ) {
        guard !healthExportedSessionIDs.contains(session.id),
              !healthExportSessionIDsInFlight.contains(session.id) else {
            completion(.success(.alreadyExists))
            return
        }

        healthExportSessionIDsInFlight.insert(session.id)
        WorkoutHealthExporter.shared.save(session) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.healthExportSessionIDsInFlight.remove(session.id)
                if case .success = result {
                    self.healthExportedSessionIDs.insert(session.id)
                    self.saveHealthExportedSessionIDs()
                }
                completion(result)
            }
        }
    }

    private func saveHealthExportedSessionIDs() {
        guard let data = try? JSONEncoder().encode(healthExportedSessionIDs.sorted { $0.uuidString < $1.uuidString }) else { return }
        GymPitSharedStorage.set(data, forKey: WorkoutPersistenceKeys.healthExportedSessionIDs)
    }

    private func deleteSessionsFromHealth(_ sessions: [WorkoutSession], total: Int, completed: Int, failed: Int) {
        guard let session = sessions.first else {
            if total > 0 {
                if failed == 0 {
                    healthExportStatus = .info(
                        AppLanguage.current.ui(format: "Aus Apple Health gelöscht (%d)", completed)
                    )
                } else {
                    healthExportStatus = .error(AppLanguage.current.ui(
                        format: "Aus Apple Health gelöscht: %d, Fehler: %d", completed, failed
                    ))
                }
            }
            return
        }

        guard WorkoutHealthExporter.shared.isAuthorizedForAutomaticSave else {
            healthExportStatus = .info(AppLanguage.current.ui("Apple Health nicht verbunden"))
            return
        }

        if completed == 0 && failed == 0 {
            healthExportStatus = .info(AppLanguage.current.ui("Apple Health Löschen läuft..."))
        }

        let remaining = Array(sessions.dropFirst())
        WorkoutHealthExporter.shared.delete(session) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    self?.healthExportedSessionIDs.remove(session.id)
                    self?.saveHealthExportedSessionIDs()
                    self?.deleteSessionsFromHealth(remaining, total: total, completed: completed + 1, failed: failed)
                case .failure:
                    self?.deleteSessionsFromHealth(remaining, total: total, completed: completed, failed: failed + 1)
                }
            }
        }
    }

    private func estimatedCaloriesForLoggedExercises() -> Int {
        let calories = plan.exercises.reduce(0.0) { partial, exercise in
            let minutes = exercise.estimatedMinutes(using: plan.profile)
            return partial + exercise.metValue * plan.profile.calorieOxygenFactor * plan.profile.bodyWeightKilograms / plan.profile.calorieDivisor * minutes
        }
        return Int(calories.rounded())
    }

    private func sessionWithEstimatedCaloriesIfNeeded(_ session: WorkoutSession) -> WorkoutSession {
        guard session.calories <= 0 else { return session }

        var updatedSession = session
        updatedSession.calories = estimatedCalories(forImportedSession: session)
        return updatedSession
    }

    private func estimatedCalories(forImportedSession session: WorkoutSession) -> Int {
        guard !session.exercises.isEmpty else { return 0 }

        let fallbackDuration = session.exercises.reduce(0.0) { partial, exercise in
            partial + Double(max(1, exercise.sets.count)) * plan.profile.minutesPerSet
        }
        let duration = session.durationMinutes > 0 ? session.durationMinutes : fallbackDuration
        let weightedSetCount = session.exercises.reduce(0) { $0 + max(1, $1.sets.count) }

        let calories = session.exercises.reduce(0.0) { partial, exercise in
            let exerciseMinutes = duration * Double(max(1, exercise.sets.count)) / Double(max(1, weightedSetCount))
            let kcal = metValue(for: exercise) * plan.profile.calorieOxygenFactor * plan.profile.bodyWeightKilograms / plan.profile.calorieDivisor * exerciseMinutes
            return partial + kcal
        }

        return max(1, Int(calories.rounded()))
    }

    private func metValue(for sessionExercise: WorkoutSessionExercise) -> Double {
        if let catalogExercise = ExerciseCatalog.all.first(where: { $0.id == sessionExercise.catalogID }) {
            return catalogExercise.metValue
        }

        if let mappedExercise = matchedExercise(for: sessionExercise) {
            return mappedExercise.metValue
        }

        switch sessionExercise.category {
        case .legs, .cardio:
            return 6.0
        case .core:
            return 4.0
        case .chest, .back, .shoulders, .arms, .freeWeights:
            return 5.0
        }
    }

    private func matchedExercise(for sessionExercise: WorkoutSessionExercise) -> Exercise? {
        let knownExercises = knownExercisesForMatching()
        if let catalogMatch = knownExercises.first(where: { $0.catalogID == sessionExercise.catalogID }) {
            return catalogMatch
        }

        let importedName = normalizedExerciseName(sessionExercise.name)
        guard !importedName.isEmpty else { return nil }
        return knownExercises.first { exercise in
            normalizedExerciseName(exercise.name) == importedName ||
            normalizedExerciseName(exercise.localizedName(language: AppLanguage.german)) == importedName ||
            normalizedExerciseName(exercise.localizedName(language: AppLanguage.english)) == importedName
        }
    }

    private func knownExercisesForMatching() -> [Exercise] {
        var exercises = ExerciseCatalog.all.map { $0.makeImportMappingExercise() }
        var seenCatalogIDs = Set(exercises.map(\.catalogID))
        for exercise in plan.exercises + routines.flatMap(\.exercises) {
            guard exercise.isCustom, !seenCatalogIDs.contains(exercise.catalogID) else { continue }
            seenCatalogIDs.insert(exercise.catalogID)
            exercises.append(exercise)
        }
        return exercises
    }

    private func normalizedExerciseName(_ name: String) -> String {
        name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
            .lowercased()
    }

    private func sortHistoryByPerformedDate() {
        history = sortedHistory(history)
    }

    private func sortedHistory(_ sessions: [WorkoutSession]) -> [WorkoutSession] {
        sessions.sorted {
            if $0.date == $1.date {
                return $0.planName.localizedStandardCompare($1.planName) == .orderedAscending
            }

            return $0.date > $1.date
        }
    }

    private func historicalExercises(for exercise: Exercise) -> [WorkoutSessionExercise] {
        let exerciseName = normalizedExerciseName(exercise.name)
        return history
            .sorted { $0.date < $1.date }
            .compactMap { session in
                session.exercises.first {
                    $0.catalogID == exercise.catalogID ||
                    (!exerciseName.isEmpty && normalizedExerciseName($0.name) == exerciseName)
                }
            }
    }

    private func notificationExerciseID(from userInfo: [AnyHashable: Any]) -> UUID? {
        guard let idString = userInfo["exerciseID"] as? String else { return nil }
        return UUID(uuidString: idString)
    }

    private func nextOpenSetIndex(for exercise: Exercise) -> Int? {
        exercise.sets.firstIndex { !$0.isLogged }
    }

    private func nextSetText(for exercise: Exercise) -> String {
        let language = AppLanguage.current
        guard let index = nextOpenSetIndex(for: exercise) else {
            return language.ui("alle Sätze erledigt")
        }
        return "\(language.ui("Satz")) \(index + 1)/\(exercise.sets.count)"
    }

    private func completeNextSetFromNotification(exerciseID: UUID) {
        guard let exerciseIndex = plan.exercises.firstIndex(where: { $0.id == exerciseID }),
              !plan.completedExerciseIDs.contains(exerciseID),
              let setIndex = plan.exercises[exerciseIndex].sets.firstIndex(where: { !$0.isLogged }) else { return }

        plan.isWorkoutStarted = true
        plan.currentExerciseID = exerciseID
        cancelNotifications(for: exerciseID)
        plan.exercises[exerciseIndex].sets[setIndex].isLogged = true

        let exercise = plan.exercises[exerciseIndex]
        if exercise.sets.allSatisfy(\.isLogged) {
            finishExerciseAfterAllSets(exerciseID: exerciseID)
        } else {
            startRestTimer(seconds: exercise.restSeconds)
        }
    }

    private func configureNotifications() {
        AppNotificationCenter.registerCategories()
        clearWorkoutNotifications()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func clearWorkoutNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    private func cancelNotifications(for exerciseID: UUID) {
        let identifiers = notificationIdentifiers(for: exerciseID)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func notificationIdentifiers(for exerciseID: UUID) -> [String] {
        [
            "rest-\(exerciseID.uuidString)",
            "exercise-\(exerciseID.uuidString)"
        ]
    }

    private func finishExerciseAfterAllSets(exerciseID: UUID) {
        cancelNotifications(for: exerciseID)
        stopRestTimer()

        if !plan.completedExerciseIDs.contains(exerciseID),
           plan.exercises.first(where: { $0.id == exerciseID })?.sets.allSatisfy(\.isLogged) == true {
            plan.completedExerciseIDs.append(exerciseID)
        }

        if plan.currentExerciseID == exerciseID {
            plan.currentExerciseID = plan.openExercises.first?.id
        }

        plan.isCompletedSectionExpanded = false
    }

    private func normalizedCompletionGoal(_ goal: WorkoutCompletionGoal) -> WorkoutCompletionGoal {
        switch goal.mode {
        case .allExercises:
            return .allExercises
        case .exerciseCount:
            return WorkoutCompletionGoal(mode: .exerciseCount, value: Double(max(1, min(Int(goal.value.rounded()), plan.exercises.count))))
        case .totalVolume, .durationMinutes, .setCount:
            return WorkoutCompletionGoal(mode: goal.mode, value: max(1, goal.value))
        }
    }

    private func scheduleRestReadyNotification(seconds: Int) {
        guard seconds > 0,
              let exercise = plan.activeExercise,
              !plan.completedExerciseIDs.contains(exercise.id),
              !exercise.sets.allSatisfy(\.isLogged) else { return }

        AppNotificationCenter.registerCategories()
        cancelNotifications(for: exercise.id)

        let content = UNMutableNotificationContent()
        content.title = AppLanguage.current.ui("Pause fertig")
        content.body = restNotificationBody(for: exercise)
        content.sound = .default
        content.categoryIdentifier = GymPitNotificationIDs.restReadyCategory
        content.threadIdentifier = "workout-\(plan.id.uuidString)"
        content.userInfo = ["exerciseID": exercise.id.uuidString]
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "rest-\(exercise.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func restNotificationBody(for exercise: Exercise) -> String {
        let language = AppLanguage.current
        let setText = nextSetText(for: exercise)
        let weight = exercise.sets.first(where: { !$0.isLogged })?.weight ?? exercise.lastLoggedWeight ?? 0
        let weightText = weight > 0 ? " · \(weight.formattedWeight(unit: .current))" : ""
        let trainingMinutes = Int(plan.actualDurationMinutes.rounded(.down))
        return "\(exercise.localizedName(language: language)): \(setText)\(weightText) \(language.ui("bereit")) · \(language.ui("Training")) \(trainingMinutes) min"
    }

}
