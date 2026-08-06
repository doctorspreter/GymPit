import Foundation

/// Wohin GymPit sendet: direkt an Home Assistant, abgesichert ueber einen
/// Long-Lived Access Token. Home Assistant erkennt am Token, welchem Benutzer
/// die Trainings gehoeren.
enum HealthpitAPI {
    static let prefix = "api/healthpit/v1"
    static let defaultPort = "8123"

    static func path(_ path: String) -> String {
        "\(prefix)/\(path)"
    }

    /// Authentifizierter Endpunkt zum Pruefen der Erreichbarkeit.
    static var probePath: String { path("status") }
}

enum GymPitBridgeSettings {
    /// Long-Lived Access Token aus dem Home-Assistant-Profil. Er ist die
    /// gesamte Anmeldung.
    static let homeAssistantTokenKey = "gymPitBridgeHomeAssistantToken"
    static let baseURLKey = "gymPitBridgeBaseURL"
    static let localConnectionEnabledKey = "gymPitBridgeLocalConnectionEnabled"
    static let localHostKey = "gymPitBridgeLocalHost"
    static let localPortKey = "gymPitBridgeLocalPort"
    static let deviceIDKey = "gymPitBridgeDeviceID"
}

/// Was nach dem Verbinden feststeht. Home Assistant stellt keine Sitzung aus —
/// der Long-Lived Token ist die Anmeldung und laeuft nicht ab. Festgehalten
/// wird nur, zu welchem Home-Assistant-Benutzer der Token gehoert; an ihm
/// haengen drueben die Entitaeten.
struct GymPitBridgeSession {
    let deviceName: String
    let username: String

    init(username: String) {
        deviceName = "GymPit (iPhone)"
        self.username = username
    }
}

struct GymPitBridgeImportedWorkoutBatchPayload: Encodable {
    let deviceID: String
    let workouts: [GymPitBridgeImportedWorkoutPayload]

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case workouts
    }
}

private struct GymPitBridgeWorkoutReconcilePayload: Encodable {
    let deviceID: String
    let source: String
    let workoutIDs: [String]

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case source
        case workoutIDs = "workout_ids"
    }
}

struct GymPitBridgeImportedWorkoutPayload: Encodable {
    let id: String
    let source: String
    let sport: String
    let title: String
    let start: Date
    let end: Date
    let durationMinutes: Double
    let distanceKm: Double?
    let energyKcal: Double?
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let notes: String
    let exercises: [GymPitBridgeImportedExercisePayload]
    let route: [GymPitBridgeRoutePointPayload]

    enum CodingKeys: String, CodingKey {
        case id, source, sport, title, start, end, notes, exercises, route
        case durationMinutes = "duration_minutes"
        case distanceKm = "distance_km"
        case energyKcal = "energy_kcal"
        case averageHeartRate = "average_heart_rate"
        case maxHeartRate = "max_heart_rate"
    }
}

struct GymPitBridgeImportedExercisePayload: Encodable {
    let id: String
    let catalogID: String
    let name: String
    let category: String
    let notes: String
    let deviceSettings: GymPitBridgeDeviceSettingsPayload
    let sets: [GymPitBridgeImportedSetPayload]

    enum CodingKeys: String, CodingKey {
        case id, name, category, notes, sets
        case catalogID = "catalog_id"
        case deviceSettings = "device_settings"
    }
}

struct GymPitBridgeDeviceSettingsPayload: Encodable {
    let machineName: String
    let seat: String
    let backrest: String
    let handle: String
    let range: String
    let notes: String

    enum CodingKeys: String, CodingKey {
        case machineName = "machine_name"
        case seat
        case backrest
        case handle
        case range
        case notes
    }
}

struct GymPitBridgeImportedSetPayload: Encodable {
    let id: String
    let index: Int
    let type: String
    let reps: Int
    let weightKg: Double
    let rpe: Int?
    let isPersonalRecord: Bool

    enum CodingKeys: String, CodingKey {
        case id, index, type, reps, rpe
        case weightKg = "weight_kg"
        case isPersonalRecord = "is_personal_record"
    }
}

struct GymPitBridgeRoutePointPayload: Encodable {
    let latitude: Double
    let longitude: Double
    let elevation: Double?
    let timestamp: Date?
    let heartRate: Double?

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, elevation, timestamp
        case heartRate = "heart_rate"
    }
}

struct GymPitBridgeUploadSummary: Equatable {
    var uploaded: Int = 0
    var created: Int = 0
    var updated: Int = 0
    var exercises: Int = 0
    var sets: Int = 0
    var volumeKg: Double = 0

    mutating func add(_ other: GymPitBridgeUploadSummary) {
        uploaded += other.uploaded
        created += other.created
        updated += other.updated
        exercises += other.exercises
        sets += other.sets
        volumeKg += other.volumeKg
    }
}

private struct GymPitBridgeImportResponse: Decodable {
    let workouts: [GymPitBridgeWorkoutImportResult]?
    let results: [GymPitBridgeWorkoutImportResult]?
    let created: Int?
    let updated: Int?
    let exerciseCount: Int?
    let setCount: Int?
    let totalVolumeKg: Double?

    enum CodingKeys: String, CodingKey {
        case workouts
        case results
        case created
        case updated
        case exerciseCount = "exercise_count"
        case exercisesCount = "exercises_count"
        case exercises
        case setCount = "set_count"
        case setsCount = "sets_count"
        case sets
        case totalVolumeKg = "total_volume_kg"
        case volumeKg = "volume_kg"
        case volume
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        workouts = try container.decodeIfPresent([GymPitBridgeWorkoutImportResult].self, forKey: .workouts)
        results = try container.decodeIfPresent([GymPitBridgeWorkoutImportResult].self, forKey: .results)
        created = try container.decodeIfPresent(Int.self, forKey: .created)
        updated = try container.decodeIfPresent(Int.self, forKey: .updated)
        exerciseCount = try container.decodeFirstInt(for: [.exerciseCount, .exercisesCount, .exercises])
        setCount = try container.decodeFirstInt(for: [.setCount, .setsCount, .sets])
        totalVolumeKg = try container.decodeFirstDouble(for: [.totalVolumeKg, .volumeKg, .volume])
    }
}

private struct GymPitBridgeWorkoutImportResult: Decodable {
    let status: String?
    let exerciseCount: Int?
    let setCount: Int?
    let totalVolumeKg: Double?

    enum CodingKeys: String, CodingKey {
        case status
        case action
        case exerciseCount = "exercise_count"
        case exercisesCount = "exercises_count"
        case exercises
        case setCount = "set_count"
        case setsCount = "sets_count"
        case sets
        case totalVolumeKg = "total_volume_kg"
        case volumeKg = "volume_kg"
        case volume
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusValue = try container.decodeIfPresent(String.self, forKey: .status)
        let actionValue = try container.decodeIfPresent(String.self, forKey: .action)
        status = statusValue ?? actionValue
        exerciseCount = try container.decodeFirstInt(for: [.exerciseCount, .exercisesCount, .exercises])
        setCount = try container.decodeFirstInt(for: [.setCount, .setsCount, .sets])
        totalVolumeKg = try container.decodeFirstDouble(for: [.totalVolumeKg, .volumeKg, .volume])
    }
}

private extension KeyedDecodingContainer {
    func decodeFirstInt(for keys: [Key]) throws -> Int? {
        for key in keys {
            if let value = try? decodeIfPresent(Int.self, forKey: key) {
                return value
            }
            if let value = try? decodeIfPresent(Double.self, forKey: key) {
                return Int(value.rounded())
            }
        }
        return nil
    }

    func decodeFirstDouble(for keys: [Key]) throws -> Double? {
        for key in keys {
            if let value = try? decodeIfPresent(Double.self, forKey: key) {
                return value
            }
            if let value = try? decodeIfPresent(Int.self, forKey: key) {
                return Double(value)
            }
        }
        return nil
    }
}

private extension GymPitBridgeWorkoutImportResult {
    var normalizedStatus: String {
        status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    }
}

private struct GymPitBridgeCredentials {
    let baseURL: URL
    let authToken: String
    let deviceID: String

    /// Pfad inklusive des Präfixes der Integration.
    func apiPath(_ path: String) -> String {
        HealthpitAPI.path(path)
    }
}

enum GymPitBridgeSyncError: LocalizedError {
    case missingURL
    case missingToken
    case invalidURL
    case serverRejected(Int)
    case serverMessage(String)

    var errorDescription: String? {
        let language = AppLanguage.current
        switch self {
        case .missingURL:
            return language.ui("Healthpit-Adresse fehlt.")
        case .missingToken:
            return language.ui("Healthpit-Token fehlt.")
        case .invalidURL:
            return language.ui("Healthpit-Adresse ist ungültig.")
        case .serverRejected(let code):
            return language.ui(format: "Healthpit hat die Übertragung abgelehnt (%d).", code)
        case .serverMessage(let message):
            // Bereits uebersetzt, wo die Meldung entsteht.
            return message
        }
    }
}

final class GymPitBridgeSyncService {
    static let shared = GymPitBridgeSyncService()

    private let defaults = UserDefaults.standard
    private let encoder: JSONEncoder
    private let decoder = JSONDecoder()

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let storedDeviceID = defaults.string(forKey: GymPitBridgeSettings.deviceIDKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let legacyDeviceIDs = ["GymPitApp", "Health" + "pit"]
        if storedDeviceID?.isEmpty != false || legacyDeviceIDs.contains(storedDeviceID ?? "") {
            defaults.set("GymPit", forKey: GymPitBridgeSettings.deviceIDKey)
        }
        if defaults.string(forKey: GymPitBridgeSettings.localPortKey)?.isEmpty != false {
            defaults.set(HealthpitAPI.defaultPort, forKey: GymPitBridgeSettings.localPortKey)
        }
    }

    var hasSession: Bool {
        !Self.trimmedKeychainValue(for: GymPitBridgeSettings.homeAssistantTokenKey).isEmpty
    }

    /// Verbindet mit Home Assistant. Der Long-Lived Token *ist* die Anmeldung;
    /// geprueft wird er einmal gegen den Statusendpunkt der Integration.
    @discardableResult
    func connect() async throws -> GymPitBridgeSession {
        let token = Self.trimmedKeychainValue(for: GymPitBridgeSettings.homeAssistantTokenKey)
        guard !token.isEmpty else { throw GymPitBridgeSyncError.missingToken }

        let baseURL = try await Self.configuredBaseURL(defaults: defaults)
        var endpoint = baseURL
        endpoint.append(path: HealthpitAPI.probePath)

        var request = URLRequest(url: endpoint)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(statusCode) else {
            if statusCode == 401 || statusCode == 403 {
                throw GymPitBridgeSyncError.serverMessage(AppLanguage.current.ui(
                    "Home Assistant hat den Token abgelehnt. Bitte einen neuen Long-Lived Access Token eintragen."
                ))
            }
            if statusCode == 404 {
                throw GymPitBridgeSyncError.serverMessage(AppLanguage.current.ui(
                    "Home Assistant antwortet, aber die Healthpit-Integration ist dort nicht eingerichtet."
                ))
            }
            if let message = Self.bridgeErrorMessage(from: data, statusCode: statusCode) {
                throw GymPitBridgeSyncError.serverMessage(message)
            }
            throw GymPitBridgeSyncError.serverRejected(statusCode)
        }

        let status = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        return GymPitBridgeSession(username: status?["user"] as? String ?? "")
    }

    func disconnect() {
        GymPitBridgeKeychainStore.delete(GymPitBridgeSettings.homeAssistantTokenKey)
    }

    @discardableResult
    func upload(_ session: WorkoutSession) async throws -> GymPitBridgeUploadSummary {
        try await upload([session])
    }

    @discardableResult
    func upload(_ sessions: [WorkoutSession]) async throws -> GymPitBridgeUploadSummary {
        let credentials = try await bridgeCredentials()
        guard !sessions.isEmpty else { return GymPitBridgeUploadSummary() }
        var summary = GymPitBridgeUploadSummary()
        let batchSize = 25

        for startIndex in stride(from: 0, to: sessions.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, sessions.count)
            let sessionsBatch = Array(sessions[startIndex..<endIndex])
            let payloadBatch = sessionsBatch.map(GymPitBridgeImportedWorkoutPayload.init)
            let batchSummary = try await uploadBatch(payloadBatch, credentials: credentials)
            summary.add(batchSummary)
        }

        return summary
    }

    @discardableResult
    func uploadAndReconcile(_ sessions: [WorkoutSession]) async throws -> GymPitBridgeUploadSummary {
        let credentials = try await bridgeCredentials()
        var summary = GymPitBridgeUploadSummary()
        let batchSize = 25

        for startIndex in stride(from: 0, to: sessions.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, sessions.count)
            let payloadBatch = sessions[startIndex..<endIndex].map(GymPitBridgeImportedWorkoutPayload.init)
            summary.add(try await uploadBatch(payloadBatch, credentials: credentials))
        }

        try await reconcile(
            workoutIDs: sessions.map { $0.id.uuidString },
            credentials: credentials
        )
        return summary
    }

    func delete(workoutID: UUID) async throws {
        let credentials = try await bridgeCredentials()
        var endpoint = credentials.baseURL
        endpoint.append(path: credentials.apiPath("workouts/imports/\(workoutID.uuidString)"))
        endpoint.append(queryItems: [
            URLQueryItem(name: "device_id", value: credentials.deviceID),
            URLQueryItem(name: "source", value: "gympit"),
        ])

        let request = authorizedRequest(url: endpoint, method: "DELETE", credentials: credentials)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data, credentials: credentials)
    }

    private func uploadBatch(
        _ workouts: [GymPitBridgeImportedWorkoutPayload],
        credentials: GymPitBridgeCredentials
    ) async throws -> GymPitBridgeUploadSummary {
        var endpoint = credentials.baseURL
        endpoint.append(path: credentials.apiPath("workouts/imports"))

        let payload = GymPitBridgeImportedWorkoutBatchPayload(
            deviceID: credentials.deviceID,
            workouts: workouts
        )
        var request = authorizedRequest(url: endpoint, method: "POST", credentials: credentials)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data, credentials: credentials)

        return uploadSummary(from: data, fallbackWorkouts: workouts)
    }

    private func reconcile(
        workoutIDs: [String],
        credentials: GymPitBridgeCredentials
    ) async throws {
        var endpoint = credentials.baseURL
        endpoint.append(path: credentials.apiPath("workouts/imports/reconcile"))

        let payload = GymPitBridgeWorkoutReconcilePayload(
            deviceID: credentials.deviceID,
            source: "gympit",
            workoutIDs: workoutIDs
        )
        var request = authorizedRequest(url: endpoint, method: "POST", credentials: credentials)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data, credentials: credentials)
    }

    private func validate(
        response: URLResponse,
        data: Data,
        credentials: GymPitBridgeCredentials
    ) throws {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(statusCode) else {
            if statusCode == 401 || statusCode == 403 {
                // Der Token wurde in Home Assistant widerrufen oder ist falsch.
                throw GymPitBridgeSyncError.serverMessage(AppLanguage.current.ui(
                    "Home Assistant hat den Token abgelehnt. Bitte einen neuen Long-Lived Access Token eintragen."
                ))
            }
            if let message = Self.bridgeErrorMessage(from: data, statusCode: statusCode) {
                throw GymPitBridgeSyncError.serverMessage(message)
            }
            throw GymPitBridgeSyncError.serverRejected(statusCode)
        }
    }

    private func uploadSummary(
        from data: Data,
        fallbackWorkouts workouts: [GymPitBridgeImportedWorkoutPayload]
    ) -> GymPitBridgeUploadSummary {
        let fallback = GymPitBridgeUploadSummary(
            uploaded: workouts.count,
            created: 0,
            updated: 0,
            exercises: workouts.reduce(0) { $0 + $1.exercises.count },
            sets: workouts.reduce(0) { total, workout in
                total + workout.exercises.reduce(0) { $0 + $1.sets.count }
            },
            volumeKg: workouts.reduce(0) { total, workout in
                total + workout.exercises.reduce(0) { exerciseTotal, exercise in
                    exerciseTotal + exercise.sets.reduce(0) { $0 + Double($1.reps) * $1.weightKg }
                }
            }
        )

        guard !data.isEmpty,
              let response = try? decoder.decode(GymPitBridgeImportResponse.self, from: data) else {
            return fallback
        }

        let workoutResults = response.workouts ?? response.results ?? []
        let created = response.created ?? workoutResults.filter { $0.normalizedStatus == "created" }.count
        let updated = response.updated ?? workoutResults.filter { $0.normalizedStatus == "updated" }.count
        let exercises = response.exerciseCount ?? workoutResults.compactMap(\.exerciseCount).reduce(0, +)
        let sets = response.setCount ?? workoutResults.compactMap(\.setCount).reduce(0, +)
        let volumeKg = response.totalVolumeKg ?? workoutResults.compactMap(\.totalVolumeKg).reduce(0, +)

        return GymPitBridgeUploadSummary(
            uploaded: max(workouts.count, created + updated),
            created: created,
            updated: updated,
            exercises: exercises == 0 ? fallback.exercises : exercises,
            sets: sets == 0 ? fallback.sets : sets,
            volumeKg: volumeKg == 0 ? fallback.volumeKg : volumeKg
        )
    }

    private func bridgeCredentials() async throws -> GymPitBridgeCredentials {
        let token = Self.trimmedKeychainValue(for: GymPitBridgeSettings.homeAssistantTokenKey)
        let deviceID = defaults.string(forKey: GymPitBridgeSettings.deviceIDKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "GymPit"

        guard !token.isEmpty else {
            throw GymPitBridgeSyncError.serverMessage(AppLanguage.current.ui(
                "GymPit ist nicht verbunden. Bitte zuerst den Home-Assistant-Token eintragen."
            ))
        }

        let baseURL = try await Self.configuredBaseURL(defaults: defaults)
        // Kein Benutzername mehr: Home Assistant leitet ihn aus dem Token ab.
        return GymPitBridgeCredentials(
            baseURL: baseURL,
            authToken: token,
            deviceID: deviceID.isEmpty ? "GymPit" : deviceID
        )
    }

    static func configuredBaseURL(defaults: UserDefaults = .standard) async throws -> URL {
        let localHost = defaults.string(forKey: GymPitBridgeSettings.localHostKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let localPort = defaults.string(forKey: GymPitBridgeSettings.localPortKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? HealthpitAPI.defaultPort

        if !localHost.isEmpty {
            let localURL = try localBaseURL(host: localHost, port: localPort)
            if await isBridgeReachable(at: localURL) {
                return localURL
            }
        }

        return try externalBaseURL(defaults: defaults)
    }

    private static func externalBaseURL(defaults: UserDefaults) throws -> URL {
        let baseURLText = defaults.string(forKey: GymPitBridgeSettings.baseURLKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !baseURLText.isEmpty else { throw GymPitBridgeSyncError.missingURL }
        guard let baseURL = URL(string: baseURLText) else { throw GymPitBridgeSyncError.invalidURL }
        guard baseURL.scheme?.lowercased() == "https" else {
            throw GymPitBridgeSyncError.serverMessage(
                AppLanguage.current.ui("Bitte die externe Healthpit-Adresse mit https:// eintragen.")
            )
        }
        return baseURL
    }

    private static func localBaseURL(host: String, port: String) throws -> URL {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPort = port.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? HealthpitAPI.defaultPort
            : port.trimmingCharacters(in: .whitespacesAndNewlines)

        let localText: String
        if trimmedHost.contains("://") {
            guard var components = URLComponents(string: trimmedHost) else {
                throw GymPitBridgeSyncError.invalidURL
            }
            components.scheme = "http"
            if components.port == nil {
                components.port = Int(normalizedPort)
            }
            components.path = components.path == "/" ? "" : components.path
            guard let normalized = components.url?.absoluteString else {
                throw GymPitBridgeSyncError.invalidURL
            }
            localText = normalized
        } else if trimmedHost.contains(":") {
            localText = "http://\(trimmedHost)"
        } else {
            localText = "http://\(trimmedHost):\(normalizedPort)"
        }

        guard let localURL = URL(string: localText),
              localURL.scheme?.lowercased() == "http" else {
            throw GymPitBridgeSyncError.invalidURL
        }
        return localURL
    }

    private static func isBridgeReachable(at baseURL: URL) async -> Bool {
        var endpoint = baseURL
        endpoint.append(path: HealthpitAPI.probePath)

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 1.2
        // Der Statusendpunkt ist authentifiziert, ein Probelauf ohne Token
        // waere also immer 401.
        let token = trimmedKeychainValue(for: GymPitBridgeSettings.homeAssistantTokenKey)
        guard !token.isEmpty else { return false }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(statusCode),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }
            // Keine Rollenpruefung mehr: der Statusendpunkt der Integration
            // meldet keine Master/Slave-Rolle, es gibt keine zweite Instanz.
            return object["status"] as? String == "ok"
        } catch {
            return false
        }
    }

    private func authorizedRequest(
        url: URL,
        method: String,
        credentials: GymPitBridgeCredentials
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(credentials.authToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private static func bridgeErrorMessage(from data: Data, statusCode: Int) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        // Die Integration nennt den Grund "error", aeltere Gegenstellen "detail".
        let detail = (object["detail"] as? String) ?? (object["error"] as? String) ?? ""
        guard !detail.isEmpty else { return nil }
        return AppLanguage.current.ui(format: "Healthpit hat abgelehnt (%d): %@", statusCode, detail)
    }

    private static func trimmedKeychainValue(for key: String) -> String {
        GymPitBridgeKeychainStore.string(for: key)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

}

private extension GymPitBridgeImportedWorkoutPayload {
    init(session: WorkoutSession) {
        id = session.id.uuidString
        source = "GymPit"
        sport = "strength_training"
        title = session.planName
        start = session.startDate
        end = session.endDate
        durationMinutes = session.durationMinutes
        distanceKm = nil
        energyKcal = session.calories > 0 ? Double(session.calories) : nil
        averageHeartRate = nil
        maxHeartRate = nil
        notes = session.notes
        exercises = session.exercises.map(GymPitBridgeImportedExercisePayload.init)
        route = []
    }
}

private extension GymPitBridgeImportedExercisePayload {
    init(exercise: WorkoutSessionExercise) {
        id = exercise.id.uuidString
        catalogID = exercise.catalogID
        name = exercise.name
        category = exercise.category.rawValue
        notes = exercise.notes
        deviceSettings = GymPitBridgeDeviceSettingsPayload(settings: exercise.deviceSettings)
        sets = exercise.sets.enumerated().map { index, set in
            GymPitBridgeImportedSetPayload(index: index + 1, set: set)
        }
    }
}

private extension GymPitBridgeImportedSetPayload {
    init(index: Int, set: WorkoutSessionSet) {
        id = set.id.uuidString
        self.index = index
        type = set.type.rawValue
        reps = set.reps
        weightKg = set.weight
        rpe = set.rpe
        isPersonalRecord = set.isPersonalRecord
    }
}

private extension GymPitBridgeDeviceSettingsPayload {
    init(settings: DeviceSettings) {
        machineName = settings.machineName
        seat = settings.seat
        backrest = settings.backrest
        handle = settings.handle
        range = settings.range
        notes = settings.notes
    }
}
