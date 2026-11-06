import Foundation
import CoreLocation

/// One trail from the bundled `trails.json` (extracted from the web app's
/// data on 2026-11-06 — same names, addresses, coordinates and stats).
struct Trail: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let address: String?
    let locality: String?
    let latitude: Double
    let longitude: Double
    let distanceKm: Double?
    let distanceLabel: String?
    let elevationGainM: Int?
    let type: String?
    let surface: String?
    let description: String?
    let parking: String?
    let pointsOfInterest: [PointOfInterest]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Apple Maps directions handoff (opens the Maps app; no API key needed).
    var directionsURL: URL? {
        URL(string: "https://maps.apple.com/?daddr=\(latitude),\(longitude)")
    }
}

struct PointOfInterest: Codable, Identifiable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double
    let note: String?

    var id: String { name }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum TrailData {
    static func load() -> [Trail] {
        guard let url = Bundle.main.url(forResource: "trails", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let trails = try? JSONDecoder().decode([Trail].self, from: data) else {
            return []
        }
        return trails
    }
}

/// Summary of one finished hike, saved on-device (UserDefaults) on Stop.
struct HikeRecord: Codable {
    var trailName: String
    var date: Date
    var durationSeconds: Double
    var gpsDistanceMeters: Double
    var pedometerDistanceMeters: Double?
    var steps: Int
    var gpsClimbMeters: Double
    var gpsDescentMeters: Double
    var barometerClimbMeters: Double
    var barometerDescentMeters: Double
}

enum HikeStore {
    private static let key = "lastHikeRecord"

    static func save(_ record: HikeRecord) {
        if let data = try? JSONEncoder().encode(record) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> HikeRecord? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(HikeRecord.self, from: data)
    }
}
