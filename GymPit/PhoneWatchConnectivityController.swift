import Foundation
import WatchConnectivity

@MainActor
final class PhoneWatchConnectivityController: NSObject {
    static let shared = PhoneWatchConnectivityController()

    weak var store: WorkoutStore?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func publishCurrentState() {
        guard let store else { return }
        publish(plan: store.plan, restEndDate: GymPitSharedStorage.date(forKey: WorkoutPersistenceKeys.restEndDate))
    }

    func publish(plan: WorkoutPlan, restEndDate: Date?) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }

        let payload = statePayload(plan: plan, restEndDate: restEndDate)
        try? session.updateApplicationContext(payload)
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }

    private func statePayload(plan: WorkoutPlan, restEndDate: Date?) -> [String: Any] {
        var payload: [String: Any] = ["type": "state"]
        if let data = try? JSONEncoder().encode(plan) {
            payload["planData"] = data
        }
        if let restEndDate {
            payload["restEndTimestamp"] = restEndDate.timeIntervalSince1970
        }
        return payload
    }

    private func handle(_ message: [String: Any]) {
        guard let command = message["command"] as? String else {
            publishCurrentState()
            return
        }

        switch command {
        case "requestState":
            break
        case "startWorkout":
            store?.startWorkout()
        case "endWorkout":
            store?.endWorkout()
        case "completeNextSet":
            if let exerciseID = exerciseID(from: message) {
                store?.completeNextSet(for: exerciseID)
            }
        case "skipRest":
            if let exerciseID = exerciseID(from: message) {
                store?.skipRest(for: exerciseID)
            }
        case "selectExercise":
            if let exerciseID = exerciseID(from: message) {
                store?.selectExercise(id: exerciseID)
            }
        default:
            break
        }

        publishCurrentState()
    }

    private func exerciseID(from message: [String: Any]) -> UUID? {
        guard let idString = message["exerciseID"] as? String else { return nil }
        return UUID(uuidString: idString)
    }
}

extension PhoneWatchConnectivityController: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        Task { @MainActor in
            publishCurrentState()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor in
            publishCurrentState()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handle(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            handle(userInfo)
        }
    }
}
