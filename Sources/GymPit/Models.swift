import Foundation

struct WorkoutPlan: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var profile: UserProfile
    var workoutNotes: String
    var completionGoal: WorkoutCompletionGoal
    var workoutStartedAt: Date?
    var exercises: [Exercise]
    var currentExerciseID: UUID?
    var completedExerciseIDs: [UUID]
    var isCompletedSectionExpanded: Bool
    var archivedSessionID: UUID?
    var isWorkoutStarted: Bool
    var workoutOnlyExerciseIDs: [UUID]
    var workoutOnlySetIDs: [UUID]

    init(
        id: UUID,
        name: String,
        profile: UserProfile,
        workoutNotes: String,
        completionGoal: WorkoutCompletionGoal = .allExercises,
        workoutStartedAt: Date? = nil,
        exercises: [Exercise],
        currentExerciseID: UUID?,
        completedExerciseIDs: [UUID],
        isCompletedSectionExpanded: Bool,
        archivedSessionID: UUID?,
        isWorkoutStarted: Bool,
        workoutOnlyExerciseIDs: [UUID] = [],
        workoutOnlySetIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.profile = profile
        self.workoutNotes = workoutNotes
        self.completionGoal = completionGoal
        self.workoutStartedAt = workoutStartedAt
        self.exercises = exercises
        self.currentExerciseID = currentExerciseID
        self.completedExerciseIDs = completedExerciseIDs
        self.isCompletedSectionExpanded = isCompletedSectionExpanded
        self.archivedSessionID = archivedSessionID
        self.isWorkoutStarted = isWorkoutStarted
        self.workoutOnlyExerciseIDs = workoutOnlyExerciseIDs
        self.workoutOnlySetIDs = workoutOnlySetIDs
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case profile
        case workoutNotes
        case completionGoal
        case workoutStartedAt
        case exercises
        case currentExerciseID
        case completedExerciseIDs
        case isCompletedSectionExpanded
        case archivedSessionID
        case isWorkoutStarted
        case workoutOnlyExerciseIDs
        case workoutOnlySetIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        profile = try container.decode(UserProfile.self, forKey: .profile)
        workoutNotes = try container.decodeIfPresent(String.self, forKey: .workoutNotes) ?? ""
        completionGoal = try container.decodeIfPresent(WorkoutCompletionGoal.self, forKey: .completionGoal) ?? .allExercises
        workoutStartedAt = try container.decodeIfPresent(Date.self, forKey: .workoutStartedAt)
        exercises = try container.decode([Exercise].self, forKey: .exercises)
        currentExerciseID = try container.decodeIfPresent(UUID.self, forKey: .currentExerciseID)
        completedExerciseIDs = try container.decodeIfPresent([UUID].self, forKey: .completedExerciseIDs) ?? []
        isCompletedSectionExpanded = try container.decodeIfPresent(Bool.self, forKey: .isCompletedSectionExpanded) ?? false
        archivedSessionID = try container.decodeIfPresent(UUID.self, forKey: .archivedSessionID)
        isWorkoutStarted = try container.decodeIfPresent(Bool.self, forKey: .isWorkoutStarted) ?? false
        workoutOnlyExerciseIDs = try container.decodeIfPresent([UUID].self, forKey: .workoutOnlyExerciseIDs) ?? []
        workoutOnlySetIDs = try container.decodeIfPresent([UUID].self, forKey: .workoutOnlySetIDs) ?? []
    }

    var activeExercise: Exercise? {
        guard let currentExerciseID else { return nextOpenExercise }
        return exercises.first { $0.id == currentExerciseID }
    }

    var openExercises: [Exercise] {
        exercises.filter { !completedExerciseIDs.contains($0.id) }
    }

    var nextOpenExercise: Exercise? {
        openExercises.first
    }

    var completedExercises: [Exercise] {
        completedExerciseIDs.compactMap { id in
            exercises.first { $0.id == id }
        }
    }

    var isFinished: Bool {
        !exercises.isEmpty && progressValue >= progressTarget
    }

    var progressValue: Double {
        switch completionGoal.mode {
        case .allExercises:
            return exercises.reduce(0) { partial, exercise in
                partial + exercise.completionFraction(isCompleted: completedExerciseIDs.contains(exercise.id))
            }
        case .exerciseCount:
            let fractionalCompletedExercises = exercises.reduce(0) { partial, exercise in
                partial + exercise.completionFraction(isCompleted: completedExerciseIDs.contains(exercise.id))
            }
            return min(progressTarget, fractionalCompletedExercises)
        case .totalVolume:
            return totalVolume
        case .durationMinutes:
            return actualDurationMinutes
        case .setCount:
            return Double(exercises.reduce(0) { $0 + $1.completedSetsCount })
        }
    }

    var progressTarget: Double {
        switch completionGoal.mode {
        case .allExercises:
            return Double(max(1, exercises.count))
        case .exerciseCount:
            return Double(max(1, min(Int(completionGoal.value.rounded()), exercises.count)))
        case .totalVolume:
            return max(1, completionGoal.value)
        case .durationMinutes:
            return max(1, completionGoal.value)
        case .setCount:
            return max(1, completionGoal.value)
        }
    }

    var progressFraction: Double {
        min(1, max(0, progressValue / progressTarget))
    }

    var progressSummary: String {
        "\(formattedProgressValue)/\(formattedProgressTarget) \(completionGoal.mode.unitTitle)"
    }

    func progressSummary(language: AppLanguage) -> String {
        "\(formattedProgressValue)/\(formattedProgressTarget) \(language.ui(completionGoal.mode.unitTitle))"
    }

    var actualDurationMinutes: Double {
        guard isWorkoutStarted, let workoutStartedAt else { return 0 }
        return max(0, Date().timeIntervalSince(workoutStartedAt) / 60)
    }

    private var formattedProgressValue: String {
        switch completionGoal.mode {
        case .allExercises, .exerciseCount:
            return progressValue.formattedProgressValue
        case .setCount:
            return "\(Int(progressValue.rounded(.down)))"
        case .durationMinutes:
            return "\(Int(progressValue.rounded(.down)))"
        case .totalVolume:
            return progressValue.formattedWeight
        }
    }

    private var formattedProgressTarget: String {
        switch completionGoal.mode {
        case .allExercises, .exerciseCount, .setCount:
            return "\(Int(progressTarget.rounded()))"
        case .durationMinutes:
            return "\(Int(progressTarget.rounded()))"
        case .totalVolume:
            return progressTarget.formattedWeight
        }
    }

    var totalCompletedSets: Int {
        exercises.reduce(0) { $0 + $1.completedSetsCount }
    }

    var estimatedCalories: Int {
        let calories = exercises.reduce(0.0) { partial, exercise in
            let minutes = exercise.estimatedMinutes(using: profile)
            let kcal = exercise.metValue * profile.calorieOxygenFactor * profile.bodyWeightKilograms / profile.calorieDivisor * minutes
            return partial + kcal
        }

        return Int(calories.rounded())
    }

    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.volume }
    }

    var muscleDistribution: [(category: DeviceCategory, count: Double)] {
        aggregateMuscleDistribution { _ in (completed: 0, planned: 1) }
            .map { (category: $0.category, count: $0.plannedSets) }
    }

    var muscleProgressDistribution: [(category: DeviceCategory, completedSets: Double, plannedSets: Double)] {
        aggregateMuscleDistribution { exercise in
            (
                completed: Double(exercise.completedSetsCount),
                planned: Double(exercise.sets.count)
            )
        }
    }

    private func aggregateMuscleDistribution(
        _ setCountsFor: (Exercise) -> (completed: Double, planned: Double)
    ) -> [(category: DeviceCategory, completedSets: Double, plannedSets: Double)] {
        var totals: [DeviceCategory: (completed: Double, planned: Double)] = [:]

        for exercise in exercises {
            let setCounts = setCountsFor(exercise)

            for (category, weight) in exercise.muscleWeights {
                totals[category, default: (completed: 0, planned: 0)].completed += setCounts.completed * weight
                totals[category, default: (completed: 0, planned: 0)].planned += setCounts.planned * weight
            }
        }

        return DeviceCategory.allCases.compactMap { category in
            guard let total = totals[category], total.planned > 0 else { return nil }
            return (category: category, completedSets: total.completed, plannedSets: total.planned)
        }
    }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kilograms
    case pounds

    static let storageKey = "gympit_weight_unit"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kilograms: "Kilogramm"
        case .pounds: "Pfund"
        }
    }

    var symbol: String {
        switch self {
        case .kilograms: "kg"
        case .pounds: "lbs"
        }
    }

    static var current: WeightUnit {
        let appGroupValue = UserDefaults(suiteName: "group.app.gympit")?.string(forKey: storageKey)
        return value(for: appGroupValue ?? UserDefaults.standard.string(forKey: storageKey) ?? WeightUnit.kilograms.rawValue)
    }

    static func value(for rawValue: String) -> WeightUnit {
        WeightUnit(rawValue: rawValue) ?? .kilograms
    }

    func displayValue(fromKilograms kilograms: Double) -> Double {
        switch self {
        case .kilograms: kilograms
        case .pounds: kilograms * 2.2046226218
        }
    }

    func kilograms(fromDisplayValue value: Double) -> Double {
        switch self {
        case .kilograms: value
        case .pounds: value / 2.2046226218
        }
    }
}

/// Per-machine weight step. Always stored in kilograms so the value survives a
/// unit switch, but offered to the user in whatever unit they currently use —
/// a gym with pound plates picks 5 lb, a metric stack picks 2.5 kg.
enum WeightIncrement {
    static let defaultKilograms: Double = 2.5

    /// Upper bound for a step. Anything larger is a typo rather than a plate.
    static let maximumKilograms: Double = 50

    static func sanitizedKilograms(_ value: Double) -> Double {
        guard value.isFinite, value > 0 else { return defaultKilograms }
        return min(maximumKilograms, (value * 100).rounded() / 100)
    }

    /// Label for a stored kilogram value, e.g. "2,5 kg" or "5 lbs".
    static func label(kilograms: Double, unit: WeightUnit) -> String {
        let display = unit.displayValue(fromKilograms: kilograms)
        let rounded = (display * 100).rounded() / 100
        return "\(rounded.formatted(.number.precision(.fractionLength(0...2)))) \(unit.symbol)"
    }
}

struct UserProfile: Codable, Equatable {
    var bodyWeightKilograms: Double
    var minutesPerSet: Double
    var setupMinutesPerExercise: Double
    var defaultRestSeconds: Int
    var calorieOxygenFactor: Double
    var calorieDivisor: Double

    init(
        bodyWeightKilograms: Double,
        minutesPerSet: Double,
        setupMinutesPerExercise: Double,
        defaultRestSeconds: Int,
        calorieOxygenFactor: Double = 3.5,
        calorieDivisor: Double = 200
    ) {
        self.bodyWeightKilograms = bodyWeightKilograms
        self.minutesPerSet = minutesPerSet
        self.setupMinutesPerExercise = setupMinutesPerExercise
        self.defaultRestSeconds = defaultRestSeconds
        self.calorieOxygenFactor = calorieOxygenFactor
        self.calorieDivisor = calorieDivisor
    }

    private enum CodingKeys: String, CodingKey {
        case bodyWeightKilograms
        case minutesPerSet
        case setupMinutesPerExercise
        case defaultRestSeconds
        case calorieOxygenFactor
        case calorieDivisor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bodyWeightKilograms = try container.decode(Double.self, forKey: .bodyWeightKilograms)
        minutesPerSet = try container.decode(Double.self, forKey: .minutesPerSet)
        setupMinutesPerExercise = try container.decode(Double.self, forKey: .setupMinutesPerExercise)
        defaultRestSeconds = try container.decode(Int.self, forKey: .defaultRestSeconds)
        calorieOxygenFactor = try container.decodeIfPresent(Double.self, forKey: .calorieOxygenFactor) ?? 3.5
        calorieDivisor = try container.decodeIfPresent(Double.self, forKey: .calorieDivisor) ?? 200
    }
}

struct WorkoutCompletionGoal: Codable, Equatable {
    var mode: WorkoutCompletionGoalMode
    var value: Double

    static let allExercises = WorkoutCompletionGoal(mode: .allExercises, value: 0)
}

enum WorkoutCompletionGoalMode: String, Codable, CaseIterable, Identifiable {
    case allExercises = "Alle Übungen"
    case exerciseCount = "Übungsanzahl"
    case totalVolume = "Gesamtvolumen"
    case durationMinutes = "Trainingszeit"
    case setCount = "Satzanzahl"

    var id: String { rawValue }

    var unitTitle: String {
        switch self {
        case .allExercises, .exerciseCount:
            "Übungen"
        case .totalVolume:
            "kg"
        case .durationMinutes:
            "min"
        case .setCount:
            "Sätze"
        }
    }
}

struct Exercise: Codable, Identifiable, Equatable {
    var id: UUID
    var catalogID: String
    var name: String
    var target: String
    var category: DeviceCategory
    var customMuscleDistribution: [MuscleDistributionShare]
    var metValue: Double
    var device: DeviceSettings
    var notes: String
    var restSeconds: Int
    var supersetGroup: Int?
    var isFavorite: Bool
    var isCustom: Bool
    var usesDedicatedDevice: Bool?
    var iconTemplateID: String?
    var shouldIncreaseWeightNextTime: Bool
    /// Smallest weight change this machine actually allows, in kilograms.
    /// Plate-loaded and pin-stack machines differ, so it is stored per exercise
    /// and drives the +/- buttons on the watch.
    var weightIncrement: Double
    var sets: [ExerciseSet]

    init(
        id: UUID,
        catalogID: String,
        name: String,
        target: String,
        category: DeviceCategory,
        customMuscleDistribution: [MuscleDistributionShare] = [],
        metValue: Double,
        device: DeviceSettings,
        notes: String,
        restSeconds: Int,
        supersetGroup: Int?,
        isFavorite: Bool,
        isCustom: Bool,
        usesDedicatedDevice: Bool? = nil,
        iconTemplateID: String? = nil,
        shouldIncreaseWeightNextTime: Bool = false,
        weightIncrement: Double = WeightIncrement.defaultKilograms,
        sets: [ExerciseSet]
    ) {
        self.id = id
        self.catalogID = catalogID
        self.name = name
        self.target = target
        self.category = category
        self.customMuscleDistribution = MuscleDistributionShare.normalizedShares(customMuscleDistribution)
        self.metValue = metValue
        self.device = device
        self.notes = notes
        self.restSeconds = restSeconds
        self.supersetGroup = supersetGroup
        self.isFavorite = isFavorite
        self.isCustom = isCustom
        self.usesDedicatedDevice = usesDedicatedDevice
        self.iconTemplateID = iconTemplateID
        self.shouldIncreaseWeightNextTime = shouldIncreaseWeightNextTime
        self.weightIncrement = WeightIncrement.sanitizedKilograms(weightIncrement)
        self.sets = sets
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case catalogID
        case name
        case target
        case category
        case customMuscleDistribution
        case metValue
        case device
        case notes
        case restSeconds
        case supersetGroup
        case isFavorite
        case isCustom
        case usesDedicatedDevice
        case iconTemplateID
        case shouldIncreaseWeightNextTime
        case weightIncrement
        case sets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        catalogID = try container.decode(String.self, forKey: .catalogID)
        name = try container.decode(String.self, forKey: .name)
        target = try container.decode(String.self, forKey: .target)
        category = try container.decode(DeviceCategory.self, forKey: .category)
        customMuscleDistribution = MuscleDistributionShare.normalizedShares(
            try container.decodeIfPresent([MuscleDistributionShare].self, forKey: .customMuscleDistribution) ?? []
        )
        metValue = try container.decodeIfPresent(Double.self, forKey: .metValue) ?? (category == .cardio ? 6.0 : 5.0)
        device = try container.decodeIfPresent(DeviceSettings.self, forKey: .device) ?? .empty
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        restSeconds = try container.decodeIfPresent(Int.self, forKey: .restSeconds) ?? 90
        supersetGroup = try container.decodeIfPresent(Int.self, forKey: .supersetGroup)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? catalogID.hasPrefix("custom-")
        usesDedicatedDevice = try container.decodeIfPresent(Bool.self, forKey: .usesDedicatedDevice)
        iconTemplateID = try container.decodeIfPresent(String.self, forKey: .iconTemplateID)
        shouldIncreaseWeightNextTime = try container.decodeIfPresent(Bool.self, forKey: .shouldIncreaseWeightNextTime) ?? false
        weightIncrement = WeightIncrement.sanitizedKilograms(
            try container.decodeIfPresent(Double.self, forKey: .weightIncrement) ?? WeightIncrement.defaultKilograms
        )
        sets = try container.decode([ExerciseSet].self, forKey: .sets)
    }

    var lastLoggedWeight: Double? {
        sets.last(where: { $0.isLogged })?.weight
    }

    var maximumWeight: Double? {
        sets.filter(\.isLogged).map(\.weight).max()
    }

    var completedSetsCount: Int {
        sets.filter(\.isLogged).count
    }

    func completionFraction(isCompleted: Bool) -> Double {
        if isCompleted { return 1 }
        let totalSets = max(1, sets.count)
        return min(1, max(0, Double(completedSetsCount) / Double(totalSets)))
    }

    var volume: Double {
        sets.filter(\.isLogged).reduce(0) { partial, set in
            partial + Double(set.reps) * set.weight
        }
    }

    var estimatedOneRepMax: Double? {
        sets
            .filter { $0.isLogged && $0.reps > 0 && $0.weight > 0 }
            .map { $0.weight * (1 + Double($0.reps) / 30) }
            .max()
    }

    func estimatedMinutes(using profile: UserProfile) -> Double {
        guard completedSetsCount > 0 else { return 0 }
        return Double(completedSetsCount) * profile.minutesPerSet + profile.setupMinutesPerExercise
    }

    var iconName: String {
        if let iconTemplateID, !iconTemplateID.isEmpty {
            return ExerciseCatalog.iconName(for: iconTemplateID, category: category)
        }
        return ExerciseCatalog.iconName(for: catalogID, category: category)
    }

    var muscleWeights: [DeviceCategory: Double] {
        let customWeights = MuscleDistributionShare.normalizedWeights(customMuscleDistribution)
        if !customWeights.isEmpty {
            return customWeights
        }

        return ExerciseCatalog.muscleWeights(for: catalogID, fallback: category)
    }

    var effectiveMuscleDistribution: [MuscleDistributionShare] {
        MuscleDistributionShare.shares(from: muscleWeights)
    }

    var isDeviceBased: Bool {
        if let catalogItem = ExerciseCatalog.item(for: catalogID) {
            return catalogItem.kind == .device
        }

        if let usesDedicatedDevice {
            return usesDedicatedDevice
        }

        if category == .freeWeights {
            return false
        }

        return !device.machineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct MuscleDistributionShare: Codable, Identifiable, Equatable {
    var category: DeviceCategory
    var weight: Double

    var id: String { category.id }

    static func defaultShares(for category: DeviceCategory) -> [MuscleDistributionShare] {
        guard DeviceCategory.muscleCategories.contains(category) else { return [] }
        return [MuscleDistributionShare(category: category, weight: 1)]
    }

    static func shares(from weights: [DeviceCategory: Double]) -> [MuscleDistributionShare] {
        normalizedShares(
            weights.map { category, weight in
                MuscleDistributionShare(category: category, weight: weight)
            }
        )
    }

    static func normalizedWeights(_ shares: [MuscleDistributionShare]) -> [DeviceCategory: Double] {
        Dictionary(uniqueKeysWithValues: normalizedShares(shares).map { ($0.category, $0.weight) })
    }

    static func normalizedShares(_ shares: [MuscleDistributionShare]) -> [MuscleDistributionShare] {
        var totals: [DeviceCategory: Double] = [:]

        for share in shares where DeviceCategory.muscleCategories.contains(share.category) && share.weight > 0 {
            totals[share.category, default: 0] += share.weight
        }

        let totalWeight = totals.values.reduce(0, +)
        guard totalWeight > 0 else { return [] }

        return DeviceCategory.muscleCategories.compactMap { category in
            guard let weight = totals[category], weight > 0 else { return nil }
            return MuscleDistributionShare(category: category, weight: weight / totalWeight)
        }
    }
}

struct DeviceSettings: Codable, Equatable {
    var machineName: String
    var seat: String
    var backrest: String
    var handle: String
    var range: String
    var notes: String

    static let empty = DeviceSettings(machineName: "", seat: "", backrest: "", handle: "", range: "", notes: "")

    private enum CodingKeys: String, CodingKey {
        case machineName
        case seat
        case backrest
        case handle
        case range
        case notes
    }

    init(machineName: String, seat: String, backrest: String, handle: String, range: String, notes: String) {
        self.machineName = machineName
        self.seat = seat
        self.backrest = backrest
        self.handle = handle
        self.range = range
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        machineName = try container.decodeIfPresent(String.self, forKey: .machineName) ?? ""
        seat = try container.decodeIfPresent(String.self, forKey: .seat) ?? ""
        backrest = try container.decodeIfPresent(String.self, forKey: .backrest) ?? ""
        handle = try container.decodeIfPresent(String.self, forKey: .handle) ?? ""
        range = try container.decodeIfPresent(String.self, forKey: .range) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

struct ExerciseSet: Codable, Identifiable, Equatable {
    var id: UUID
    var type: WorkoutSetType
    var reps: Int
    var weight: Double
    var rpe: Int?
    var isLogged: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case reps
        case weight
        case rpe
        case isLogged
    }

    init(id: UUID, type: WorkoutSetType, reps: Int, weight: Double, rpe: Int?, isLogged: Bool) {
        self.id = id
        self.type = type
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.isLogged = isLogged
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        type = try container.decodeIfPresent(WorkoutSetType.self, forKey: .type) ?? .normal
        reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 12
        weight = try container.decodeIfPresent(Double.self, forKey: .weight) ?? 0
        rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
        isLogged = try container.decodeIfPresent(Bool.self, forKey: .isLogged) ?? false
    }
}

enum WorkoutSetType: String, Codable, CaseIterable, Identifiable {
    case normal = "Arbeit"
    case warmup = "Warm-up"
    case drop = "Drop"
    case failure = "Failure"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .normal: "A"
        case .warmup: "W"
        case .drop: "D"
        case .failure: "F"
        }
    }
}

struct WorkoutSession: Codable, Identifiable, Equatable {
    var id: UUID
    var planName: String
    var date: Date
    var notes: String
    var durationMinutes: Double
    var calories: Int
    var exercises: [WorkoutSessionExercise]

    private enum CodingKeys: String, CodingKey {
        case id
        case planName
        case date
        case notes
        case durationMinutes
        case calories
        case exercises
    }

    init(id: UUID, planName: String, date: Date, notes: String, durationMinutes: Double, calories: Int, exercises: [WorkoutSessionExercise]) {
        self.id = id
        self.planName = planName
        self.date = date
        self.notes = notes
        self.durationMinutes = durationMinutes
        self.calories = calories
        self.exercises = exercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        planName = try container.decodeIfPresent(String.self, forKey: .planName) ?? "Training"
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        durationMinutes = try container.decodeIfPresent(Double.self, forKey: .durationMinutes) ?? 0
        calories = try container.decodeIfPresent(Int.self, forKey: .calories) ?? 0
        exercises = try container.decodeIfPresent([WorkoutSessionExercise].self, forKey: .exercises) ?? []
    }

    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.volume }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var endDate: Date { date }

    var startDate: Date {
        date.addingTimeInterval(-durationMinutes * 60)
    }

    var exerciseSummaryText: String {
        exercises.map { exercise in
            let sets = exercise.sets.enumerated().map { index, set in
                "\(index + 1). \(set.reps)x\(set.weight.formattedWeight(unit: .current))"
            }.joined(separator: ", ")
            return "\(exercise.name): \(sets)"
        }.joined(separator: "\n")
    }
}

struct WorkoutSessionExercise: Codable, Identifiable, Equatable {
    var id: UUID
    var catalogID: String
    var name: String
    var category: DeviceCategory
    var notes: String
    var deviceSettings: DeviceSettings
    var sets: [WorkoutSessionSet]

    private enum CodingKeys: String, CodingKey {
        case id
        case catalogID
        case name
        case category
        case notes
        case deviceSettings
        case sets
    }

    init(id: UUID, catalogID: String, name: String, category: DeviceCategory, notes: String, deviceSettings: DeviceSettings = .empty, sets: [WorkoutSessionSet]) {
        self.id = id
        self.catalogID = catalogID
        self.name = name
        self.category = category
        self.notes = notes
        self.deviceSettings = deviceSettings
        self.sets = sets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        catalogID = try container.decodeIfPresent(String.self, forKey: .catalogID) ?? "custom-\(id.uuidString)"
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Übung"
        category = try container.decodeIfPresent(DeviceCategory.self, forKey: .category) ?? .freeWeights
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        deviceSettings = try container.decodeIfPresent(DeviceSettings.self, forKey: .deviceSettings) ?? .empty
        sets = try container.decodeIfPresent([WorkoutSessionSet].self, forKey: .sets) ?? []
    }

    var volume: Double {
        sets.reduce(0) { $0 + Double($1.reps) * $1.weight }
    }

    var maximumWeight: Double? {
        sets.map(\.weight).max()
    }

    var bestSetDescription: String {
        guard let best = sets.max(by: { $0.weight < $1.weight }) else { return "-" }
        return "\(best.reps) x \(best.weight.formattedWeight(unit: .current))"
    }
}

struct WorkoutSessionSet: Codable, Identifiable, Equatable {
    var id: UUID
    var type: WorkoutSetType
    var reps: Int
    var weight: Double
    var rpe: Int?
    var isPersonalRecord: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case reps
        case weight
        case rpe
        case isPersonalRecord
    }

    init(id: UUID, type: WorkoutSetType, reps: Int, weight: Double, rpe: Int?, isPersonalRecord: Bool = false) {
        self.id = id
        self.type = type
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.isPersonalRecord = isPersonalRecord
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        type = try container.decodeIfPresent(WorkoutSetType.self, forKey: .type) ?? .normal
        reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 0
        weight = try container.decodeIfPresent(Double.self, forKey: .weight) ?? 0
        rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
        isPersonalRecord = try container.decodeIfPresent(Bool.self, forKey: .isPersonalRecord) ?? false
    }
}

enum RecordMetric: String, CaseIterable, Identifiable {
    case setVolume = "Satzvolumen"
    case maxWeight = "Höchstes Gewicht"
    case estimatedOneRepMax = "Beste Einzelwiederholung"
    case sessionVolume = "Bestes Sitzungsvolumen"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .setVolume: "chart.bar.fill"
        case .maxWeight: "scalemass.fill"
        case .estimatedOneRepMax: "1.circle.fill"
        case .sessionVolume: "sum"
        }
    }
}

struct ExerciseRecordSummary: Identifiable, Equatable {
    let metric: RecordMetric
    let value: Double?

    var id: String { metric.id }
}

struct ExerciseTrendPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let volume: Double
    let maxWeight: Double
    let bestSetVolume: Double
}

struct PersonalRecordFlags: Equatable {
    var setVolume: Bool = false
    var maxWeight: Bool = false
    var estimatedOneRepMax: Bool = false
    var sessionVolume: Bool = false

    var hasAny: Bool {
        setVolume || maxWeight || estimatedOneRepMax || sessionVolume
    }
}

enum RecordTimeScale: String, CaseIterable, Identifiable {
    case thirtyDays = "30 Tage"
    case ninetyDays = "90 Tage"
    case all = "Alle"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .thirtyDays: 30
        case .ninetyDays: 90
        case .all: nil
        }
    }
}

enum ExerciseCatalogItemKind: Equatable {
    case device
    case exercise
}

struct ExerciseCatalogItem: Identifiable, Equatable {
    let id: String
    let name: String
    let category: DeviceCategory
    let target: String
    let defaultSets: Int
    let defaultReps: Int
    let defaultWeight: Double
    let metValue: Double
    let device: DeviceSettings
    let kind: ExerciseCatalogItemKind
    let isCustom: Bool

    var iconName: String {
        ExerciseCatalog.iconName(for: id, category: category)
    }

    func makeExercise() -> Exercise {
        let startingReps = category == .cardio ? defaultReps : 12

        return Exercise(
            id: UUID(),
            catalogID: id,
            name: name,
            target: target,
            category: category,
            metValue: metValue,
            device: .empty,
            notes: "",
            restSeconds: 90,
            supersetGroup: nil,
            isFavorite: false,
            isCustom: isCustom,
            usesDedicatedDevice: kind == .device,
            sets: (0..<defaultSets).map { _ in
                ExerciseSet(id: UUID(), type: .normal, reps: startingReps, weight: defaultWeight, rpe: nil, isLogged: false)
            }
        )
    }

    func makeImportMappingExercise() -> Exercise {
        var exercise = makeExercise()
        exercise.id = Self.stableUUID(for: id)
        return exercise
    }

    private static func stableUUID(for value: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        for (index, byte) in value.utf8.enumerated() {
            let slot = index % bytes.count
            bytes[slot] = bytes[slot] &* 31 &+ byte
            bytes[(slot + 7) % bytes.count] ^= byte &* 17
        }
        bytes[6] = (bytes[6] & 0x0f) | 0x50
        bytes[8] = (bytes[8] & 0x3f) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5],
            bytes[6], bytes[7],
            bytes[8], bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

extension Double {
    var formattedWeight: String {
        formatted(.number.precision(.fractionLength(0...2)))
    }

    var formattedProgressValue: String {
        if abs(rounded() - self) < 0.05 {
            return "\(Int(rounded()))"
        }

        return formatted(.number.precision(.fractionLength(1)))
    }

    func formattedWeight(unit: WeightUnit) -> String {
        "\(unit.displayValue(fromKilograms: self).formattedWeight) \(unit.symbol)"
    }
}

enum DeviceCategory: String, Codable, CaseIterable, Identifiable {
    case chest = "Brust"
    case back = "Rücken"
    case shoulders = "Schultern"
    case legs = "Beine"
    case arms = "Arme"
    case core = "Core"
    case cardio = "Cardio"
    case freeWeights = "Freie Gewichte"

    var id: String { rawValue }

    static var muscleCategories: [DeviceCategory] {
        [.chest, .back, .shoulders, .legs, .arms, .core, .cardio]
    }

    var iconName: String {
        switch self {
        case .chest: "figure.strengthtraining.traditional"
        case .back: "figure.rower"
        case .shoulders: "figure.arms.open"
        case .legs: "figure.strengthtraining.functional"
        case .arms: "dumbbell"
        case .core: "figure.core.training"
        case .cardio: "figure.run"
        case .freeWeights: "scalemass"
        }
    }
}

struct RoutineTemplate: Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    let catalogIDs: [String]

    static let all: [RoutineTemplate] = [
        RoutineTemplate(
            id: "gympit-routine-import",
            name: "GymPit",
            subtitle: "Routine mit 15 Übungen",
            catalogIDs: [
                "chest-press",
                "incline-press",
                "lat-pulldown",
                "seated-row",
                "shoulder-press",
                "lateral-raise",
                "leg-press",
                "leg-extension",
                "leg-curl",
                "hip-thrust",
                "calf-raise",
                "biceps-curl",
                "triceps-press",
                "ab-crunch",
                "treadmill"
            ]
        ),
        RoutineTemplate(
            id: "push",
            name: "Push",
            subtitle: "Brust, Schultern, Trizeps",
            catalogIDs: ["chest-press", "incline-press", "shoulder-press", "lateral-raise", "triceps-press"]
        ),
        RoutineTemplate(
            id: "pull",
            name: "Pull",
            subtitle: "Rücken, hintere Schulter, Bizeps",
            catalogIDs: ["lat-pulldown", "seated-row", "rear-delt", "assisted-pullup", "biceps-curl"]
        ),
        RoutineTemplate(
            id: "legs",
            name: "Legs",
            subtitle: "Beine und Core",
            catalogIDs: ["leg-press", "leg-extension", "leg-curl", "hip-thrust", "calf-raise", "ab-crunch"]
        ),
        RoutineTemplate(
            id: "full-body",
            name: "Full Body",
            subtitle: "Ganzkörper, effizient",
            catalogIDs: ["leg-press", "chest-press", "lat-pulldown", "shoulder-press", "ab-crunch"]
        ),
        RoutineTemplate(
            id: "upper",
            name: "Upper",
            subtitle: "Oberkörper-Fokus",
            catalogIDs: ["bench-press", "seated-row", "shoulder-press", "lat-pulldown", "triceps-press", "biceps-curl"]
        ),
        RoutineTemplate(
            id: "lower",
            name: "Lower",
            subtitle: "Unterkörper-Fokus",
            catalogIDs: ["squat", "deadlift", "leg-extension", "leg-curl", "calf-raise", "plank"]
        )
    ]
}

enum ExerciseCatalog {
    static let all: [ExerciseCatalogItem] = [
        item("chest-press", "Brustpresse", .chest, "3 x 8-10", 3, 10, 60, 5.0, "Chest Press", "4", "2", "Mittel", "Voll"),
        item("incline-press", "Schrägbrustpresse", .chest, "3 x 8-10", 3, 10, 45, 5.0, "Incline Chest Press", "4", "2", "Mittel", "Kontrolliert"),
        item("pec-deck", "Butterfly / Pec Deck", .chest, "3 x 10-12", 3, 12, 45, 4.5, "Pec Deck", "5", "1", "Neutral", "Voll"),
        item("cable-fly", "Kabelzug Fly", .chest, "3 x 12", 3, 12, 15, 4.5, "Kabelzug", "-", "-", "D-Griffe", "Leicht gebeugt"),
        item("machine-fly", "Machine Fly", .chest, "3 x 10-12", 3, 12, 40, 4.5, "Fly Machine", "4", "2", "Pads", "Voll"),
        item("cable-chest-press", "Kabelzug Brustdrücken", .chest, "3 x 10-12", 3, 12, 20, 5.0, "Kabelzug", "-", "-", "D-Griffe", "Kontrolliert"),
        item("smith-bench-press", "Smith Machine Bankdrücken", .chest, "3 x 8-10", 3, 10, 60, 5.5, "Smith Machine", "Bankposition", "-", "Langhantel", "Bis Brust"),
        item("push-up", "Liegestütze", .chest, "3 x 12", 3, 12, 0, 4.0, "Körpergewicht", "-", "-", "Schulterbreit", "Voll", kind: .exercise),

        item("lat-pulldown", "Latzug", .back, "3 x 8-12", 3, 10, 55, 5.0, "Lat Pulldown", "4", "-", "Breit", "Bis Brust"),
        item("seated-row", "Rudermaschine", .back, "3 x 8-12", 3, 10, 55, 5.0, "Seated Row", "3", "Brustpolster 2", "Eng", "Voll"),
        item("seated-machine-row", "Rudern sitzend (Maschine)", .back, "3 x 8-12", 3, 10, 55, 5.0, "Sitzende Rudermaschine", "3", "Brustpolster 2", "Neutral", "Voll"),
        item("back-extension", "Rückenstrecker", .back, "3 x 12-15", 3, 12, 0, 4.0, "Back Extension", "Hüfte am Pad", "-", "-", "Neutral"),
        item("assisted-pullup", "Assistierte Klimmzüge", .back, "3 x 6-10", 3, 8, 30, 5.5, "Assisted Pull-Up", "Kniepad", "-", "Breit", "Voll"),
        item("low-row", "Low Row Maschine", .back, "3 x 8-12", 3, 10, 55, 5.0, "Low Row", "3", "Brustpolster 2", "Neutral", "Voll"),
        item("t-bar-row-machine", "T-Bar Row Maschine", .back, "3 x 8-10", 3, 10, 50, 5.5, "T-Bar Row", "Brustpolster", "-", "Neutral", "Bis Bauch"),
        item("pullover-machine", "Pullover Maschine", .back, "3 x 10-12", 3, 12, 35, 4.5, "Pullover", "4", "2", "Pad", "Kontrolliert"),
        item("cable-row", "Kabelrudern sitzend", .back, "3 x 8-12", 3, 10, 50, 5.0, "Kabelzug Row", "Bank", "-", "Enggriff", "Voll"),
        item("face-pull", "Face Pull", .back, "3 x 12-15", 3, 12, 20, 4.0, "Kabelzug", "-", "-", "Seil", "Zum Gesicht"),

        item("shoulder-press", "Schulterpresse", .shoulders, "3 x 8-10", 3, 8, 35, 5.0, "Shoulder Press", "5", "1", "Neutral", "Bis Kinnlinie"),
        item("lateral-raise", "Seitheben Maschine", .shoulders, "3 x 12-15", 3, 12, 20, 4.5, "Lateral Raise", "4", "-", "Pads", "Schulterhöhe"),
        item("rear-delt", "Reverse Butterfly", .shoulders, "3 x 12-15", 3, 12, 25, 4.5, "Reverse Pec Deck", "5", "1", "Horizontal", "Kontrolliert"),
        item("cable-lateral-raise", "Seitheben Kabelzug", .shoulders, "3 x 12-15", 3, 12, 10, 4.5, "Kabelzug", "-", "-", "D-Griff", "Schulterhöhe"),
        item("front-raise", "Frontheben", .shoulders, "3 x 10-12", 3, 12, 12.5, 4.0, "Kurzhantel", "-", "-", "Neutral", "Bis Schulterhöhe", kind: .exercise),
        item("shrug-machine", "Shrug Maschine", .shoulders, "3 x 10-12", 3, 12, 60, 4.5, "Shrug Machine", "Stand", "-", "Neutral", "Oben halten"),
        item("arnold-press", "Arnold Press", .shoulders, "3 x 8-10", 3, 10, 17.5, 5.0, "Kurzhantel", "Bank", "80 Grad", "Neutral", "Kontrolliert", kind: .exercise),

        item("leg-press", "Beinpresse", .legs, "4 x 8-12", 4, 10, 120, 5.5, "Leg Press", "6", "2", "Füße mittig", "Tief kontrolliert"),
        item("leg-extension", "Beinstrecker", .legs, "3 x 10-12", 3, 12, 45, 5.0, "Leg Extension", "4", "2", "Pad am Spann", "Oben halten"),
        item("leg-curl", "Beinbeuger", .legs, "3 x 10-12", 3, 12, 40, 5.0, "Leg Curl", "4", "2", "Pad Achillessehne", "Voll"),
        item("hip-thrust", "Hip Thrust Maschine", .legs, "3 x 8-12", 3, 10, 70, 5.5, "Hip Thrust", "Gurt eng", "-", "Füße stabil", "Oben halten"),
        item("abductor", "Abduktor", .legs, "3 x 12-15", 3, 15, 45, 4.0, "Abductor", "5", "2", "Pads", "Kontrolliert"),
        item("adductor", "Adduktor", .legs, "3 x 12-15", 3, 15, 45, 4.0, "Adductor", "5", "2", "Pads", "Kontrolliert"),
        item("calf-raise", "Wadenheben", .legs, "4 x 10-15", 4, 12, 50, 4.5, "Calf Raise", "Schulterpads", "-", "Fussballen", "Voll"),
        item("hack-squat", "Hack Squat", .legs, "4 x 8-12", 4, 10, 100, 5.5, "Hack Squat", "Rückenpad", "-", "Füße mittig", "Tief"),
        item("smith-squat", "Smith Machine Kniebeuge", .legs, "3 x 8-10", 3, 10, 70, 5.5, "Smith Machine", "Stand", "-", "Langhantel", "Kontrolliert"),
        item("glute-kickback", "Glute Kickback Maschine", .legs, "3 x 12 je Seite", 3, 12, 30, 4.5, "Glute Kickback", "Brustpolster", "-", "Fussplatte", "Oben halten"),
        item("seated-calf-raise", "Wadenheben sitzend", .legs, "4 x 12-15", 4, 12, 40, 4.0, "Seated Calf Raise", "Kniepolster", "-", "Fussballen", "Voll"),
        item("standing-calf-raise", "Wadenheben stehend", .legs, "4 x 10-15", 4, 12, 60, 4.5, "Standing Calf Raise", "Schulterpads", "-", "Fussballen", "Voll"),

        item("biceps-curl", "Bizepscurl Maschine", .arms, "3 x 10-12", 3, 12, 25, 4.0, "Biceps Curl", "4", "Pad 2", "Untergriff", "Voll"),
        item("triceps-press", "Trizepsdrücken", .arms, "3 x 10-12", 3, 12, 35, 4.0, "Kabelzug", "-", "-", "Seil", "Ellbogen fix"),
        item("dip-machine", "Dip Maschine", .arms, "3 x 8-12", 3, 10, 45, 5.0, "Dip Machine", "4", "-", "Neutral", "Kontrolliert"),
        item("preacher-curl", "Scottcurl Maschine", .arms, "3 x 10-12", 3, 12, 25, 4.0, "Preacher Curl", "Sitz 4", "Pad 2", "Untergriff", "Voll"),
        item("hammer-curl", "Hammercurl", .arms, "3 x 10-12", 3, 12, 15, 4.0, "Kurzhantel", "-", "-", "Neutral", "Voll", kind: .exercise),
        item("cable-curl", "Kabelcurl", .arms, "3 x 10-12", 3, 12, 25, 4.0, "Kabelzug", "-", "-", "Stange", "Voll"),
        item("overhead-triceps", "Trizeps über Kopf", .arms, "3 x 10-12", 3, 12, 22.5, 4.0, "Kabelzug", "-", "-", "Seil", "Voll"),
        item("skull-crusher", "Skull Crusher", .arms, "3 x 8-10", 3, 10, 25, 4.0, "SZ-Stange", "Bank", "-", "Eng", "Kontrolliert", kind: .exercise),

        item("ab-crunch", "Bauchmaschine", .core, "3 x 12-15", 3, 15, 35, 4.0, "Ab Crunch", "4", "2", "Griffe", "Einrollen"),
        item("crunch-press", "Crunch / Bauchpresse", .core, "3 x 12-15", 3, 15, 35, 4.0, "Bauchpresse", "4", "2", "Griffe", "Einrollen"),
        item("rotary-torso", "Rumpfrotation", .core, "3 x 12 je Seite", 3, 12, 25, 4.0, "Rotary Torso", "3", "1", "Griffe", "Kontrolliert"),
        item("plank", "Plank", .core, "3 x 45 s", 3, 45, 0, 3.5, "Matte", "-", "-", "-", "Stabil", kind: .exercise),
        item("cable-crunch", "Cable Crunch", .core, "3 x 12-15", 3, 15, 35, 4.0, "Kabelzug", "-", "-", "Seil", "Einrollen"),
        item("hanging-leg-raise", "Hanging Leg Raise", .core, "3 x 10-15", 3, 12, 0, 4.5, "Captain Chair", "-", "-", "Unterarm Pads", "Kontrolliert"),
        item("roman-chair", "Roman Chair Sit-Up", .core, "3 x 10-12", 3, 12, 0, 4.0, "Roman Chair", "Hüftpad", "-", "-", "Kontrolliert"),
        item("pallof-press", "Pallof Press", .core, "3 x 12 je Seite", 3, 12, 15, 3.5, "Kabelzug", "-", "-", "D-Griff", "Antirotation"),

        item("treadmill", "Laufband", .cardio, "1 x 20 min", 1, 20, 0, 8.0, "Treadmill", "-", "-", "-", "Tempo frei"),
        item("bike", "Ergometer", .cardio, "1 x 20 min", 1, 20, 0, 6.8, "Bike", "Sattelhöhe", "-", "-", "Rund treten"),
        item("cross-trainer", "Crosstrainer", .cardio, "1 x 20 min", 1, 20, 0, 6.0, "Elliptical", "Schrittlänge", "-", "Griffe", "Gleichmäßig"),
        item("rowing", "Ruderergometer", .cardio, "1 x 10 min", 1, 10, 0, 7.0, "Row Erg", "Dampfer 5", "-", "Griff", "Sauber"),
        item("stairmaster", "Stairmaster", .cardio, "1 x 15 min", 1, 15, 0, 8.8, "Stair Climber", "-", "-", "Griffe locker", "Level frei"),
        item("skierg", "SkiErg", .cardio, "1 x 10 min", 1, 10, 0, 7.5, "SkiErg", "Dampfer 5", "-", "Griffe", "Rhythmisch"),
        item("air-bike", "Air Bike", .cardio, "1 x 12 min", 1, 12, 0, 8.0, "Air Bike", "Sattel", "-", "Griffe", "Gleichmäßig"),

        item("bench-press", "Bankdrücken", .freeWeights, "3 x 5-8", 3, 8, 60, 6.0, "Langhantel", "Bank flach", "-", "Breit", "Brust berühren", kind: .exercise),
        item("squat", "Kniebeuge", .freeWeights, "3 x 5-8", 3, 8, 80, 6.0, "Rack", "J-Hooks", "Safety Bars", "Langhantel", "Tief stabil", kind: .exercise),
        item("deadlift", "Kreuzheben", .freeWeights, "3 x 5", 3, 5, 90, 6.0, "Plattform", "-", "-", "Langhantel", "Neutral", kind: .exercise),
        item("dumbbell-row", "Kurzhantelrudern", .freeWeights, "3 x 10 je Seite", 3, 10, 25, 5.0, "Kurzhantel", "Bank", "-", "Neutral", "Voll", kind: .exercise),
        item("romanian-deadlift", "Rumänisches Kreuzheben", .freeWeights, "3 x 8-10", 3, 10, 70, 5.5, "Langhantel", "-", "-", "Obergriff", "Bis Dehnung", kind: .exercise),
        item("goblet-squat", "Goblet Squat", .freeWeights, "3 x 10-12", 3, 12, 25, 5.0, "Kettlebell", "-", "-", "Vor Brust", "Tief", kind: .exercise),
        item("walking-lunge", "Ausfallschritte gehend", .freeWeights, "3 x 12 je Seite", 3, 12, 20, 5.5, "Kurzhantel", "-", "-", "Neutral", "Kontrolliert", kind: .exercise),
        item("dumbbell-bench-press", "Kurzhantel Bankdrücken", .freeWeights, "3 x 8-10", 3, 10, 25, 5.5, "Kurzhantel", "Bank flach", "-", "Neutral", "Voll", kind: .exercise)
    ]

    static func item(for id: String) -> ExerciseCatalogItem? {
        all.first { $0.id == id }
    }

    static func iconName(for id: String, category: DeviceCategory) -> String {
        "exercise.\(id)"
    }

    static func muscleWeights(for id: String, fallback: DeviceCategory) -> [DeviceCategory: Double] {
        switch id {
        case "chest-press", "incline-press", "cable-chest-press", "smith-bench-press", "bench-press", "dumbbell-bench-press":
            [.chest: 0.70, .arms: 0.20, .shoulders: 0.10]
        case "pec-deck", "cable-fly", "machine-fly":
            [.chest: 0.90, .shoulders: 0.10]
        case "push-up":
            [.chest: 0.65, .arms: 0.20, .shoulders: 0.10, .core: 0.05]

        case "lat-pulldown", "assisted-pullup", "pullover-machine":
            [.back: 0.75, .arms: 0.25]
        case "seated-row", "seated-machine-row", "low-row", "t-bar-row-machine", "cable-row":
            [.back: 0.75, .arms: 0.20, .shoulders: 0.05]
        case "dumbbell-row":
            [.back: 0.75, .arms: 0.20, .core: 0.05]
        case "back-extension":
            [.back: 0.55, .legs: 0.35, .core: 0.10]
        case "face-pull":
            [.shoulders: 0.65, .back: 0.25, .arms: 0.10]

        case "shoulder-press", "arnold-press":
            [.shoulders: 0.70, .arms: 0.20, .chest: 0.10]
        case "lateral-raise", "rear-delt", "cable-lateral-raise", "front-raise", "shrug-machine":
            [.shoulders: 0.85, .back: 0.10, .arms: 0.05]

        case "leg-press", "leg-extension", "leg-curl", "hip-thrust", "abductor", "adductor", "calf-raise", "hack-squat", "smith-squat", "glute-kickback", "seated-calf-raise", "standing-calf-raise":
            [.legs: 1.0]
        case "squat":
            [.legs: 0.85, .core: 0.10, .back: 0.05]
        case "deadlift":
            [.legs: 0.50, .back: 0.35, .core: 0.10, .arms: 0.05]
        case "romanian-deadlift":
            [.legs: 0.65, .back: 0.25, .core: 0.10]
        case "goblet-squat":
            [.legs: 0.80, .core: 0.15, .back: 0.05]
        case "walking-lunge":
            [.legs: 0.90, .core: 0.10]

        case "biceps-curl", "triceps-press", "preacher-curl", "hammer-curl", "cable-curl", "overhead-triceps", "skull-crusher":
            [.arms: 1.0]
        case "dip-machine":
            [.arms: 0.60, .chest: 0.30, .shoulders: 0.10]

        case "ab-crunch", "crunch-press", "rotary-torso", "plank", "cable-crunch", "roman-chair":
            [.core: 1.0]
        case "hanging-leg-raise":
            [.core: 0.85, .legs: 0.15]
        case "pallof-press":
            [.core: 0.90, .shoulders: 0.10]

        case "treadmill", "bike", "cross-trainer":
            [.cardio: 1.0]
        case "rowing":
            [.cardio: 0.70, .back: 0.15, .legs: 0.10, .arms: 0.05]
        case "stairmaster":
            [.cardio: 0.70, .legs: 0.30]
        case "skierg":
            [.cardio: 0.75, .back: 0.15, .arms: 0.10]
        case "air-bike":
            [.cardio: 0.75, .legs: 0.15, .arms: 0.10]

        default:
            [fallback: 1.0]
        }
    }

    private static func item(
        _ id: String,
        _ name: String,
        _ category: DeviceCategory,
        _ target: String,
        _ defaultSets: Int,
        _ defaultReps: Int,
        _ defaultWeight: Double,
        _ metValue: Double,
        _ machineName: String,
        _ seat: String,
        _ backrest: String,
        _ handle: String,
        _ range: String,
        kind: ExerciseCatalogItemKind = .device
    ) -> ExerciseCatalogItem {
        ExerciseCatalogItem(
            id: id,
            name: name,
            category: category,
            target: target,
            defaultSets: defaultSets,
            defaultReps: defaultReps,
            defaultWeight: defaultWeight,
            metValue: metValue,
            device: DeviceSettings(
                machineName: machineName,
                seat: seat,
                backrest: backrest,
                handle: handle,
                range: range,
                notes: ""
            ),
            kind: kind,
            isCustom: false
        )
    }
}

extension WorkoutPlan {
    static let sample = WorkoutPlan(
        id: UUID(),
        name: "GymPit",
        profile: UserProfile(
            bodyWeightKilograms: 80,
            minutesPerSet: 3.5,
            setupMinutesPerExercise: 2,
            defaultRestSeconds: 90
        ),
        workoutNotes: "",
        exercises: RoutineTemplate.all.first { $0.id == "gympit-routine-import" }!.catalogIDs.compactMap {
            ExerciseCatalog.item(for: $0)?.makeExercise()
        },
        currentExerciseID: nil,
        completedExerciseIDs: [],
        isCompletedSectionExpanded: false,
        archivedSessionID: nil,
        isWorkoutStarted: false
    )
}
