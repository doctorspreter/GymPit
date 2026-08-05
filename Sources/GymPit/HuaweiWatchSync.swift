import Foundation

struct HuaweiWatchImportSummary: Equatable {
    let imported: Int
    let skipped: Int
    let rows: Int
}

enum HuaweiWatchSyncError: LocalizedError {
    case unsupportedPayload

    var errorDescription: String? {
        switch self {
        case .unsupportedPayload:
            "Die Huawei-Watch-Datei enthält kein unterstütztes GymPit-Format."
        }
    }
}

enum HuaweiWatchSyncCodec {
    static let schemaVersion = 1

    static func export(plan: WorkoutPlan, history: [WorkoutSession], restEndDate: Date?) throws -> Data {
        let payload = HuaweiWatchPayload(
            schemaVersion: schemaVersion,
            generatedAt: Date(),
            source: "GymPit iPhone",
            activeRoutine: HuaweiWatchRoutine(plan: plan, restEndDate: restEndDate),
            recentSessions: history.prefix(20).map { HuaweiWatchSession(session: $0) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    static func importSessions(from data: Data) throws -> [WorkoutSession] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let importPayload = try? decoder.decode(HuaweiWatchSessionImportPayload.self, from: data) {
            return importPayload.sessions.map(\.workoutSession)
        }

        if let payload = try? decoder.decode(HuaweiWatchPayload.self, from: data) {
            return payload.recentSessions.map(\.workoutSession)
        }

        if let sessions = try? decoder.decode([HuaweiWatchSession].self, from: data) {
            return sessions.map(\.workoutSession)
        }

        if let session = try? decoder.decode(HuaweiWatchSession.self, from: data) {
            return [session.workoutSession]
        }

        throw HuaweiWatchSyncError.unsupportedPayload
    }
}

private struct HuaweiWatchPayload: Codable {
    var schemaVersion: Int
    var generatedAt: Date
    var source: String
    var activeRoutine: HuaweiWatchRoutine
    var recentSessions: [HuaweiWatchSession]
}

private struct HuaweiWatchSessionImportPayload: Codable {
    var schemaVersion: Int
    var source: String?
    var sessions: [HuaweiWatchSession]
}

private struct HuaweiWatchRoutine: Codable {
    var id: UUID
    var name: String
    var notes: String
    var startedAt: Date?
    var isWorkoutStarted: Bool
    var activeExerciseID: UUID?
    var completionGoal: String
    var progress: String
    var restEndDate: Date?
    var exercises: [HuaweiWatchExercise]

    init(plan: WorkoutPlan, restEndDate: Date?) {
        let language = AppLanguage.current
        id = plan.id
        name = plan.name
        notes = plan.workoutNotes
        startedAt = plan.workoutStartedAt
        isWorkoutStarted = plan.isWorkoutStarted
        activeExerciseID = plan.activeExercise?.id
        completionGoal = language.ui(plan.completionGoal.mode.rawValue)
        progress = plan.progressSummary(language: language)
        self.restEndDate = restEndDate
        exercises = plan.exercises.map { exercise in
            HuaweiWatchExercise(
                exercise: exercise,
                isActive: exercise.id == plan.activeExercise?.id,
                isCompleted: plan.completedExerciseIDs.contains(exercise.id)
            )
        }
    }
}

private struct HuaweiWatchExercise: Codable {
    var id: UUID
    var catalogID: String
    var name: String
    var target: String
    var category: String
    var notes: String
    var restSeconds: Int
    var isActive: Bool
    var isCompleted: Bool
    var device: HuaweiWatchDeviceSettings
    var sets: [HuaweiWatchSet]

    init(exercise: Exercise, isActive: Bool, isCompleted: Bool) {
        id = exercise.id
        catalogID = exercise.catalogID
        name = exercise.name
        target = exercise.target
        category = exercise.category.rawValue
        notes = exercise.notes
        restSeconds = exercise.restSeconds
        self.isActive = isActive
        self.isCompleted = isCompleted
        device = HuaweiWatchDeviceSettings(settings: exercise.device)
        sets = exercise.sets.enumerated().map { index, set in
            HuaweiWatchSet(set: set, index: index + 1)
        }
    }
}

private struct HuaweiWatchDeviceSettings: Codable {
    var machineName: String
    var seat: String
    var backrest: String
    var handle: String
    var range: String
    var notes: String

    init(settings: DeviceSettings) {
        machineName = settings.machineName
        seat = settings.seat
        backrest = settings.backrest
        handle = settings.handle
        range = settings.range
        notes = settings.notes
    }
}

private struct HuaweiWatchSet: Codable {
    var id: UUID
    var index: Int
    var type: String
    var reps: Int
    var weight: Double
    var rpe: Int?
    var isLogged: Bool

    init(set: ExerciseSet, index: Int) {
        id = set.id
        self.index = index
        type = set.type.rawValue
        reps = set.reps
        weight = set.weight
        rpe = set.rpe
        isLogged = set.isLogged
    }
}

private struct HuaweiWatchSession: Codable {
    var id: UUID
    var planName: String
    var date: Date
    var notes: String
    var durationMinutes: Double
    var calories: Int
    var exercises: [HuaweiWatchSessionExercise]

    init(session: WorkoutSession) {
        id = session.id
        planName = session.planName
        date = session.date
        notes = session.notes
        durationMinutes = session.durationMinutes
        calories = session.calories
        exercises = session.exercises.map { HuaweiWatchSessionExercise(exercise: $0) }
    }

    var workoutSession: WorkoutSession {
        WorkoutSession(
            id: id,
            planName: planName,
            date: date,
            notes: notes,
            durationMinutes: durationMinutes,
            calories: calories,
            exercises: exercises.map(\.workoutSessionExercise)
        )
    }
}

private struct HuaweiWatchSessionExercise: Codable {
    var id: UUID
    var catalogID: String
    var name: String
    var category: String
    var notes: String
    var sets: [HuaweiWatchSessionSet]

    init(exercise: WorkoutSessionExercise) {
        id = exercise.id
        catalogID = exercise.catalogID
        name = exercise.name
        category = exercise.category.rawValue
        notes = exercise.notes
        sets = exercise.sets.map { HuaweiWatchSessionSet(set: $0) }
    }

    var workoutSessionExercise: WorkoutSessionExercise {
        WorkoutSessionExercise(
            id: id,
            catalogID: catalogID,
            name: name,
            category: DeviceCategory(rawValue: category) ?? .freeWeights,
            notes: notes,
            sets: sets.map(\.workoutSessionSet)
        )
    }
}

private struct HuaweiWatchSessionSet: Codable {
    var id: UUID
    var type: String
    var reps: Int
    var weight: Double
    var rpe: Int?

    init(set: WorkoutSessionSet) {
        id = set.id
        type = set.type.rawValue
        reps = set.reps
        weight = set.weight
        rpe = set.rpe
    }

    var workoutSessionSet: WorkoutSessionSet {
        WorkoutSessionSet(
            id: id,
            type: WorkoutSetType(rawValue: type) ?? .normal,
            reps: reps,
            weight: weight,
            rpe: rpe
        )
    }
}
