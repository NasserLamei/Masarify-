import SwiftUI

/// First-install benefit carousel — 4 colorful animated pages.
struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    var onFinished: () -> Void

    @State private var page = 0
    @State private var appeared = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            accent: BrandTheme.deepTeal,
            secondary: BrandTheme.lagoon,
            symbol: "banknote.fill",
            titleKey: .onboard1Title,
            bodyKey: .onboard1Body,
            art: .welcome
        ),
        OnboardingPage(
            accent: BrandTheme.azure,
            secondary: BrandTheme.deepTeal,
            symbol: "mic.fill",
            titleKey: .onboard2Title,
            bodyKey: .onboard2Body,
            art: .capture
        ),
        OnboardingPage(
            accent: BrandTheme.highlight,
            secondary: BrandTheme.ember,
            symbol: "chart.pie.fill",
            titleKey: .onboard3Title,
            bodyKey: .onboard3Body,
            art: .insights
        ),
        OnboardingPage(
            accent: BrandTheme.coral,
            secondary: BrandTheme.lagoon,
            symbol: "lock.shield.fill",
            titleKey: .onboard4Title,
            bodyKey: .onboard4Body,
            art: .secure
        )
    ]

    var body: some View {
        ZStack {
            animatedBackdrop

            VStack(spacing: 0) {
                HStack {
                    languageChip
                    Spacer()
                    if page < pages.count - 1 {
                        Button(settings.t(.onboardSkip)) { finish() }
                            .font(AppFont.subheadline())
                            .foregroundStyle(BrandTheme.ink.opacity(0.72))
                    }
                }
                .padding(.horizontal, BrandTheme.screenInset)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingPageView(page: item, isActive: page == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(Motion.softSpring, value: page)

                pageDots
                    .padding(.bottom, 18)

                primaryButton
                    .padding(.horizontal, BrandTheme.screenInset)
                    .padding(.bottom, 28)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            withAnimation(Motion.softSpring) { appeared = true }
        }
    }

    private var animatedBackdrop: some View {
        let current = pages[safe: page] ?? pages[0]
        return ZStack {
            LinearGradient(
                colors: [
                    current.accent.opacity(0.28),
                    BrandTheme.foam,
                    current.secondary.opacity(0.22),
                    BrandTheme.mist
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(Motion.gentle, value: page)

            Image("AppBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.35)
                .allowsHitTesting(false)

            Circle()
                .fill(current.accent.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(x: appeared ? -90 : -40, y: appeared ? -220 : -160)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: appeared)

            Circle()
                .fill(current.secondary.opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 36)
                .offset(x: appeared ? 110 : 60, y: appeared ? 260 : 200)
                .animation(.easeInOut(duration: 5.2).repeatForever(autoreverses: true), value: appeared)
        }
    }

    private var languageChip: some View {
        Button {
            withAnimation(Motion.snappy) {
                settings.language = settings.language == .arabic ? .english : .arabic
            }
        } label: {
            Text(settings.language == .arabic ? "EN" : "عربي")
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.deepTeal)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BrandTheme.surface.opacity(0.92))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(BrandTheme.deepTeal.opacity(0.28), lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == page ? pages[index].accent : BrandTheme.ink.opacity(0.18))
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .animation(Motion.snappy, value: page)
            }
        }
    }

    private var primaryButton: some View {
        let isLast = page == pages.count - 1
        return Button {
            if isLast {
                finish()
            } else {
                withAnimation(Motion.softSpring) { page += 1 }
            }
        } label: {
            Text(isLast ? settings.t(.onboardStart) : settings.t(.onboardNext))
                .font(AppFont.headline())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [pages[page].accent, pages[page].secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: pages[page].accent.opacity(0.35), radius: 14, y: 6)
        }
        .buttonStyle(PressableStyle())
    }

    private func finish() {
        settings.hasCompletedOnboarding = true
        withAnimation(Motion.gentle) { onFinished() }
    }
}

private struct OnboardingPage: Identifiable {
    enum Art { case welcome, capture, insights, secure }
    let id = UUID()
    let accent: Color
    let secondary: Color
    let symbol: String
    let titleKey: L10n.Key
    let bodyKey: L10n.Key
    let art: Art
}

private struct OnboardingPageView: View {
    @EnvironmentObject private var settings: AppSettings
    let page: OnboardingPage
    let isActive: Bool

    @State private var pulse = false
    @State private var float = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)

            artStage
                .frame(height: 280)
                .opacity(isActive ? 1 : 0.55)
                .scaleEffect(isActive ? 1 : 0.94)
                .animation(Motion.softSpring, value: isActive)

            VStack(spacing: 12) {
                Text(settings.t(.appName))
                    .font(AppFont.brand(34))
                    .foregroundStyle(page.accent)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text(settings.t(page.titleKey))
                    .font(AppFont.display(26))
                    .foregroundStyle(BrandTheme.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)

                Text(settings.t(page.bodyKey))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, BrandTheme.screenInset)

            Spacer()
        }
        .onAppear { startMotion() }
        .onChange(of: isActive) { _, active in
            if active { startMotion() }
        }
    }

    @ViewBuilder
    private var artStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            page.accent.opacity(0.22),
                            page.secondary.opacity(0.16),
                            BrandTheme.surface.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .strokeBorder(page.accent.opacity(0.35), lineWidth: 1.4)
                )
                .padding(.horizontal, BrandTheme.screenInset)
                .scaleEffect(pulse ? 1.02 : 1)
                .shadow(color: page.accent.opacity(0.2), radius: 20, y: 10)

            switch page.art {
            case .welcome:
                welcomeArt
            case .capture:
                captureArt
            case .insights:
                insightsArt
            case .secure:
                secureArt
            }
        }
    }

    private var welcomeArt: some View {
        ZStack {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 118, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: page.accent.opacity(0.35), radius: 18, y: 10)
                .offset(y: float ? -8 : 6)

            floatingChip("EGP", x: -110, y: -70)
            floatingChip("−85", x: 108, y: -40)
            floatingChip("ميزانية", x: -90, y: 88)
        }
    }

    private var captureArt: some View {
        HStack(spacing: 28) {
            symbolBubble("mic.fill", tint: BrandTheme.deepTeal)
                .offset(y: float ? -10 : 8)
            symbolBubble("camera.fill", tint: BrandTheme.azure)
                .offset(y: float ? 10 : -8)
        }
    }

    private var insightsArt: some View {
        ZStack {
            symbolBubble("chart.pie.fill", tint: page.accent, size: 88)
                .offset(y: float ? -6 : 6)
            floatingChip("مصاصة", x: 100, y: -70)
            floatingChip("أسبوعي", x: -105, y: 70)
        }
    }

    private var secureArt: some View {
        ZStack {
            symbolBubble("faceid", tint: page.accent, size: 88)
                .offset(y: float ? -8 : 6)
            floatingChip("iCloud", x: -100, y: -60)
            floatingChip("Face ID", x: 95, y: 75)
        }
    }

    private func symbolBubble(_ name: String, tint: Color, size: CGFloat = 76) -> some View {
        Image(systemName: name)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [tint, tint.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(Circle())
            .shadow(color: tint.opacity(0.35), radius: 14, y: 8)
            .scaleEffect(pulse ? 1.06 : 1)
    }

    private func floatingChip(_ text: String, x: CGFloat, y: CGFloat) -> some View {
        Text(text)
            .font(AppFont.caption())
            .foregroundStyle(BrandTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(BrandTheme.surface.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(page.accent.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: page.accent.opacity(0.16), radius: 8, y: 4)
            .offset(x: x, y: y + (float ? -6 : 4))
    }

    private func startMotion() {
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            float = true
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
