import Foundation
import HealthKit

enum WorkoutHealthExportError: LocalizedError {
    case unavailable
    case missingAuthorization
    case missingBuilderWorkout

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "Apple Health ist auf diesem Gerät nicht verfügbar."
        case .missingAuthorization:
            "Apple Health hat das Speichern nicht erlaubt."
        case .missingBuilderWorkout:
            "Apple Health hat kein Workout zurückgegeben."
        }
    }
}

enum WorkoutHealthSaveResult: Equatable {
    case saved
    case alreadyExists
}

final class WorkoutHealthExporter {
    static let shared = WorkoutHealthExporter()

    private let healthStore = HKHealthStore()

    private init() {}

    var isAuthorizedForAutomaticSave: Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        return healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    func requestAuthorization(completion: @escaping (Result<Void, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(WorkoutHealthExportError.unavailable))
            return
        }

        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
            if let error {
                completion(.failure(error))
            } else if success {
                completion(.success(()))
            } else {
                completion(.failure(WorkoutHealthExportError.missingAuthorization))
            }
        }
    }

    func save(_ session: WorkoutSession, completion: @escaping (Result<WorkoutHealthSaveResult, Error>) -> Void) {
        requestAuthorization { [weak self] result in
            switch result {
            case .success:
                self?.saveAuthorized(session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func delete(_ session: WorkoutSession, completion: @escaping (Result<Void, Error>) -> Void) {
        requestAuthorization { [weak self] result in
            switch result {
            case .success:
                self?.deleteAuthorized(session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private var shareTypes: Set<HKSampleType> {
        let workoutType = HKObjectType.workoutType()
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        var types: Set<HKSampleType> = [workoutType]
        if let energyType {
            types.insert(energyType)
        }
        return types
    }

    private var readTypes: Set<HKObjectType> {
        [HKObjectType.workoutType()]
    }

    private func saveAuthorized(
        _ session: WorkoutSession,
        completion: @escaping (Result<WorkoutHealthSaveResult, Error>) -> Void
    ) {
        workoutExists(for: session) { [weak self] result in
            switch result {
            case .success(true):
                completion(.success(.alreadyExists))
            case .success(false):
                self?.createWorkout(session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func workoutExists(
        for session: WorkoutSession,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        let predicate = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeyExternalUUID,
            allowedValues: [session.id.uuidString]
        )
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { _, samples, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(!(samples?.isEmpty ?? true)))
            }
        }
        healthStore.execute(query)
    }

    private func createWorkout(
        _ session: WorkoutSession,
        completion: @escaping (Result<WorkoutHealthSaveResult, Error>) -> Void
    ) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        let duration = max(60, session.durationMinutes * 60)
        let endDate = session.endDate
        let startDate = endDate.addingTimeInterval(-duration)

        builder.beginCollection(withStart: startDate) { [weak self] success, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard success else {
                completion(.failure(WorkoutHealthExportError.missingBuilderWorkout))
                return
            }

            self?.addSamplesAndFinish(builder: builder, session: session, startDate: startDate, endDate: endDate, completion: completion)
        }
    }

    private func addSamplesAndFinish(
        builder: HKWorkoutBuilder,
        session: WorkoutSession,
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<WorkoutHealthSaveResult, Error>) -> Void
    ) {
        let metadata: [String: Any] = [
            HKMetadataKeyIndoorWorkout: true,
            HKMetadataKeyExternalUUID: session.id.uuidString,
            "GymPitTrainingName": session.planName,
            "GymPitExerciseSummary": session.exerciseSummaryText,
            "GymPitTotalSets": "\(session.totalSets)",
            "GymPitTotalVolumeKg": session.totalVolume.formattedWeight
        ]

        builder.addMetadata(metadata) { _, metadataError in
            if let metadataError {
                completion(.failure(metadataError))
                return
            }

            let samples = self.energySamples(for: session, startDate: startDate, endDate: endDate)
            guard !samples.isEmpty else {
                self.finish(builder: builder, endDate: endDate, completion: completion)
                return
            }

            builder.add(samples) { _, sampleError in
                if let sampleError {
                    completion(.failure(sampleError))
                } else {
                    self.finish(builder: builder, endDate: endDate, completion: completion)
                }
            }
        }
    }

    private func energySamples(for session: WorkoutSession, startDate: Date, endDate: Date) -> [HKSample] {
        guard session.calories > 0,
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return []
        }

        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: Double(session.calories))
        return [HKQuantitySample(type: energyType, quantity: quantity, start: startDate, end: endDate)]
    }

    private func finish(
        builder: HKWorkoutBuilder,
        endDate: Date,
        completion: @escaping (Result<WorkoutHealthSaveResult, Error>) -> Void
    ) {
        builder.endCollection(withEnd: endDate) { _, endError in
            if let endError {
                completion(.failure(endError))
                return
            }

            builder.finishWorkout { workout, finishError in
                if let finishError {
                    completion(.failure(finishError))
                } else if workout == nil {
                    completion(.failure(WorkoutHealthExportError.missingBuilderWorkout))
                } else {
                    completion(.success(.saved))
                }
            }
        }
    }

    private func deleteAuthorized(_ session: WorkoutSession, completion: @escaping (Result<Void, Error>) -> Void) {
        let metadataPredicate = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeyExternalUUID,
            allowedValues: [session.id.uuidString]
        )
        let datePredicate = HKQuery.predicateForSamples(
            withStart: session.startDate.addingTimeInterval(-60),
            end: session.endDate.addingTimeInterval(60)
        )
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [metadataPredicate, datePredicate])
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
                completion(.success(()))
                return
            }

            self?.healthStore.delete(workouts) { success, deleteError in
                if let deleteError {
                    completion(.failure(deleteError))
                } else if success {
                    completion(.success(()))
                } else {
                    completion(.failure(WorkoutHealthExportError.missingAuthorization))
                }
            }
        }
        healthStore.execute(query)
    }
}
