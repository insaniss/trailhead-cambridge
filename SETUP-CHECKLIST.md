# Setup Checklist — Trailhead Cambridge on Your iPhone (No Mac)

Artur's setup: **Windows PC + iPhone 17 Pro Max. No Mac.**

**The plan (decided 2026-11-06): FREE NATIVE SWIFT testing.**
The app is now a real native Swift app (in `swift/`). Codemagic's cloud Mac
compiles it into an **unsigned `.ipa`**, and Artur installs it on his iPhone
with **AltStore** using his **free Apple ID** — **$0 total**. The trade-off:
free-signed apps expire after **7 days** and need a quick refresh.

The paid TestFlight route still exists as the **upgrade** (bottom of this
file) — same Swift app, no rewrite, just better delivery.

---

## What it costs

| Item | Cost |
|---|---|
| Apple Developer Program | **$0 — not needed for this route** (CA$118.99/yr only for the TestFlight upgrade) |
| Codemagic (cloud Mac builds) | **$0** — free tier includes **500 macOS build minutes/month**, then US$0.095/min pay-as-you-go |
| AltStore / AltServer | **$0** |
| GitHub (code hosting) | **$0** — free account |

**Total for free native Swift testing: $0.**

Never put an Apple ID password, payment details, or any key file into chat.
Accounts and sign-ins are Artur's, on his own devices.

---

## PRIMARY ROUTE — Free native Swift via AltStore

### Step 1 — Put the project on GitHub (Artur, free account)
- Create a **free GitHub account** (if you don't have one) at github.com.
- Create a **private** repository (e.g. `trailhead-cambridge`) and push this
  `hiking-app-native/` folder to it — or ask Muse for the exact commands;
  the folder is ready to push as-is. The Swift app lives in `swift/`.

### Step 2 — Build the unsigned .ipa on Codemagic (Artur clicks, Muse configured it)
1. Create a **free Codemagic account** at codemagic.io and add the GitHub
   repo as an app.
2. Start the workflow **"iOS - Sideload unsigned .ipa (native Swift, free
   AltStore route)"** (`ios-sideload-unsigned` in `codemagic.yaml`).
   The cloud Mac will: install XcodeGen → generate the Xcode project from
   `swift/project.yml` → build the Swift app unsigned → package
   **`TrailheadCambridge-unsigned.ipa`**.
3. Download that `.ipa` artifact from the finished build.
   First builds sometimes fail on a config detail — send the build log to
   Muse and the config gets fixed. That's expected, not a dead end.

### Step 3 — Install AltStore (Artur, Windows PC + iPhone)
1. **On the PC:** install iTunes and iCloud for Windows **from Apple's
   website** (not the Microsoft Store versions — AltServer can't use those).
2. **On the PC:** download and install **AltServer** from **altstore.io**.
   Run it (it lives in the system tray).
3. **Plug the iPhone into the PC**, unlock it, tap **Trust** if asked. In
   iTunes, enable Wi-Fi sync for the phone.
4. **In AltServer (system tray):** Install AltStore → select the iPhone →
   sign in with your Apple ID. AltStore appears on the home screen.
5. **Trust the profile on the iPhone:** Settings → General → VPN & Device
   Management → trust your Apple ID profile. (On newer iOS you may also need
   Settings → Privacy & Security → **Developer Mode ON**, then restart.)

### Step 4 — Sideload the app
1. Get `TrailheadCambridge-unsigned.ipa` onto the phone (Files / iCloud
   Drive / USB transfer).
2. **In AltStore:** My Apps → **+** → pick the `.ipa`. AltStore signs it
   with your free Apple ID and installs **Trailhead Cambridge**.
3. **The 7-day rule:** it stops opening after 7 days unless refreshed.
   AltStore refreshes automatically in the background **as long as the PC
   is on, AltServer is running, and PC + iPhone share the same Wi-Fi**.
   Expired? Open AltStore near the PC → **Refresh All**. Free Apple IDs cap
   you at **3 sideloaded apps** at once — fine for this.

### Step 5 — First launch on the phone (important for trail tracking)
- Open the app and grant, when prompted:
  - **Location: "Always"** (not just "While Using") — this is what lets
    tracking keep running **with the phone locked** in your pocket.
  - **Motion & Fitness: Allow** — turns on the pedometer + barometer, so you
    get steps/step-distance and barometer climb/descent next to the GPS
    numbers.
- Then: Trails tab → Dryden → **Start Live Tracking**, lock the phone, and
  hike. Stop at the end — the hike summary saves on the phone and shows in
  the Progress tab.

---

## UPGRADE — Paid TestFlight route (when/if you want it)

Removes the 7-day refresh and the 3-app cap; builds arrive in Apple's
TestFlight app and last 90 days. **The app code does not change.**

1. **Enroll in the Apple Developer Program** — **CA$118.99/year** in Canada,
   with your own Apple ID at developer.apple.com. Artur only: his identity,
   his payment, his agreements. Muse cannot enroll or pay for him.
2. **Create the app record** in App Store Connect (bundle ID
   `com.artur.hikingapp` — a placeholder until this moment; once the record
   exists, the bundle ID **cannot** change).
3. **Create an App Store Connect API key** (Users and Access → Integrations)
   and upload the `.p8` file **only into Codemagic's** App Store Connect
   integration. 🔒 The `.p8` is downloaded once — never send it in chat or
   commit it to the repo.
4. A signed TestFlight workflow gets added to `codemagic.yaml` for the
   **Swift** app at that point (the `ios-testflight` workflow currently in
   the file is the older Capacitor-wrap fallback — kept for reference, not
   the Swift path).
5. Install **TestFlight** (free) on the iPhone, accept the tester invite,
   install Trailhead Cambridge from there.

**HealthKit note:** this free build deliberately has **no HealthKit**
entitlement. HealthKit (saving hikes into Apple Health, reading Apple
Health data) gets added once free signing is validated on the phone — or
with the paid account, where there's no question about it.

---

## Who does what

| Task | Artur | Muse |
|---|---|---|
| GitHub + Codemagic free accounts | ✅ His accounts | Writes all config |
| AltServer install, AltStore install, sideloading, refreshes | ✅ His PC/phone | Gives exact steps |
| Granting Location "Always" + Motion on the phone | ✅ | — |
| Apple Developer enrollment + payment (upgrade only) | ✅ Himself only | ❌ Cannot — his account/identity/payment |
| App Store Connect record + API key `.p8` (upgrade only) | ✅ Himself only (key never shared) | Can give exact values to type |
| All Swift code, `project.yml`, `codemagic.yaml`, build-log fixes | — | ✅ |
| On-trail testing and reporting results | ✅ | Interprets results, fixes, iterates |

## Decisions still open for Artur
1. **Bundle ID:** `com.artur.hikingapp` is a placeholder. For the free
   AltStore route it only needs to stay consistent; it becomes permanent
   only if/when an App Store Connect record is created (paid route).
2. **App record name (paid route only):** "Trailhead Cambridge" must be
   unique on the App Store when that day comes.
3. The Capacitor wrap files (`capacitor.config.json`, `package.json`,
   `www/`) are a **superseded fallback** — kept in the folder, not the plan.
