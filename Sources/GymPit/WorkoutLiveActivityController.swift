import ActivityKit
import Foundation

@MainActor
final class WorkoutLiveActivityController {
    static let shared = WorkoutLiveActivityController()

    private var activityID: String?
    private var restEndDate: Date?

    private init() {}

    func refresh(for plan: WorkoutPlan) {
        guard let state = WorkoutActivitySnapshot.contentState(for: plan, restEndDate: restEndDate) else {
            end()
            return
        }

        let content = ActivityContent(state: state, staleDate: restEndDate)

        if let activity = activeActivity(for: plan) {
            Task {
                await activity.update(content)
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        do {
            let attributes = WorkoutActivityAttributes(planIDString: plan.id.uuidString)
            let activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            activityID = activity.id
        } catch {
            activityID = nil
        }
    }

    func setRest(seconds: Int, for plan: WorkoutPlan) {
        restEndDate = seconds > 0 ? Date().addingTimeInterval(TimeInterval(seconds)) : nil
        refresh(for: plan)
    }

    func clearRest(for plan: WorkoutPlan) {
        restEndDate = nil
        refresh(for: plan)
    }

    func end() {
        restEndDate = nil
        let activities = Activity<WorkoutActivityAttributes>.activities
        activityID = nil
        Task {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private func activeActivity(for plan: WorkoutPlan) -> Activity<WorkoutActivityAttributes>? {
        if let activityID,
           let activity = Activity<WorkoutActivityAttributes>.activities.first(where: { $0.id == activityID }) {
            return activity
        }

        let matching = Activity<WorkoutActivityAttributes>.activities.first {
            $0.attributes.planIDString == plan.id.uuidString
        }
        activityID = matching?.id
        return matching
    }
}
