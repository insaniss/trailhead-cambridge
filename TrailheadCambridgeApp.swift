import SwiftUI

@main
struct TrailheadCambridgeApp: App {
    @StateObject private var tracker = LocationTracker()
    private let trails = TrailData.load()

    var body: some Scene {
        WindowGroup {
            ContentView(trails: trails)
                .environmentObject(tracker)
        }
    }
}
