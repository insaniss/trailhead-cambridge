import SwiftUI

/// Root view: Instagram-style bottom tab bar — Home / Trails / Progress /
/// Settings — matching the web app's layout.
struct ContentView: View {
    @EnvironmentObject var tracker: LocationTracker
    let trails: [Trail]

    var body: some View {
        TabView {
            HomeView(trails: trails)
                .tabItem { Label("Home", systemImage: "house.fill") }

            TrailListView(trails: trails)
                .tabItem { Label("Trails", systemImage: "map.fill") }

            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.forest)
        .background(Color.stonePaper)
    }
}

struct HomeView: View {
    let trails: [Trail]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trailhead Cambridge")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.ink)
                        Text("12 trails around Cambridge, Ontario — live GPS, phone sensors, and Apple Maps.")
                            .foregroundStyle(.secondary)
                    }

                    if let featured = trails.first {
                        Text("Featured — your daily hike")
                            .font(.headline)
                        TrailCardView(trail: featured)
                    }

                    Text("Start with the Trails tab to pick a trail, then Start Live Tracking on its page. Tracking keeps running with the phone locked (grant Location: Always).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .background(Color.stonePaper)
        }
    }
}

struct TrailCardView: View {
    let trail: Trail

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(trail.name)
                .font(.headline)
                .foregroundStyle(Color.ink)
            HStack(spacing: 8) {
                if let label = trail.distanceLabel {
                    Label(label, systemImage: "figure.hiking")
                }
                if let gain = trail.elevationGainM {
                    Label("\(gain) m gain", systemImage: "arrow.up.right")
                }
                if let type = trail.type {
                    Text("· \(type)")
                }
            }
            .font(.caption)
            .foregroundStyle(Color.warmBrown)
            if let locality = trail.locality {
                Text(locality)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xD9D0BE)))
    }
}

struct TrailListView: View {
    let trails: [Trail]
    @State private var search = ""

    private var filtered: [Trail] {
        if search.isEmpty { return trails }
        return trails.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { trail in
                NavigationLink(value: trail) {
                    TrailCardView(trail: trail)
                }
                .listRowBackground(Color.stonePaper)
            }
            .listStyle(.plain)
            .background(Color.stonePaper)
            .searchable(text: $search, prompt: "Search trails")
            .navigationTitle("Trails")
            .navigationDestination(for: Trail.self) { trail in
                TrailDetailView(trail: trail)
            }
        }
    }
}

struct ProgressTabView: View {
    @State private var lastHike: HikeRecord?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Progress")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ink)

                if let hike = lastHike {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last hike — \(hike.trailName)")
                            .font(.headline)
                        Text(hike.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Time: \(formatDuration(hike.durationSeconds))")
                        Text("GPS distance: \(formatDistance(hike.gpsDistanceMeters))")
                        if let pedo = hike.pedometerDistanceMeters {
                            Text("Pedometer distance: \(formatDistance(pedo)) · \(hike.steps) steps")
                        }
                        Text("GPS climb / descent: \(Int(hike.gpsClimbMeters)) m / \(Int(hike.gpsDescentMeters)) m")
                        Text("Barometer climb / descent: \(Int(hike.barometerClimbMeters)) m / \(Int(hike.barometerDescentMeters)) m")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("Full progress tracking is under construction — hike history, totals and charts come later. Your last hike (above, when one exists) is saved on this phone only.")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .background(Color.stonePaper)
        .onAppear { lastHike = HikeStore.load() }
    }
}

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.ink)
                Text("Settings are under construction.")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Text("About this build")
                        .font(.headline)
                    Text("Free native test build (Swift), sideloaded via AltStore — it expires 7 days after install; refresh it in AltStore on the same Wi-Fi as your PC.")
                    Text("Sensor fusion is built in: GPS + pedometer + barometer, with background (locked-phone) location updates.")
                    Text("HealthKit is intentionally NOT in this free build yet — it gets added once free signing is validated on the phone (or with the paid Developer account).")
                    Text("Native roadmap already agreed: Apple Maps (MapKit) base map, Core Motion + barometer fusion like Apple Health, background tracking.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .background(Color.stonePaper)
    }
}
