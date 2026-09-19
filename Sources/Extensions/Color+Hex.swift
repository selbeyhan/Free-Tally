import SwiftUI

extension Color {
    /// Creates a color from a 6-digit RGB hex string (with or without a leading "#").
    /// Falls back to system blue if the string can't be parsed.
    init(hex: String) {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard sanitized.count == 6, Scanner(string: sanitized).scanHexInt64(&rgb) else {
            self = .blue
            return
        }

        let red = Double((rgb >> 16) & 0xFF) / 255
        let green = Double((rgb >> 8) & 0xFF) / 255
        let blue = Double(rgb & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
