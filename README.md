# Trailhead Cambridge — Native Swift Test App (Mac-free)

**Current plan (decided 2026-11-06): FREE NATIVE SWIFT testing.**
The app is a native **SwiftUI** iPhone app. Nobody on this project has a
Mac — Artur has a **Windows PC** and an **iPhone 17 Pro Max** — so the app
is compiled on a **cloud Mac (Codemagic)** into an **unsigned `.ipa`** and
sideloaded onto his iPhone with **AltStore** + a free Apple ID. **$0.**
Free-signed apps expire after **7 days** and are refreshed by AltStore over
Wi-Fi (PC on, same network). The paid TestFlight route (Apple Developer
Program, CA$118.99/yr) is the documented upgrade — same app, no rewrite.

> The earlier **Capacitor wrap** scaffold in this folder
> (`capacitor.config.json`, `package.json`, `www/`, and the `ios-testflight`
> workflow in `codemagic.yaml`) is **superseded — kept as a fallback only.**

## Folder layout

```
hiking-app-native/
├── README.md               <- this file
├── SETUP-CHECKLIST.md      <- Artur's step-by-step: free Swift/AltStore
│                              route (primary) + paid TestFlight upgrade
├── codemagic.yaml          <- cloud-Mac pipelines:
│                              • ios-sideload-unsigned  (PRIMARY, Swift)
│                              • ios-testflight          (future/fallback,
│                                Capacitor, needs paid Developer account)
├── swift/                  <- THE APP (native Swift)
│   ├── project.yml         <- XcodeGen spec: the .xcodeproj is GENERATED
│   │                          in CI from this file — no hand-written
│   │                          project file to maintain without a Mac
│   └── TrailheadCambridge/
│       ├── TrailheadCambridgeApp.swift   <- @main, tab shell wiring
│       ├── Info.plist      <- location (WhenInUse + Always) + motion usage
│       │                      strings, UIBackgroundModes = location.
│       │                      NO HealthKit entitlement in this free build.
│       ├── Models/Trail.swift        <- Trail model + trails.json loader
│       │                                + on-device last-hike storage
│       ├── Services/LocationTracker.swift
│       │                             <- CoreLocation (background updates ON)
│       │                                + CMPedometer + CMAltimeter,
│       │                                GPS vs sensors side by side
│       ├── Views/          <- ContentView (Home/Trails/Progress/Settings
│       │                      tabs), TrailDetailView (MapKit map, Apple
│       │                      Maps directions, live tracking panel), Theme
│       └── Resources/trails.json     <- all 12 Cambridge-area trails,
│                                        extracted from the web app export
├── capacitor.config.json   <- FALLBACK (Capacitor wrap) — superseded
├── package.json            <- FALLBACK (Capacitor wrap) — superseded
└── www/index.html          <- the original web app export (data source for
                               trails.json; also the Capacitor fallback app)
```

## The Swift app

- **Trails:** all 12 from the web app — Dryden, Sudden, Drynan, Dickson,
  Pinehurst, Little Tract, Devil's Creek, rare, Grand Trunk, Cambridge–Paris
  Rail Trail, Dumfries, Shade's Mills — with addresses, trailhead
  coordinates, distances, descriptions, and Dryden's **Farm Overlook** POI
  (43.31926, -80.37602, confirmed on site by Artur).
- **Screens:** bottom tab bar (Home / Trails / Progress / Settings —
  Progress and Settings are placeholders that show the last saved hike),
  trail list + search, trail detail with a **MapKit** map (trailhead pin,
  POI pins, user location), **Directions — Apple Maps** handoff button, and
  **Start/Stop Live Tracking**.
- **Tracking (the point of going native):**
  - CoreLocation with `allowsBackgroundLocationUpdates` — keeps tracking
    **with the phone locked** (needs Location: **Always**, granted on the
    phone at first launch).
  - GPS distance with the web version's lessons applied: fixes worse than
    ~30 m accuracy never count; distance accumulates from the last accepted
    fix so walking-pace fixes add up; GPS climb/descent behind a 3 m
    threshold.
  - **Side-by-side phone sensors:** CMPedometer (steps + step distance) and
    CMAltimeter barometer (climb/descent, 0.5 m threshold) displayed next to
    the GPS numbers so they can be compared on the trail.
  - On Stop, a **last-hike summary** (trail, date, duration, GPS distance,
    steps, GPS + barometer climb/descent) is saved on-device and shown in
    the Progress tab. Nothing leaves the phone.
- **Look:** the web app's palette — stone paper `#FAF8F3`, forest `#2F5233`,
  burnt orange `#C2410C` buttons, near-black `#1A1E17` text.
- **HealthKit:** deliberately **not** in this free build (no entitlement).
  It is added once free signing is validated on the phone, or with the paid
  Developer account. The sensor fusion that matters for trail accuracy —
  pedometer + barometer alongside GPS, the way Apple Health does it — plus
  background/locked tracking and the Apple Maps (MapKit) base map are the
  agreed native requirements and are designed in from this first build.

## Build flow

```
Edit anywhere (PC / Linux) ──push──► GitHub ──► Codemagic (cloud Mac)
                                                   │  brew install xcodegen (if needed)
                                                   │  xcodegen generate   (from swift/project.yml)
                                                   │  xcodebuild build    (CODE_SIGNING_ALLOWED=NO)
                                                   │  zip .app → Payload → unsigned .ipa
                                                   ▼
                              TrailheadCambridge-unsigned.ipa
                                                   │  AltStore on iPhone signs it
                                                   │  with Artur's free Apple ID
                                                   ▼
                                        Install on iPhone — refresh
                                        every 7 days over Wi-Fi
```

There is no iOS Simulator and no local iOS build on Windows/Linux: every
test build is a Codemagic build → AltStore install on the real phone.
First real compile happens on Codemagic (no iOS SDK on this machine).

## Placeholders / things only Artur supplies

1. **Bundle ID** — `com.artur.hikingapp` (in `swift/project.yml`) is a
   **placeholder**. For the free route it just needs to be consistent; it
   only becomes permanent if an App Store Connect record is created later.
2. **Accounts** — GitHub, Codemagic, Apple ID: Artur's own, created by him.
   Muse writes code and config only; Muse cannot create his accounts,
   enroll him, or pay for anything.
3. **Paid upgrade only:** App Store Connect integration name,
   `APP_STORE_APP_ID`, and the `.p8` API key (Codemagic only, never in this
   repo or in chat) — see `SETUP-CHECKLIST.md`.

Costs in one line: **free route $0** (Codemagic free tier = 500 macOS
minutes/month, then US$0.095/min); **proper TestFlight route =
CA$118.99/year** for the Apple Developer Program, cloud Mac still $0 within
the free minutes.
