import SwiftUI
import AppKit

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

struct ColorOption: Identifiable {
    let id = UUID()
    let name: String
    let hex: String

    static let all: [ColorOption] = [
        ColorOption(name: "Orange", hex: "#FF9500"),
        ColorOption(name: "Green", hex: "#34C759"),
        ColorOption(name: "Blue", hex: "#007AFF"),
        ColorOption(name: "Red", hex: "#FF3B30"),
        ColorOption(name: "Purple", hex: "#AF52DE"),
        ColorOption(name: "Pink", hex: "#FF2D55"),
        ColorOption(name: "Teal", hex: "#5AC8FA"),
        ColorOption(name: "Yellow", hex: "#FFCC00"),
        ColorOption(name: "Indigo", hex: "#5856D6"),
        ColorOption(name: "Mint", hex: "#00C7BE"),
    ]
}
