import SwiftUI

enum BrandTheme {
    static let ink = Color(hex: 0x0B1F24)
    static let deepTeal = Color(hex: 0x0A5C5A)
    static let azure = Color(hex: 0x0B6E99)
    static let mist = Color(hex: 0xE7F0F5)
    static let seafoam = Color(hex: 0xD7EBE6)
    static let foam = Color(hex: 0xF4FAF8)
    static let muted = Color(hex: 0x5B6B70)

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                mist,
                seafoam,
                Color(hex: 0xC9E4EF)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [deepTeal, azure],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

enum CurrencyFormat {
    static func egp(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        formatter.locale = Locale(identifier: "ar_EG")
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(number) ج.م"
    }
}
