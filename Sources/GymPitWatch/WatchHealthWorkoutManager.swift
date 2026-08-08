import Foundation
import HealthKit
import WatchKit

struct WatchWorkoutSummary {
    let workoutID: UUID?
    let durationSeconds: TimeInterval
    let activeCalories: Double
    let wasSavedToHealth: Bool
}

@MainActor
final class WatchHealthWorkoutManager: NSObject, ObservableObject {
    enum Phase: Equatable {
        case idle
        case preparing
        case running
        case paused
        case ending
        case finished
        case failed(String)

        var isActive: Bool {
            switch self {
            case .preparing, .running, .paused, .ending:
                true
            case .idle, .finished, .failed:
                false
            }
        }
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var heartRate = 0.0
    @Published private(set) var activeCalories = 0.0
    @Published private(set) var elapsedSeconds: TimeInterval = 0

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var workoutID: UUID?
    private var workoutName = "Training"
    private var startedAt: Date?
    private var pausedAt: Date?
    private var accumulatedPauseSeconds: TimeInterval = 0
    private var timer: Timer?
    private var finishCompletion: ((WatchWorkoutSummary) -> Void)?

    deinit {
        timer?.invalidate()
    }

    var isPaused: Bool { phase == .paused }
    var hasLiveWorkout: Bool { phase.isActive }

    func startWorkout(named name: String) {
        guard !phase.isActive else { return }
        guard HKHealthStore.isHealthDataAvailable() else {
            phase = .failed("Apple Health ist auf dieser Watch nicht verfügbar.")
            return
        }

        resetMetrics()
        workoutName = name
        workoutID = UUID()
        phase = .preparing

        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { [weak self] success, error in
            Task { @MainActor in
                guard let self else { return }
                guard self.phase == .preparing else { return }
                if let error {
                    self.phase = .failed(error.localizedDescription)
                } else if success {
                    self.beginAuthorizedWorkout()
                } else {
                    self.phase = .failed("Apple Health hat das Aufzeichnen nicht erlaubt.")
                }
            }
        }
    }

    func togglePause() {
        guard let workoutSession else { return }
        if phase == .paused {
            workoutSession.resume()
            if let pausedAt {
                accumulatedPauseSeconds += Date().timeIntervalSince(pausedAt)
            }
            self.pausedAt = nil
            phase = .running
            WKInterfaceDevice.current().play(.start)
        } else if phase == .running {
            workoutSession.pause()
            pausedAt = Date()
            phase = .paused
            WKInterfaceDevice.current().play(.stop)
        }
        updateElapsedTime()
    }

    func endWorkout(completion: @escaping (WatchWorkoutSummary) -> Void) {
        guard phase.isActive, let workoutSession, let workoutBuilder else {
            completion(currentSummary(savedToHealth: false))
            phase = .finished
            return
        }

        phase = .ending
        finishCompletion = completion
        updateElapsedTime()
        timer?.invalidate()
        timer = nil

        let endDate = Date()
        workoutSession.end()
        workoutBuilder.endCollection(withEnd: endDate) { [weak self] success, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.finishWithError(error)
                    return
                }
                guard success else {
                    self.finishWithError(WatchHealthWorkoutError.couldNotFinish)
                    return
                }
                self.addMetadataAndFinish()
            }
        }
    }

    private var shareTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        return types
    }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        return types
    }

    private func beginAuthorizedWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            session.delegate = self
            builder.delegate = self
            workoutSession = session
            workoutBuilder = builder

            let startDate = Date()
            startedAt = startDate
            session.startActivity(with: startDate)
            builder.beginCollection(withStart: startDate) { [weak self] success, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        self.finishWithError(error)
                    } else if success {
                        self.phase = .running
                        self.startTimer()
                        WKInterfaceDevice.current().play(.start)
                    } else {
                        self.finishWithError(WatchHealthWorkoutError.couldNotStart)
                    }
                }
            }
        } catch {
            finishWithError(error)
        }
    }

    private func addMetadataAndFinish() {
        guard let workoutBuilder else {
            finishWithError(WatchHealthWorkoutError.couldNotFinish)
            return
        }

        var metadata: [String: Any] = [
            HKMetadataKeyIndoorWorkout: true,
            "GymPitTrainingName": workoutName
        ]
        if let workoutID {
            metadata[HKMetadataKeyExternalUUID] = workoutID.uuidString
        }

        workoutBuilder.addMetadata(metadata) { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.finishWithError(error)
                    return
                }
                do {
                    let workout = try await workoutBuilder.finishWorkout()
                    self.finishSuccessfully(savedToHealth: workout != nil)
                } catch {
                    self.finishWithError(error)
                }
            }
        }
    }

    private func finishSuccessfully(savedToHealth: Bool) {
        let summary = currentSummary(savedToHealth: savedToHealth)
        phase = .finished
        workoutSession = nil
        workoutBuilder = nil
        WKInterfaceDevice.current().play(.success)
        let completion = finishCompletion
        finishCompletion = nil
        completion?(summary)
    }

    private func finishWithError(_ error: Error) {
        let summary = currentSummary(savedToHealth: false)
        phase = .failed(error.localizedDescription)
        workoutSession?.end()
        workoutSession = nil
        workoutBuilder = nil
        timer?.invalidate()
        timer = nil
        let completion = finishCompletion
        finishCompletion = nil
        completion?(summary)
    }

    private func currentSummary(savedToHealth: Bool) -> WatchWorkoutSummary {
        WatchWorkoutSummary(
            workoutID: workoutID,
            durationSeconds: elapsedSeconds,
            activeCalories: activeCalories,
            wasSavedToHealth: savedToHealth
        )
    }

    private func resetMetrics() {
        heartRate = 0
        activeCalories = 0
        elapsedSeconds = 0
        startedAt = nil
        pausedAt = nil
        accumulatedPauseSeconds = 0
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
        updateElapsedTime()
    }

    private func updateElapsedTime() {
        guard let startedAt else { return }
        let effectiveEnd = pausedAt ?? Date()
        elapsedSeconds = max(0, effectiveEnd.timeIntervalSince(startedAt) - accumulatedPauseSeconds)
    }

    private func updateStatistics(for types: Set<HKSampleType>) {
        guard let workoutBuilder else { return }

        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
           types.contains(heartRateType),
           let statistics = workoutBuilder.statistics(for: heartRateType),
           let quantity = statistics.mostRecentQuantity() {
            heartRate = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }

        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           types.contains(energyType),
           let statistics = workoutBuilder.statistics(for: energyType),
           let quantity = statistics.sumQuantity() {
            activeCalories = quantity.doubleValue(for: .kilocalorie())
        }
    }
}

extension WatchHealthWorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            if toState == .paused {
                phase = .paused
            } else if toState == .running {
                phase = .running
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in
            finishWithError(error)
        }
    }
}

extension WatchHealthWorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            updateStatistics(for: collectedTypes)
        }
    }
}

private enum WatchHealthWorkoutError: LocalizedError {
    case couldNotStart
    case couldNotFinish

    var errorDescription: String? {
        switch self {
        case .couldNotStart:
            "Das HealthKit-Training konnte nicht gestartet werden."
        case .couldNotFinish:
            "Das HealthKit-Training konnte nicht gespeichert werden."
        }
    }
}
