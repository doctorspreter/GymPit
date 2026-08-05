import SwiftUI

@main
struct GymPitWatchApp: App {
    @StateObject private var store = WatchWorkoutStore()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(store)
        }
    }
}
