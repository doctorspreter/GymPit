import Foundation

/// The destination GymPit sends to: Home Assistant directly, authenticated by a
/// long-lived access token. Home Assistant derives the workout owner from it.
enum HealthpitAPI {
    static let prefix = "api/healthpit/v1"
    static let defaultPort = "8123"

    static func path(_ path: String) -> String {
        "\(prefix)/\(path)"
    }

    /// Authenticated endpoint used to verify reachability.
    static var probePath: String { path("status") }
}

enum GymPitBridgeSettings {
    /// Long-lived access token from the Home Assistant profile. It is the
    /// complete credential.
    static let homeAssistantTokenKey = "gymPitBridgeHomeAssistantToken"
    static let baseURLKey = "gymPitBridgeBaseURL"
    static let localConnectionEnabledKey = "gymPitBridgeLocalConnectionEnabled"
    static let localHostKey = "gymPitBridgeLocalHost"
    static let localPortKey = "gymPitBridgeLocalPort"
    static let deviceIDKey = "gymPitBridgeDeviceID"
}

/// State established after connecting. Home Assistant issues no session: the
/// long-lived token is the credential and does not expire. Only the Home
/// Assistant user belonging to the token is retained, because that user owns
/// the entities on the receiving side.
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
    /// 2 = die Werte tragen die Kennungen aus HealthPits Katalog.
    ///
    /// Die Gegenstelle erkennt daran, dass sie `values` auswerten kann und
    /// nichts mehr uebersetzen muss. Aeltere Fassungen ignorieren beides.
    let modelVersion: Int
    /// Messwerte in HealthPits Sprache, je Uebung und Satz.
    let values: [HealthPitValue]

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case workouts, values
        case modelVersion = "model_version"
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

    /// Path including the integration prefix.
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
            return language.ui("HealthPit-Adresse fehlt.")
        case .missingToken:
            return language.ui("HealthPit-Token fehlt.")
        case .invalidURL:
            return language.ui("HealthPit-Adresse ist ungültig.")
        case .serverRejected(let code):
            return language.ui(format: "HealthPit hat die Übertragung abgelehnt (%d).", code)
        case .serverMessage(let message):
            // Already translated where the message is created.
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

    /// Connects to Home Assistant. The long-lived token *is* the credential and
    /// is verified once against the integration status endpoint.
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
                    "Home Assistant antwortet, aber die HealthPit-Integration ist dort nicht eingerichtet."
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
            // Die Messwerte in HealthPits Sprache reisen mit. Ohne diese Zeile
            // steht `values` leer in der Nutzlast – die Uebersetzung waere
            // gebaut, aber nie benutzt.
            let values = sessionsBatch.flatMap { HealthPitPayload.values(for: $0) }
            let batchSummary = try await uploadBatch(payloadBatch,
                                                     healthPitValues: values,
                                                     credentials: credentials)
            summary.add(batchSummary)
        }

        await backfillHistory(credentials: credentials)
        return summary
    }

    @discardableResult
    func uploadAndReconcile(_ sessions: [WorkoutSession]) async throws -> GymPitBridgeUploadSummary {
        let credentials = try await bridgeCredentials()
        var summary = GymPitBridgeUploadSummary()
        let batchSize = 25

        for startIndex in stride(from: 0, to: sessions.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, sessions.count)
            let sessionsBatch = Array(sessions[startIndex..<endIndex])
            let payloadBatch = sessionsBatch.map(GymPitBridgeImportedWorkoutPayload.init)
            let values = sessionsBatch.flatMap { HealthPitPayload.values(for: $0) }
            summary.add(try await uploadBatch(payloadBatch,
                                              healthPitValues: values,
                                              credentials: credentials))
        }

        try await reconcile(
            workoutIDs: sessions.map { $0.id.uuidString },
            credentials: credentials
        )
        await backfillHistory(credentials: credentials)
        return summary
    }

    /// Bittet HealthPit, die Vergangenheit nachzutragen.
    ///
    /// Hochgeladene Trainings stehen zunaechst nur als aktueller Zustand da.
    /// Home Assistant kann seine Zustandstabelle nicht rueckdatieren, seine
    /// Statistik aber schon – und genau die fuellt dieser Aufruf. Ohne ihn
    /// zeigt ein Diagramm ueber ein Jahr eine einzige Sitzung: die letzte.
    ///
    /// Ein Fehlschlag bleibt folgenlos. Der Upload ist zu diesem Zeitpunkt
    /// erledigt, und der naechste Abgleich versucht es erneut.
    private func backfillHistory(credentials: GymPitBridgeCredentials) async {
        var endpoint = credentials.baseURL
        endpoint.append(path: credentials.apiPath("history/workouts"))
        var request = authorizedRequest(url: endpoint, method: "POST", credentials: credentials)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)
        _ = try? await URLSession.shared.data(for: request)
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
        healthPitValues: [HealthPitValue] = [],
        credentials: GymPitBridgeCredentials
    ) async throws -> GymPitBridgeUploadSummary {
        var endpoint = credentials.baseURL
        endpoint.append(path: credentials.apiPath("workouts/imports"))

        let payload = GymPitBridgeImportedWorkoutBatchPayload(
            deviceID: credentials.deviceID,
            workouts: workouts,
            modelVersion: HealthPitPayload.modelVersion,
            values: healthPitValues
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
                // The token was revoked in Home Assistant or is invalid.
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
        // No username is needed because Home Assistant derives it from the token.
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
                AppLanguage.current.ui("Bitte die externe HealthPit-Adresse mit https:// eintragen.")
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
        // The status endpoint is authenticated, so probing it without the token
        // would always return 401.
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
            // No role check is needed: the integration status endpoint has no
            // primary/secondary role because there is no second instance.
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
        // The integration calls the reason "error"; older peers use "detail".
        let detail = (object["detail"] as? String) ?? (object["error"] as? String) ?? ""
        guard !detail.isEmpty else { return nil }
        return AppLanguage.current.ui(format: "HealthPit hat abgelehnt (%d): %@", statusCode, detail)
    }

    private static func trimmedKeychainValue(for key: String) -> String {
        GymPitBridgeKeychainStore.string(for: key)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

}

private extension GymPitBridgeImportedWorkoutPayload {
    init(session: WorkoutSession) {
        id = session.id.uuidString
        source = "gympit"
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
        reps = set.repetitions
        weightKg = set.weightKilograms
        rpe = set.perceivedExertion
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
