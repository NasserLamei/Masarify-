import SwiftUI

/// Cairo helpers for the widget extension (fonts ship via UIAppFonts).
enum WidgetFont {
    static func cairo(_ name: String, size: CGFloat) -> Font {
        .custom(name, size: size)
    }

    static func regular(_ size: CGFloat) -> Font { cairo("Cairo-Regular", size: size) }
    static func medium(_ size: CGFloat) -> Font { cairo("Cairo-Medium", size: size) }
    static func bold(_ size: CGFloat) -> Font { cairo("Cairo-Bold", size: size) }
    static func extraBold(_ size: CGFloat) -> Font { cairo("Cairo-ExtraBold", size: size) }
}

enum WidgetBrand {
    static let deepTeal = Color(red: 0.047, green: 0.420, blue: 0.388)
    static let lagoon = Color(red: 0.078, green: 0.580, blue: 0.561)
    static let azure = Color(red: 0.102, green: 0.478, blue: 0.612)
    static let coral = Color(red: 0.851, green: 0.310, blue: 0.239)
    static let highlight = Color(red: 0.910, green: 0.639, blue: 0.090)
    static let foam = Color(red: 0.953, green: 0.973, blue: 0.965)
    static let ink = Color(red: 0.039, green: 0.110, blue: 0.125)

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

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [deepTeal, lagoon, azure],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Matches in-app `ScreenAtmosphere` — money wallpaper + teal wash.
struct WidgetAtmosphere: View {
    var intense: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    WidgetBrand.foam,
                    Color(red: 0.82, green: 0.92, blue: 0.89),
                    Color(red: 0.89, green: 0.94, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image("AppBackground")
                .resizable()
                .scaledToFill()
                .opacity(intense ? 0.58 : 0.48)
                .clipped()

            // Soft brand bloom for depth
            RadialGradient(
                colors: [
                    WidgetBrand.highlight.opacity(0.10),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 4,
                endRadius: 140
            )

            LinearGradient(
                colors: [
                    WidgetBrand.foam.opacity(0.50),
                    Color.white.opacity(0.22),
                    WidgetBrand.lagoon.opacity(0.14),
                    WidgetBrand.foam.opacity(0.40)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct WidgetCardChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Inset stroke so the brand border isn't clipped by the widget mask.
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(WidgetBrand.cardBorder, lineWidth: 1.4)
                    .padding(2)
            )
    }
}

extension View {
    func widgetCardChrome() -> some View {
        modifier(WidgetCardChrome())
    }
}
