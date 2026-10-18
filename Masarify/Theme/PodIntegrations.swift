import SwiftUI
import IQKeyboardManagerSwift
import AlertToast
import Lottie

enum PodIntegrations {
    @MainActor
    static func configureAtLaunch() {
        let keyboard = IQKeyboardManager.shared
        keyboard.enable = true
        keyboard.resignOnTouchOutside = true
        // Toolbar was showing the placeholder as a floating pill and confusing amount entry.
        keyboard.enableAutoToolbar = false
        keyboard.keyboardDistanceFromTextField = 28
    }
}

/// Thin wrapper around Lottie for consistent sizing in Masarify.
struct MasarifyLottie: View {
    let name: String
    var loopMode: LottieLoopMode = .loop
    var speed: Double = 1

    var body: some View {
        LottieView(animation: .named(name))
            .playing(loopMode: loopMode)
            .animationSpeed(speed)
    }
}

extension View {
    /// Arabic-friendly success toast after saves.
    func masarifyToast(isPresented: Binding<Bool>, title: String, subtitle: String? = nil) -> some View {
        toast(isPresenting: isPresented) {
            AlertToast(
                displayMode: .banner(.pop),
                type: .complete(BrandTheme.deepTeal),
                title: title,
                subTitle: subtitle,
                style: .style(
                    backgroundColor: Color.white.opacity(0.96),
                    titleColor: BrandTheme.ink,
                    subTitleColor: BrandTheme.muted,
                    titleFont: AppFont.headline(),
                    subTitleFont: AppFont.caption()
                )
            )
        }
    }
}
