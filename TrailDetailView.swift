import SwiftUI
import MapKit

struct TrailDetailView: View {
    let trail: Trail
    @EnvironmentObject var tracker: LocationTracker
    @Environment(\.openURL) private var openURL
    @State private var cameraPosition: MapCameraPosition

    init(trail: Trail) {
        self.trail = trail
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: trail.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                map
                if let desc = trail.description {
                    Text(desc).foregroundStyle(Color.ink)
                }
                infoRows
                trackingPanel
                directionsButton
            }
            .padding(16)
        }
        .background(Color.stonePaper)
        .navigationTitle(trail.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let address = trail.address {
                Text(trail.locality.map { "\(address) · \($0)" } ?? address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                if let label = trail.distanceLabel {
                    Label(label, systemImage: "figure.hiking")
                }
                if let gain = trail.elevationGainM {
                    Label("\(gain) m gain", systemImage: "arrow.up.right")
                }
                if let surface = trail.surface {
                    Label(surface, systemImage: "leaf")
                }
            }
            .font(.caption)
            .foregroundStyle(Color.warmBrown)
        }
    }

    private var map: some View {
        Map(position: $cameraPosition) {
            Marker("Trailhead", coordinate: trail.coordinate)
                .tint(Color.forest)
            ForEach(trail.pointsOfInterest) { poi in
                Marker(poi.name, coordinate: poi.coordinate)
                    .tint(Color.brightOrange)
            }
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var infoRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let parking = trail.parking {
                Label(parking, systemImage: "car.fill")
            }
            ForEach(trail.pointsOfInterest) { poi in
                if let note = poi.note {
                    Label("\(poi.name) — \(note)", systemImage: "star.fill")
                }
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private var directionsButton: some View {
        Button {
            if let url = trail.directionsURL { openURL(url) }
        } label: {
            Text("Directions — Apple Maps")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.borderedProminent)
        .tint(.burntOrange)
    }

    // MARK: Live tracking panel — GPS vs phone sensors, side by side

    private var trackingPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Live tracking")
                    .font(.headline)
                Spacer()
                Text(tracker.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                statBlock(title: "GPS", rows: [
                    ("Walked", formatDistance(tracker.gpsDistanceMeters)),
                    ("Climbed", "\(Int(tracker.gpsClimbMeters)) m"),
                    ("Descended", "\(Int(tracker.gpsDescentMeters)) m"),
                    ("Elevation", tracker.currentElevation.map { "\(Int($0)) m" } ?? "—"),
                    ("Accuracy", tracker.lastAccuracy.map { "±\(Int($0)) m" } ?? "—")
                ])
                statBlock(title: "Phone sensors", rows: [
                    ("Steps", "\(tracker.steps)"),
                    ("Step dist.", tracker.pedometerDistanceMeters.map(formatDistance) ?? "—"),
                    ("Climbed (baro.)", tracker.barometerAvailable ? "\(Int(tracker.barometerClimbMeters)) m" : "Unavailable"),
                    ("Descended (baro.)", tracker.barometerAvailable ? "\(Int(tracker.barometerDescentMeters)) m" : "Unavailable"),
                    ("Time", formatDuration(tracker.elapsedSeconds))
                ])
            }

            Text("Compare the two columns on the trail — barometer climb/descent and pedometer distance are the phone-sensor numbers Apple Health-style tracking uses, next to raw GPS.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if tracker.isTracking {
                Button(role: .destructive) {
                    tracker.stop()
                } label: {
                    Text("Stop Tracking")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.forestDeep)
            } else {
                Button {
                    tracker.requestPermissions()
                    tracker.start(trail: trail)
                } label: {
                    Text("Start Live Tracking")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.burntOrange)
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xD9D0BE)))
    }

    private func statBlock(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(Color.forest)
            ForEach(rows, id: \.0) { row in
                HStack {
                    Text(row.0).foregroundStyle(.secondary)
                    Spacer()
                    Text(row.1).fontWeight(.semibold)
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.stonePaper)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
