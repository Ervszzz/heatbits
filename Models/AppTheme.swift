import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case green  = "Green"
    case blue   = "Blue"
    case purple = "Purple"
    case orange = "Orange"
    case pink   = "Pink"

    var id: String { rawValue }

    var accentColor: Color {
        switch self {
        case .green:  return Color(hex: "#30D158")!
        case .blue:   return Color(hex: "#0A84FF")!
        case .purple: return Color(hex: "#BF5AF2")!
        case .orange: return Color(hex: "#FF9F0A")!
        case .pink:   return Color(hex: "#FF375F")!
        }
    }

    func heatmapColor(rate: Double) -> Color {
        if rate <= 0 { return Color(hex: "#2C2C2E")! }
        let t = max(0, min(1, rate))
        switch self {
        case .green:
            return interpolate(t, from: (0x1A, 0x5C, 0x30), to: (0x34, 0xFF, 0x6A))
        case .blue:
            return interpolate(t, from: (0x1A, 0x3A, 0x6E), to: (0x0A, 0x84, 0xFF))
        case .purple:
            return interpolate(t, from: (0x3A, 0x1A, 0x6E), to: (0xBF, 0x5A, 0xF2))
        case .orange:
            return interpolate(t, from: (0x6E, 0x3A, 0x1A), to: (0xFF, 0x9F, 0x0A))
        case .pink:
            return interpolate(t, from: (0x6E, 0x1A, 0x3A), to: (0xFF, 0x37, 0x5F))
        }
    }

    private func interpolate(_ t: Double,
                             from: (Int, Int, Int),
                             to: (Int, Int, Int)) -> Color {
        let r = from.0 + Int(Double(to.0 - from.0) * t)
        let g = from.1 + Int(Double(to.1 - from.1) * t)
        let b = from.2 + Int(Double(to.2 - from.2) * t)
        return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
