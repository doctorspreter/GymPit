import Foundation

enum TrainerSetKind: String, Equatable {
    case work
    case warmup
    case drop
    case failure
}

struct TrainerSetSnapshot: Equatable {
    let kind: TrainerSetKind
    let repetitions: Int
    let weightKilograms: Double
    let rpe: Int?
}

struct TrainerRecommendation: Equatable {
    enum Basis: String, Equatable {
        case currentWorkout
        case previousWorkout
        case plan
    }

    let basis: Basis
    let title: String
    let explanation: String
    let weightKilograms: Double
    let repetitions: Int
    let restSeconds: Int
    let adjustmentPercent: Double
    let detailKeys: [String]
    let missingRPEHint: String?

    var requiresRPEInput: Bool { missingRPEHint != nil }

    init(
        basis: Basis,
        title: String,
        explanation: String,
        weightKilograms: Double,
        repetitions: Int,
        restSeconds: Int,
        adjustmentPercent: Double,
        detailKeys: [String] = [],
        missingRPEHint: String? = nil
    ) {
        self.basis = basis
        self.title = title
        self.explanation = explanation
        self.weightKilograms = weightKilograms
        self.repetitions = repetitions
        self.restSeconds = restSeconds
        self.adjustmentPercent = adjustmentPercent
        self.detailKeys = detailKeys
        self.missingRPEHint = missingRPEHint
    }
}

enum TrainerRecommendationEngine {
    static func recommendation(
        completedSets: [TrainerSetSnapshot],
        nextPlannedSet: TrainerSetSnapshot?,
        previousWorkoutSets: [TrainerSetSnapshot],
        defaultRestSeconds: Int
    ) -> TrainerRecommendation {
        let safeRest = min(300, max(30, defaultRestSeconds))

        if let nextPlannedSet, nextPlannedSet.kind == .drop || nextPlannedSet.kind == .warmup {
            return TrainerRecommendation(
                basis: .plan,
                title: nextPlannedSet.kind == .warmup ? "Warm-up wie geplant" : "Drop-Satz wie geplant",
                explanation: "Spezialsätze werden nicht anhand der RPE des Arbeitssatzes verändert.",
                weightKilograms: roundedWeight(nextPlannedSet.weightKilograms),
                repetitions: max(1, nextPlannedSet.repetitions),
                restSeconds: safeRest,
                adjustmentPercent: 0
            )
        }

        let completedWorkingSets = completedSets.filter { $0.kind == .work || $0.kind == .failure }
        if let latest = completedWorkingSets.last {
            return currentWorkoutRecommendation(
                latest: latest,
                workingSets: completedWorkingSets,
                nextPlannedSet: nextPlannedSet,
                defaultRestSeconds: safeRest
            )
        }

        let previousWorkingSets = previousWorkoutSets.filter { $0.kind == .work || $0.kind == .failure }
        if !previousWorkingSets.isEmpty {
            return previousWorkoutRecommendation(
                previousSets: previousWorkingSets,
                nextPlannedSet: nextPlannedSet,
                defaultRestSeconds: safeRest
            )
        }

        let planned = nextPlannedSet ?? TrainerSetSnapshot(kind: .work, repetitions: 12, weightKilograms: 0, rpe: nil)
        return TrainerRecommendation(
            basis: .plan,
            title: "Mit dem Plan starten",
            explanation: "Noch fehlen vergleichbare RPE-Daten. Erfasse nach dem Satz deine RPE, dann passt der Trainer den nächsten Satz an.",
            weightKilograms: roundedWeight(planned.weightKilograms),
            repetitions: max(1, planned.repetitions),
            restSeconds: safeRest,
            adjustmentPercent: 0,
            missingRPEHint: "Wähle nach jedem Satz eine RPE von 6 bis 10 aus. Ohne RPE kann der Trainer Gewicht und Pause nicht anpassen."
        )
    }

    private static func currentWorkoutRecommendation(
        latest: TrainerSetSnapshot,
        workingSets: [TrainerSetSnapshot],
        nextPlannedSet: TrainerSetSnapshot?,
        defaultRestSeconds: Int
    ) -> TrainerRecommendation {
        let baseWeight = latest.weightKilograms > 0
            ? latest.weightKilograms
            : (nextPlannedSet?.weightKilograms ?? latest.weightKilograms)
        let baseRepetitions = max(1, nextPlannedSet?.repetitions ?? latest.repetitions)

        guard let rpe = latest.rpe else {
            return TrainerRecommendation(
                basis: .currentWorkout,
                title: "RPE ergänzen",
                explanation: "Gewicht und Wiederholungen bleiben vorerst gleich. Mit einer RPE von 6 bis 10 kann der Trainer genauer steuern.",
                weightKilograms: roundedWeight(baseWeight),
                repetitions: baseRepetitions,
                restSeconds: defaultRestSeconds,
                adjustmentPercent: 0,
                missingRPEHint: "Für den letzten erfassten Satz fehlt die RPE. Tippe im Satz auf RPE und wähle einen Wert von 6 bis 10."
            )
        }

        var factor: Double
        var title: String
        var explanation: String
        var rest = defaultRestSeconds
        var detailKeys: [String] = []

        switch rpe {
        case ...6:
            factor = 1.05
            title = "Etwas steigern"
            explanation = "Die RPE lässt deutliche Reserven. Der nächste Satz darf etwas schwerer werden."
        case 7:
            factor = 1.025
            title = "Kleine Steigerung"
            explanation = "RPE 7 liegt unter dem produktiven Zielbereich. Eine kleine Laststeigerung ist sinnvoll."
        case 8:
            factor = 1
            title = "Gewicht halten"
            explanation = "RPE 8 passt gut: Belastung und Technik können im nächsten Satz stabil bleiben."
        case 9:
            factor = 0.975
            title = "Leicht entlasten"
            explanation = "RPE 9 war sehr fordernd. Eine kleine Reduktion hält den nächsten Satz sauber."
            rest += 30
        default:
            factor = 0.95
            title = "Erholung priorisieren"
            explanation = "RPE 10 bedeutet keine Reserve. Last reduzieren und länger pausieren."
            rest += 60
        }

        let recentRPEs = workingSets.suffix(2).compactMap(\.rpe)
        if recentRPEs.count == 2, Double(recentRPEs.reduce(0, +)) / 2 >= 9 {
            factor -= 0.025
            title = "Ermüdung abfangen"
            detailKeys.append("Zwei sehr harte Sätze in Folge sprechen für zusätzliche Entlastung.")
            rest += 30
        }

        let adjustmentPercent = (factor - 1) * 100
        let proposedWeight: Double
        let proposedRepetitions: Int

        if baseWeight > 0 {
            proposedWeight = roundedWeight(baseWeight * factor)
            proposedRepetitions = baseRepetitions
        } else {
            proposedWeight = 0
            proposedRepetitions = max(1, baseRepetitions + bodyweightRepetitionAdjustment(for: rpe))
            detailKeys.append("Da kein Zusatzgewicht hinterlegt ist, wird über Wiederholungen gesteuert.")
        }

        return TrainerRecommendation(
            basis: .currentWorkout,
            title: title,
            explanation: explanation,
            weightKilograms: proposedWeight,
            repetitions: proposedRepetitions,
            restSeconds: min(300, max(30, rest)),
            adjustmentPercent: adjustmentPercent,
            detailKeys: detailKeys
        )
    }

    private static func previousWorkoutRecommendation(
        previousSets: [TrainerSetSnapshot],
        nextPlannedSet: TrainerSetSnapshot?,
        defaultRestSeconds: Int
    ) -> TrainerRecommendation {
        let strongestSet = previousSets.max {
            estimatedOneRepMax(for: $0) < estimatedOneRepMax(for: $1)
        } ?? previousSets[0]
        let baseWeight = nextPlannedSet?.weightKilograms ?? strongestSet.weightKilograms
        let baseRepetitions = max(1, nextPlannedSet?.repetitions ?? strongestSet.repetitions)
        let rpeValues = previousSets.compactMap(\.rpe)

        guard !rpeValues.isEmpty else {
            return TrainerRecommendation(
                basis: .previousWorkout,
                title: "Letzte Leistung übernehmen",
                explanation: "Die letzte Einheit liefert Gewicht und Wiederholungen, aber noch keine RPE für eine belastbare Anpassung.",
                weightKilograms: roundedWeight(baseWeight),
                repetitions: baseRepetitions,
                restSeconds: defaultRestSeconds,
                adjustmentPercent: 0,
                missingRPEHint: "Erfasse in dieser Einheit nach jedem Satz die RPE, dann rechnet der Trainer beim nächsten Mal damit."
            )
        }

        let averageRPE = Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
        let factor: Double
        let title: String
        let explanation: String

        if averageRPE <= 7 {
            factor = 1.025
            title = "Stärker einsteigen"
            explanation = "Die letzte Einheit lag im niedrigen RPE-Bereich. Eine kleine Steigerung ist realistisch."
        } else if averageRPE >= 9 {
            factor = 0.95
            title = "Kontrolliert einsteigen"
            explanation = "Die letzte Einheit lag im sehr hohen RPE-Bereich. Heute etwas leichter beginnen."
        } else {
            factor = 1
            title = "Leistung bestätigen"
            explanation = "Die letzte Einheit lag im Zielbereich. Gewicht und Wiederholungen zunächst bestätigen."
        }

        return TrainerRecommendation(
            basis: .previousWorkout,
            title: title,
            explanation: explanation,
            weightKilograms: roundedWeight(baseWeight * factor),
            repetitions: baseRepetitions,
            restSeconds: defaultRestSeconds,
            adjustmentPercent: (factor - 1) * 100
        )
    }

    private static func estimatedOneRepMax(for set: TrainerSetSnapshot) -> Double {
        set.weightKilograms * (1 + Double(max(0, set.repetitions)) / 30)
    }

    private static func bodyweightRepetitionAdjustment(for rpe: Int) -> Int {
        switch rpe {
        case ...6: 2
        case 7: 1
        case 8: 0
        case 9: -1
        default: -2
        }
    }

    private static func roundedWeight(_ value: Double) -> Double {
        min(400, max(0, (value * 2).rounded() / 2))
    }
}
