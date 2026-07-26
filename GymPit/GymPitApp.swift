import SwiftUI
import UIKit
import UserNotifications

enum GymPitNotificationIDs {
    static let restReadyCategory = "GYMPIT_REST_READY"
    static let completeNextSetAction = "GYMPIT_COMPLETE_NEXT_SET"
    static let openWorkoutAction = "GYMPIT_OPEN_WORKOUT"
}

final class GymPitAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppNotificationCenter.registerCategories()
        UNUserNotificationCenter.current().delegate = AppNotificationCenter.shared
        return true
    }
}

final class AppNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AppNotificationCenter()

    @MainActor weak var store: WorkoutStore?

    static func registerCategories() {
        let completeSetAction = UNNotificationAction(
            identifier: GymPitNotificationIDs.completeNextSetAction,
            title: "Satz erledigt",
            options: []
        )
        let openWorkoutAction = UNNotificationAction(
            identifier: GymPitNotificationIDs.openWorkoutAction,
            title: "Öffnen",
            options: [.foreground]
        )

        let restCategory = UNNotificationCategory(
            identifier: GymPitNotificationIDs.restReadyCategory,
            actions: [completeSetAction, openWorkoutAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([restCategory])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo

        Task { @MainActor in
            AppNotificationCenter.shared.store?.handleNotificationAction(actionIdentifier, userInfo: userInfo)
            completionHandler()
        }
    }
}

@main
struct GymPitApp: App {
    @UIApplicationDelegateAdaptor(GymPitAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    AppNotificationCenter.shared.store = store
                    PhoneWatchConnectivityController.shared.store = store
                    PhoneWatchConnectivityController.shared.activate()
                    PhoneWatchConnectivityController.shared.publishCurrentState()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        store.reloadPlanFromSharedStorage()
                        store.clearDeliveredWorkoutNotifications()
                        PhoneWatchConnectivityController.shared.publishCurrentState()
                    }
                }
        }
    }
}
