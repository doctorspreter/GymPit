import SwiftUI

@main
struct GymPitWatchApp: App {
    @StateObject private var store = WatchWorkoutStore()
    @StateObject private var healthWorkout = WatchHealthWorkoutManager()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(store)
                .environmentObject(healthWorkout)
        }
    }
}
