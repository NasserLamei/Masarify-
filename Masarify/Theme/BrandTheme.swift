import SwiftUI
import UIKit

enum BrandTheme {
    /// Wider leading / trailing content inset (user requested larger margins).
    static let screenInset: CGFloat = 32

    // Same Masarify teal family
    static let deepTeal = Color(hex: 0x0C6B63)
    static let azure = Color(hex: 0x1A7A9C)
    static let lagoon = Color(hex: 0x14948F)
    static let highlight = Color(hex: 0xE8A317)
    static let coral = Color(hex: 0xD94F3D)
    static let ember = Color(hex: 0xC45C26)

    static let ink = Color(light: 0x0A1C20, dark: 0xE8F5F2)
    static let muted = Color(light: 0x5B6C71, dark: 0x98ADB2)
    static let foam = Color(light: 0xF3F8F6, dark: 0x081214)
    static let seafoam = Color(light: 0xD2EBE4, dark: 0x123033)
    static let mist = Color(light: 0xE4F0F3, dark: 0x0E2428)
    static let sand = Color(light: 0xE7EEE8, dark: 0x162628)
    static let surface = Color(light: 0xFFFFFF, dark: 0x122024)
    static let glass = Color(light: 0xFFFFFF, dark: 0x152426)
    /// Stronger brand stroke for creative card borders.
    static let stroke = Color(light: 0x0C6B63, dark: 0x3FA8A4).opacity(0.42)

    /// Teal → lagoon → azure border used on cards.
    static var cardBorder: LinearGradient {
        LinearGradient(
            colors: [
                deepTeal.opacity(0.75),
                lagoon.opacity(0.65),
                azure.opacity(0.70),
                deepTeal.opacity(0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(light: 0xD4EDEA, dark: 0x14363A).opacity(0.92),
                Color(light: 0xC8E2EC, dark: 0x184450).opacity(0.88),
                Color(light: 0xBFE0D2, dark: 0x1A4A40).opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [deepTeal, lagoon, azure],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var emergencyGradient: LinearGradient {
        LinearGradient(
            colors: [coral, ember],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var goalGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xC9891A), highlight, Color(hex: 0xE8C35A)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Soft wash — readable UI over abstract teal wallpaper.
    static var atmosphereScrim: LinearGradient {
        LinearGradient(
            colors: [
                foam.opacity(0.35),
                Color.white.opacity(0.18),
                seafoam.opacity(0.22),
                mist.opacity(0.30)
            ],
            startPoint: .top,
            endPoint: .bottom
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

    init(light: UInt32, dark: UInt32) {
        self.init(
            uiColor: UIColor { traits in
                let hex = traits.userInterfaceStyle == .dark ? dark : light
                let r = CGFloat((hex >> 16) & 0xFF) / 255
                let g = CGFloat((hex >> 8) & 0xFF) / 255
                let b = CGFloat(hex & 0xFF) / 255
                return UIColor(red: r, green: g, blue: b, alpha: 1)
            }
        )
    }
}

enum CurrencyFormat {
    static func number(_ value: Double, language: AppLanguage = .arabic) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        // Always 0–9 even when app language is Arabic.
        formatter.locale = AppLanguage.latinDigitsLocale
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func egp(_ value: Double, language: AppLanguage = .arabic) -> String {
        let number = number(value, language: language)
        let suffix = L10n.string(.currencySuffix, language: language)
        return "\(number) \(suffix)"
    }
}

enum WesternDigits {
    /// Maps Eastern Arabic / Persian digits to ASCII 0–9.
    static func normalize(_ string: String) -> String {
        let map: [Character: Character] = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
            "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
            "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9",
            "٫": ".", "٬": ",",
            "،": "." // Arabic comma sometimes used as decimal
        ]
        return String(string.map { map[$0] ?? $0 })
    }
}

/// Clean light panel used across screens — creative brand gradient border.
struct MasarifyPanel<Content: View>: View {
    var tint: Color = BrandTheme.deepTeal
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .masarifyCard(cornerRadius: cornerRadius, accent: tint)
    }
}

struct MasarifyCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var accent: Color = BrandTheme.deepTeal
    var fillOpacity: Double = 0.62

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(BrandTheme.glass.opacity(fillOpacity))
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.85),
                            BrandTheme.lagoon.opacity(0.65),
                            BrandTheme.azure.opacity(0.75),
                            accent.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.6
                )
            )
            .shadow(color: accent.opacity(0.08), radius: 10, y: 4)
    }
}

extension View {
    /// Shared creative card chrome with app-color border.
    func masarifyCard(cornerRadius: CGFloat = 20, accent: Color = BrandTheme.deepTeal, fillOpacity: Double = 0.62) -> some View {
        modifier(MasarifyCardModifier(cornerRadius: cornerRadius, accent: accent, fillOpacity: fillOpacity))
    }
}
