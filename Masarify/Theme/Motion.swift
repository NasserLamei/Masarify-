import SwiftUI
import UIKit

enum Motion {
    static let softSpring = Animation.spring(response: 0.55, dampingFraction: 0.82)
    static let snappy = Animation.spring(response: 0.38, dampingFraction: 0.78)
    static let gentle = Animation.easeOut(duration: 0.45)
    static let barFill = Animation.spring(response: 0.85, dampingFraction: 0.78)

    static func stagger(index: Int, base: Double = 0.06) -> Animation {
        softSpring.delay(Double(index) * base)
    }
}

/// Brand wallpaper from `SplashBackground` — one continuous full-window layer with alpha.
struct ScreenAtmosphere: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var shimmer = false

    /// Pattern alpha: readable brand texture without fighting UI.
    private var patternAlpha: Double {
        colorScheme == .dark ? 0.42 : 0.55
    }

    var body: some View {
        // Global-aligned so any sheet copy still matches the root wallpaper (no seams).
        GeometryReader { geo in
            let global = geo.frame(in: .global)
            let screen = UIScreen.main.bounds

            ZStack {
                LinearGradient(
                    colors: [
                        BrandTheme.foam,
                        BrandTheme.seafoam.opacity(0.9),
                        BrandTheme.mist
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image("SplashBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screen.width, height: screen.height)
                    .opacity(patternAlpha)
                    .offset(x: -global.minX, y: -global.minY)

                RadialGradient(
                    colors: [
                        BrandTheme.highlight.opacity(shimmer ? 0.08 : 0.03),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 10,
                    endRadius: 380
                )
                .blendMode(.softLight)
                .offset(x: -global.minX, y: -global.minY)
                .frame(width: screen.width, height: screen.height)

                BrandTheme.atmosphereScrim

                if colorScheme == .dark {
                    Color.black.opacity(0.28)
                }
            }
            .frame(width: screen.width, height: screen.height)
            .offset(x: -global.minX, y: -global.minY)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .animation(Motion.gentle, value: colorScheme)
    }
}

struct AppearMotion: ViewModifier {
    var index: Int = 0
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 18)
            .scaleEffect(shown ? 1 : 0.97)
            .onAppear {
                withAnimation(Motion.stagger(index: index)) {
                    shown = true
                }
            }
    }
}

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.58), value: configuration.isPressed)
    }
}

struct AnimatedProgressBar: View {
    var progress: Double
    var tint: Color
    @State private var widthFactor: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(tint.opacity(0.14))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.75)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geo.size.width * widthFactor))
                }
        }
        .frame(height: 10)
        .onAppear {
            withAnimation(Motion.barFill) {
                widthFactor = CGFloat(min(max(progress, 0), 1))
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(Motion.barFill) {
                widthFactor = CGFloat(min(max(newValue, 0), 1))
            }
        }
    }
}

extension View {
    func masarifyAppear(_ index: Int = 0) -> some View {
        modifier(AppearMotion(index: index))
    }

    /// Keeps content transparent so the single root `ScreenAtmosphere` shows through.
    /// Sheets still get their own atmosphere via `presentationBackground`.
    func masarifyScreenBackground() -> some View {
        background(Color.clear)
            .toolbarBackground(.hidden, for: .navigationBar)
            .presentationBackground { ScreenAtmosphere() }
    }

    /// Shared screen leading / trailing inset (content + headers share this).
    func masarifyScreenInsets() -> some View {
        padding(.horizontal, BrandTheme.screenInset)
    }

    /// Lists / scroll content that should match the same edge insets.
    func masarifyListInsets() -> some View {
        contentMargins(.horizontal, BrandTheme.screenInset, for: .scrollContent)
    }

    /// Voice on **leading**, Camera on **trailing** via custom header (same insets as content).
    func masarifyLeadingTrailingChrome(
        title: String,
        showVoice: Bool = true,
        showCamera: Bool = true,
        leadingExtra: AnyView? = nil,
        trailingExtra: AnyView? = nil
    ) -> some View {
        modifier(
            MasarifyRootHeaderChrome(
                title: title,
                showVoice: showVoice,
                showCamera: showCamera,
                leadingExtra: leadingExtra,
                trailingExtra: trailingExtra
            )
        )
    }

    /// Pushed screens: custom header with back + optional trailing (same leading/trailing inset).
    func masarifyPushedChrome(title: String, trailing: AnyView? = nil) -> some View {
        modifier(MasarifyPushedChrome(title: title, trailing: trailing))
    }
}

/// Root-tab header chrome — hides system nav, uses shared inset header.
private struct MasarifyRootHeaderChrome: ViewModifier {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.onVoiceCapture) private var onVoice
    @Environment(\.onCameraCapture) private var onCamera
    let title: String
    var showVoice: Bool = true
    var showCamera: Bool = true
    var leadingExtra: AnyView? = nil
    var trailingExtra: AnyView? = nil

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                MasarifyCustomHeader(title: title) {
                    HStack(spacing: 8) {
                        if showVoice {
                            ToolbarCircleButton(
                                systemImage: "mic.fill",
                                tint: BrandTheme.deepTeal,
                                action: onVoice
                            )
                            .accessibilityLabel(settings.t(.voiceCaptureA11y))
                        }
                        if let leadingExtra { leadingExtra }
                    }
                } trailing: {
                    HStack(spacing: 8) {
                        if let trailingExtra { trailingExtra }
                        if showCamera {
                            ToolbarCircleButton(
                                systemImage: "camera.fill",
                                tint: BrandTheme.azure,
                                action: onCamera
                            )
                            .accessibilityLabel(settings.t(.cameraCaptureA11y))
                        }
                    }
                }
            }
            .background(MasarifyChromeHost())
            .onAppear {
                AppAppearance.apply()
                DispatchQueue.main.async { AppAppearance.refreshLiveChrome() }
            }
    }
}

/// Back + optional trailing for NavigationLink destinations (custom header, shared insets).
struct MasarifyPushedChrome: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    let title: String
    var trailing: AnyView? = nil

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .safeAreaInset(edge: .top, spacing: 0) {
                MasarifyCustomHeader(title: title) {
                    ToolbarCircleButton(
                        systemImage: "chevron.backward",
                        tint: BrandTheme.deepTeal,
                        action: { dismiss() }
                    )
                    .accessibilityLabel("رجوع")
                } trailing: {
                    if let trailing {
                        trailing
                    } else {
                        Color.clear.frame(width: 44, height: 44)
                    }
                }
            }
            .background(MasarifyChromeHost())
            .onAppear {
                AppAppearance.apply()
                DispatchQueue.main.async { AppAppearance.refreshLiveChrome() }
            }
    }
}

/// Soft ring header button — tint icon on seafoam disc, spring + bounce on tap.
struct ToolbarCircleButton: View {
    let systemImage: String
    var tint: Color = BrandTheme.deepTeal
    let action: () -> Void
    @State private var bounce = false
    @State private var appeared = false

    var body: some View {
        Button {
            bounce.toggle()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .symbolEffect(.bounce, value: bounce)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(BrandTheme.surface)
                        .overlay(Circle().fill(tint.opacity(0.10)))
                        .overlay(Circle().strokeBorder(tint.opacity(0.32), lineWidth: 1.4))
                }
                .shadow(color: tint.opacity(0.16), radius: bounce ? 10 : 5, y: 2)
                .scaleEffect(appeared ? 1 : 0.82)
                .opacity(appeared ? 1 : 0)
        }
        .buttonStyle(PressableStyle(scale: 0.88))
        .onAppear {
            withAnimation(Motion.softSpring.delay(0.05)) { appeared = true }
        }
    }
}

/// Legacy name → ring button.
struct ToolbarActionChip: View {
    let title: String
    let systemImage: String
    var tint: Color = BrandTheme.deepTeal
    var filled: Bool = true
    let action: () -> Void

    var body: some View {
        ToolbarCircleButton(systemImage: systemImage, tint: tint, action: action)
            .accessibilityLabel(title)
    }
}

/// Text action for custom headers (Cancel / Save) — min width, Cairo, animated.
struct MasarifyHeaderTextButton: View {
    let title: String
    var prominent: Bool = false
    let action: () -> Void
    @State private var bounce = false
    @State private var appeared = false

    var body: some View {
        Button {
            bounce.toggle()
            action()
        } label: {
            Text(title)
                .font(AppFont.custom(prominent ? .bold : .medium, size: 15))
                .foregroundStyle(prominent ? Color.white : BrandTheme.deepTeal)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(minWidth: 80)
                .background {
                    Capsule()
                        .fill(prominent ? BrandTheme.deepTeal : BrandTheme.surface)
                }
                .overlay(
                    Capsule().strokeBorder(
                        BrandTheme.deepTeal.opacity(prominent ? 0 : 0.28),
                        lineWidth: 1.2
                    )
                )
                .shadow(color: BrandTheme.deepTeal.opacity(prominent ? 0.22 : 0.08), radius: 6, y: 2)
                .scaleEffect(appeared ? (bounce ? 1.05 : 1) : 0.9)
                .opacity(appeared ? 1 : 0)
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .animation(Motion.snappy, value: bounce)
        .onAppear {
            withAnimation(Motion.softSpring.delay(0.05)) { appeared = true }
        }
    }
}

/// Custom top bar — leading/trailing match `BrandTheme.screenInset` like all content.
struct MasarifyCustomHeader<Leading: View, Trailing: View>: View {
    let title: String
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            leading()
                .frame(minWidth: 88, alignment: .leading)

            Text(title)
                .font(AppFont.custom(.bold, size: 18))
                .foregroundStyle(BrandTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)

            trailing()
                .frame(minWidth: 88, alignment: .trailing)
        }
        .padding(.horizontal, BrandTheme.screenInset)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background {
            BrandTheme.surface.opacity(0.88)
                .background(.ultraThinMaterial)
                .shadow(color: BrandTheme.ink.opacity(0.06), radius: 8, y: 3)
                .ignoresSafeArea(edges: .top)
        }
    }
}

extension MasarifyCustomHeader where Leading == EmptyView, Trailing == EmptyView {
    init(title: String) {
        self.title = title
        self.leading = { EmptyView() }
        self.trailing = { EmptyView() }
    }
}

private struct VoiceActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct CameraActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var onVoiceCapture: () -> Void {
        get { self[VoiceActionKey.self] }
        set { self[VoiceActionKey.self] = newValue }
    }

    var onCameraCapture: () -> Void {
        get { self[CameraActionKey.self] }
        set { self[CameraActionKey.self] = newValue }
    }
}

