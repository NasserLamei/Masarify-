import SwiftUI
import UIKit

/// Tajawal (OFL) — Arabic + Latin display/body family for Masarify.
enum AppFont {
    static let family = "Tajawal"

    enum Weight {
        case regular
        case medium
        case bold
        case extraBold

        var postScriptName: String {
            switch self {
            case .regular: return "Tajawal-Regular"
            case .medium: return "Tajawal-Medium"
            case .bold: return "Tajawal-Bold"
            case .extraBold: return "Tajawal-ExtraBold"
            }
        }

        var uiFontWeight: UIFont.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .bold: return .bold
            case .extraBold: return .heavy
            }
        }
    }

    static func custom(_ weight: Weight, size: CGFloat) -> Font {
        .custom(weight.postScriptName, size: size)
    }

    static func ui(_ weight: Weight, size: CGFloat) -> UIFont {
        if let font = UIFont(name: weight.postScriptName, size: size) {
            return font
        }
        // Fallback while fonts register / for previews
        return .systemFont(ofSize: size, weight: weight.uiFontWeight)
    }

    static func display(_ size: CGFloat = 40) -> Font { custom(.extraBold, size: size) }
    static func brand(_ size: CGFloat = 44) -> Font { custom(.extraBold, size: size) }
    static func title(_ size: CGFloat = 28) -> Font { custom(.bold, size: size) }
    static func title2(_ size: CGFloat = 22) -> Font { custom(.bold, size: size) }
    static func title3(_ size: CGFloat = 18) -> Font { custom(.medium, size: size) }
    static func headline(_ size: CGFloat = 17) -> Font { custom(.medium, size: size) }
    static func body(_ size: CGFloat = 16) -> Font { custom(.regular, size: size) }
    static func subheadline(_ size: CGFloat = 14) -> Font { custom(.regular, size: size) }
    static func caption(_ size: CGFloat = 12) -> Font { custom(.medium, size: size) }
    static func footnote(_ size: CGFloat = 13) -> Font { custom(.regular, size: size) }
}

extension View {
    func masarifyFont(_ weight: AppFont.Weight, size: CGFloat) -> some View {
        font(AppFont.custom(weight, size: size))
    }
}
