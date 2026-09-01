import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

enum DrevosTheme {
    static let background = Color.black
    static let panel = Color(hex: 0x1A1A1A)
    static let panel2 = Color(hex: 0x202020)
    static let border = Color(hex: 0x3B3B3B)
    static let orange = Color(hex: 0xFF5A1F)
    static let selected = Color(hex: 0x2A1B16)
    static let text = Color(hex: 0xF2F2F2)
    static let muted = Color(hex: 0x9B9B9B)
    static let danger = Color(hex: 0xE05252)
}
