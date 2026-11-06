import SwiftUI

/// Palette carried over from the web app redesign:
/// stone paper background, forest green primary, burnt orange CTAs
/// (bright orange is graphics-only there — buttons use the burnt tone
/// because white text on it passes contrast), near-black ink text.
extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    static let stonePaper = Color(hex: 0xFAF8F3)
    static let forest = Color(hex: 0x2F5233)
    static let forestDeep = Color(hex: 0x213A24)
    static let burntOrange = Color(hex: 0xC2410C)
    static let brightOrange = Color(hex: 0xEA580C)
    static let ink = Color(hex: 0x1A1E17)
    static let warmBrown = Color(hex: 0x6B4F35)
}

func formatDistance(_ meters: Double) -> String {
    if meters >= 1000 {
        return String(format: "%.2f km", meters / 1000)
    }
    return String(format: "%.0f m", meters)
}

func formatDuration(_ seconds: Double) -> String {
    let total = Int(seconds)
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
    return String(format: "%d:%02d", m, s)
}
