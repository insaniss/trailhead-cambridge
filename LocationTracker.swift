import Foundation
import CoreLocation
import CoreMotion

/// Live tracking engine — the whole reason for the native version:
/// GPS (CoreLocation, background updates ON so it keeps tracking with the
/// phone locked) running SIDE BY SIDE with the phone's own sensors —
/// CMPedometer for steps/distance and CMAltimeter (barometer) for
/// climb/descent — so the two can be compared on the trail.
///
/// Lessons carried over from the web version:
/// - Fixes with horizontal accuracy worse than ~30 m never count toward
///   distance and never move the anchor point (they caused phantom metres).
/// - Distance is accumulated segment-by-segment from the last *accepted*
///   fix, so walking-pace fixes 1-2 m apart still add up.
/// - GPS climb/descent uses a 3 m threshold so altitude noise doesn't
///   inflate the numbers; the barometer uses a 0.5 m threshold.
final class LocationTracker: NSObject, ObservableObject {

    // MARK: Published state for the UI
    @Published var isTracking = false
    @Published var statusText = "Not tracking"
    @Published var elapsedSeconds: Double = 0
    @Published var currentCoordinate: CLLocationCoordinate2D?
    @Published var lastAccuracy: Double?
    @Published var currentElevation: Double?

    // GPS numbers
    @Published var gpsDistanceMeters: Double = 0
    @Published var gpsClimbMeters: Double = 0
    @Published var gpsDescentMeters: Double = 0

    // Phone-sensor numbers (CoreMotion)
    @Published var steps: Int = 0
    @Published var pedometerDistanceMeters: Double?
    @Published var barometerClimbMeters: Double = 0
    @Published var barometerDescentMeters: Double = 0
    @Published var barometerAvailable = CMAltimeter.isRelativeAltitudeAvailable()
    @Published var pedometerAvailable = CMPedometer.isStepCountingAvailable()

    // MARK: Internals
    private let manager = CLLocationManager()
    private let pedometer = CMPedometer()
    private let altimeter = CMAltimeter()
    private var timer: Timer?
    private var startDate: Date?
    private var anchor: CLLocation?          // last fix accepted for distance
    private var lastAltitude: Double?        // last accepted GPS altitude
    private var lastRelativeAltitude: Double = 0
    private var currentTrail: Trail?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        // Locked-phone tracking: keep location updates coming in background.
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func requestPermissions() {
        // "Always" is what lets tracking continue with the phone locked.
        manager.requestAlwaysAuthorization()
    }

    func start(trail: Trail) {
        currentTrail = trail
        resetNumbers()
        startDate = Date()
        isTracking = true
        statusText = "Tracking — live"

        manager.startUpdatingLocation()

        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] data, _ in
                guard let self, let data else { return }
                DispatchQueue.main.async {
                    self.steps = data.numberOfSteps.intValue
                    self.pedometerDistanceMeters = data.distance?.doubleValue
                }
            }
        }

        if CMAltimeter.isRelativeAltitudeAvailable() {
            lastRelativeAltitude = 0
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                let rel = data.relativeAltitude.doubleValue
                let delta = rel - self.lastRelativeAltitude
                // 0.5 m noise threshold: only sustained moves accumulate.
                if delta >= 0.5 {
                    self.barometerClimbMeters += delta
                    self.lastRelativeAltitude = rel
                } else if delta <= -0.5 {
                    self.barometerDescentMeters += -delta
                    self.lastRelativeAltitude = rel
                }
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.startDate else { return }
            self.elapsedSeconds = Date().timeIntervalSince(start)
        }
    }

    /// Stops tracking and saves the "last hike" summary on-device.
    @discardableResult
    func stop() -> HikeRecord? {
        timer?.invalidate()
        timer = nil
        manager.stopUpdatingLocation()
        pedometer.stopUpdates()
        altimeter.stopRelativeAltitudeUpdates()
        isTracking = false
        statusText = "Stopped"

        guard let trail = currentTrail, let start = startDate else { return nil }
        let record = HikeRecord(
            trailName: trail.name,
            date: start,
            durationSeconds: Date().timeIntervalSince(start),
            gpsDistanceMeters: gpsDistanceMeters,
            pedometerDistanceMeters: pedometerDistanceMeters,
            steps: steps,
            gpsClimbMeters: gpsClimbMeters,
            gpsDescentMeters: gpsDescentMeters,
            barometerClimbMeters: barometerClimbMeters,
            barometerDescentMeters: barometerDescentMeters
        )
        if record.durationSeconds >= 5 {
            HikeStore.save(record)
        }
        return record
    }

    private func resetNumbers() {
        elapsedSeconds = 0
        gpsDistanceMeters = 0
        gpsClimbMeters = 0
        gpsDescentMeters = 0
        steps = 0
        pedometerDistanceMeters = nil
        barometerClimbMeters = 0
        barometerDescentMeters = 0
        anchor = nil
        lastAltitude = nil
        lastRelativeAltitude = 0
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationTracker: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for fix in locations {
            lastAccuracy = fix.horizontalAccuracy
            currentCoordinate = fix.coordinate

            // Accuracy gate: poor fixes are shown but never counted.
            guard fix.horizontalAccuracy >= 0, fix.horizontalAccuracy <= 30 else {
                if isTracking { statusText = "Tracking — holding for a better GPS fix" }
                continue
            }
            if isTracking { statusText = "Tracking — live" }

            if let anchor {
                gpsDistanceMeters += fix.distance(from: anchor)
            }
            anchor = fix

            if fix.verticalAccuracy >= 0 {
                currentElevation = fix.altitude
                if let last = lastAltitude {
                    let delta = fix.altitude - last
                    if delta >= 3 {
                        gpsClimbMeters += delta
                        lastAltitude = fix.altitude
                    } else if delta <= -3 {
                        gpsDescentMeters += -delta
                        lastAltitude = fix.altitude
                    }
                } else {
                    lastAltitude = fix.altitude
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusText = "Location error: \(error.localizedDescription)"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            statusText = "Location permission is off — enable it in Settings"
        }
    }
}
