//
//  HealthPitPayload.swift
//  GymPit
//
//  Ein Training in der Sprache von HealthPit.
//
//  Frueher schickte GymPit seine eigenen Feldnamen (`weight_kg`, `reps`), und
//  HealthPit uebersetzte sie mit einer Tabelle. Zwei Seiten, eine Bedeutung,
//  zwei Schreibweisen – und beide mussten gepflegt werden. Jetzt spricht
//  GymPit die Kennungen aus `HealthPitMetricIDs` direkt; die Tabelle in der
//  Mitte faellt weg.
//
//  Was hier entsteht, ist eine flache Liste von Messwerten. Die Struktur geht
//  dabei nicht verloren: Jeder Wert traegt `exercise_id` und `set_index`, so
//  dass HealthPit Uebung und Satz wieder zusammensetzen kann, ohne dass die
//  Reihenfolge eine Rolle spielt.
//

import Foundation

/// Ein einzelner Messwert auf dem Weg zu HealthPit.
struct HealthPitValue: Encodable {
    let metricID: String
    let unit: String?
    /// Zahl, Text oder Ja/Nein – je nachdem, was die Metrik traegt.
    let value: Double?
    let text: String?
    let boolean: Bool?
    let start: Date
    let end: Date
    /// Woran der Wert haengt. Leer bei Werten des ganzen Trainings.
    let exerciseID: String?
    let exerciseName: String?
    let setIndex: Int?

    enum CodingKeys: String, CodingKey {
        case unit, value, text, boolean, start, end
        case metricID = "metric_id"
        case exerciseID = "exercise_id"
        case exerciseName = "exercise_name"
        case setIndex = "set_index"
    }
}

enum HealthPitPayload {

    /// Fassung der Nutzlast. HealthPit und die Home-Assistant-Integration
    /// erkennen daran, dass die Werte bereits kanonisch benannt sind.
    static let modelVersion = 2

    /// Alle Werte eines Trainings.
    static func values(for session: WorkoutSession,
                       bodyWeightKg: Double? = nil) -> [HealthPitValue] {
        let start = session.date
        let end = session.date.addingTimeInterval(session.durationMinutes * 60)
        var values: [HealthPitValue] = []

        func add(_ metric: HealthPitMetric,
                 value: Double? = nil,
                 text: String? = nil,
                 boolean: Bool? = nil,
                 from: Date = start,
                 to: Date = end,
                 exerciseID: String? = nil,
                 exerciseName: String? = nil,
                 setIndex: Int? = nil) {
            values.append(HealthPitValue(metricID: metric.id,
                                         unit: metric.unit,
                                         value: value,
                                         text: text,
                                         boolean: boolean,
                                         start: from,
                                         end: to,
                                         exerciseID: exerciseID,
                                         exerciseName: exerciseName,
                                         setIndex: setIndex))
        }

        // Das ganze Training.
        add(HealthPitMetricIDs.wrkDuration, value: session.durationMinutes * 60)
        if session.calories > 0 {
            add(HealthPitMetricIDs.wrkEnergy, value: Double(session.calories))
        } else if let calories = estimatedCalories(for: session, bodyWeightKg: bodyWeightKg) {
            // Kein gemessener Wert: aus MET, Koerpergewicht und Dauer
            // gerechnet. Die Rechnung steht offen in `estimatedCalories` –
            // besser eine nachvollziehbare Schaetzung als eine Luecke.
            add(HealthPitMetricIDs.wrkEnergy, value: calories)
        }

        // Je Uebung und Satz.
        for exercise in session.exercises {
            let exerciseID = exercise.catalogID.isEmpty
                ? "custom-\(exercise.id.uuidString.lowercased())"
                : exercise.catalogID

            add(HealthPitMetricIDs.wrkExercise,
                text: exerciseID,
                exerciseID: exerciseID,
                exerciseName: exercise.name)

            // Geraeteeinstellungen nur, wenn wirklich etwas eingetragen ist.
            // Der Katalog liefert keine Voreinstellungen mehr; was hier steht,
            // hat der Anwender selbst gesetzt und ist deshalb eine Aussage.
            for (metric, entry) in equipmentEntries(exercise.deviceSettings) {
                add(metric, text: entry, exerciseID: exerciseID, exerciseName: exercise.name)
            }

            for (index, set) in exercise.sets.enumerated() {
                let common: (HealthPitMetric, Double?, String?, Bool?) -> Void = { metric, value, text, boolean in
                    add(metric, value: value, text: text, boolean: boolean,
                        exerciseID: exerciseID, exerciseName: exercise.name, setIndex: index)
                }
                common(HealthPitMetricIDs.wrkSetReps, Double(set.repetitions), nil, nil)
                if set.weightKilograms > 0 {
                    common(HealthPitMetricIDs.wrkSetWeight, set.weightKilograms, nil, nil)
                    common(HealthPitMetricIDs.wrkSetVolume, Double(set.repetitions) * set.weightKilograms, nil, nil)
                }
                if let rpe = set.perceivedExertion {
                    common(HealthPitMetricIDs.wrkSetRpe, Double(rpe), nil, nil)
                }
                common(HealthPitMetricIDs.wrkSetType, nil, setTypeCode(set.type), nil)
                if set.isPersonalRecord {
                    common(HealthPitMetricIDs.wrkSetIsPersonalRecord, nil, nil, true)
                }
            }
        }
        return values
    }

    /// Nur die Einstellungen, die gesetzt sind.
    static func equipmentEntries(_ settings: DeviceSettings) -> [(HealthPitMetric, String)] {
        var result: [(HealthPitMetric, String)] = []
        func take(_ metric: HealthPitMetric, _ value: String) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed != "-" else { return }
            result.append((metric, trimmed))
        }
        take(HealthPitMetricIDs.wrkEquipmentSeat, settings.seat)
        take(HealthPitMetricIDs.wrkEquipmentBackrest, settings.backrest)
        take(HealthPitMetricIDs.wrkEquipmentHandle, settings.handle)
        take(HealthPitMetricIDs.wrkEquipmentRange, settings.range)
        return result
    }

    /// Die Satzart als sprachneutraler Code.
    ///
    /// GymPits Rohwerte sind deutsche Woerter („Arbeit“, „Warm-up“). Als
    /// Kennung taugen sie nicht: Sie wuerden sich mit einer Uebersetzung
    /// aendern, und HealthPit fuehrt sie als festen Satz erlaubter Codes.
    static func setTypeCode(_ type: WorkoutSetType) -> String {
        switch type {
        case .normal:  return "WORKING"
        case .warmup:  return "WARMUP"
        case .drop:    return "DROPSET"
        case .failure: return "FAILURE"
        }
    }

    /// Kalorien aus MET, Koerpergewicht und Dauer.
    ///
    ///     kcal = MET × kg × Stunden
    ///
    /// Ohne Koerpergewicht keine Schaetzung – lieber keine Zahl als eine
    /// erfundene.
    static func estimatedCalories(for session: WorkoutSession,
                                  bodyWeightKg: Double?) -> Double? {
        guard let weight = bodyWeightKg, weight > 0, session.durationMinutes > 0 else { return nil }
        let mets = session.exercises.compactMap { ExerciseCatalog.item(for: $0.catalogID)?.metValue }
        guard !mets.isEmpty else { return nil }
        let averageMet = mets.reduce(0, +) / Double(mets.count)
        return averageMet * weight * (session.durationMinutes / 60)
    }
}
