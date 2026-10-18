import SwiftUI

/// First-install benefit carousel — 4 colorful animated pages.
struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    var onFinished: () -> Void

    @State private var page = 0
    @State private var orbPhase = false
    @State private var dragOffset: CGFloat = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            accent: BrandTheme.deepTeal,
            secondary: BrandTheme.lagoon,
            titleKey: .onboard1Title,
            bodyKey: .onboard1Body,
            art: .welcome
        ),
        OnboardingPage(
            accent: BrandTheme.azure,
            secondary: BrandTheme.deepTeal,
            titleKey: .onboard2Title,
            bodyKey: .onboard2Body,
            art: .capture
        ),
        OnboardingPage(
            accent: BrandTheme.highlight,
            secondary: BrandTheme.ember,
            titleKey: .onboard3Title,
            bodyKey: .onboard3Body,
            art: .insights
        ),
        OnboardingPage(
            accent: BrandTheme.coral,
            secondary: BrandTheme.lagoon,
            titleKey: .onboard4Title,
            bodyKey: .onboard4Body,
            art: .secure
        )
    ]

    var body: some View {
        ZStack {
            BrandTheme.foam.ignoresSafeArea()
            animatedBackdrop

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, BrandTheme.screenInset)
                    .padding(.top, 8)

                // Pages fill leftover space; each page centers its own block.
                GeometryReader { geo in
                    let width = geo.size.width
                    ZStack {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                            OnboardingPageView(page: item, isActive: page == index)
                                .frame(width: width, height: geo.size.height)
                                .offset(x: pageOffset(for: index, width: width))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(pageDrag(width: width))
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomChrome
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
                orbPhase = true
            }
        }
    }

    private var bottomChrome: some View {
        VStack(spacing: 14) {
            pageDots

            Button {
                if page == pages.count - 1 {
                    finish()
                } else {
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) { page += 1 }
                }
            } label: {
                Text(page == pages.count - 1 ? settings.t(.onboardStart) : settings.t(.onboardNext))
                    .font(AppFont.headline())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [pages[page].accent, pages[page].secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .shadow(color: pages[page].accent.opacity(0.32), radius: 12, y: 5)
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal, BrandTheme.screenInset)
            .animation(.easeInOut(duration: 0.3), value: page)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(BrandTheme.foam.opacity(0.001)) // keep safe-area layout stable
    }

    private func pageOffset(for index: Int, width: CGFloat) -> CGFloat {
        let dir: CGFloat = settings.language == .arabic ? -1 : 1
        return dir * (CGFloat(index - page) * width) + dragOffset
    }

    private func pageDrag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let dir: CGFloat = settings.language == .arabic ? -1 : 1
                let progress = dir * value.translation.width
                let threshold = width * 0.2
                withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
                    if progress < -threshold, page < pages.count - 1 {
                        page += 1
                    } else if progress > threshold, page > 0 {
                        page -= 1
                    }
                    dragOffset = 0
                }
            }
    }

    private var topBar: some View {
        HStack {
            languageChip
            Spacer()
            if page < pages.count - 1 {
                Button(settings.t(.onboardSkip)) { finish() }
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.ink.opacity(0.72))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(BrandTheme.surface.opacity(0.92))
                    .clipShape(Capsule())
            }
        }
    }

    private var animatedBackdrop: some View {
        let current = pages[safe: page] ?? pages[0]
        return ZStack {
            LinearGradient(
                colors: [
                    BrandTheme.foam,
                    current.accent.opacity(0.30),
                    BrandTheme.seafoam,
                    current.secondary.opacity(0.24),
                    BrandTheme.mist
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.55), value: page)

            Image("AppBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.50)
                .scaleEffect(orbPhase ? 1.05 : 1.0)
                .allowsHitTesting(false)

            Circle()
                .fill(current.accent.opacity(0.26))
                .frame(width: 300, height: 300)
                .blur(radius: 48)
                .offset(x: orbPhase ? -70 : 40, y: orbPhase ? -180 : -120)

            Circle()
                .fill(current.secondary.opacity(0.20))
                .frame(width: 240, height: 240)
                .blur(radius: 42)
                .offset(x: orbPhase ? 90 : -20, y: orbPhase ? 220 : 160)
        }
        .allowsHitTesting(false)
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
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
            }
        }
        .frame(maxWidth: .infinity)
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
    let titleKey: L10n.Key
    let bodyKey: L10n.Key
    let art: Art
}

private struct OnboardingPageView: View {
    @EnvironmentObject private var settings: AppSettings
    let page: OnboardingPage
    let isActive: Bool

    @State private var entered = false
    @State private var spin: Double = 0
    @State private var bob = false
    @State private var ring = false

    private var chipBudget: String {
        settings.language == .arabic ? "ميزانية" : "Budget"
    }
    private var chipWeek: String {
        settings.t(.chartsWeek)
    }
    private var chipTop: String {
        settings.language == .arabic ? "أعلى بند" : "Top spend"
    }

    var body: some View {
        VStack(spacing: 18) {
            artStage
                .frame(height: 200)
                .frame(maxWidth: 300)
                .scaleEffect(entered ? 1 : 0.82)
                .opacity(entered ? 1 : 0)

            VStack(spacing: 10) {
                Text(settings.t(.appName))
                    .font(AppFont.brand(32))
                    .foregroundStyle(page.accent)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text(settings.t(page.titleKey))
                    .font(AppFont.display(24))
                    .foregroundStyle(BrandTheme.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)

                Text(settings.t(page.bodyKey))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, BrandTheme.screenInset)
            .opacity(entered ? 1 : 0)
            .offset(y: entered ? 0 : 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear { playEntrance() }
        .onChange(of: isActive) { _, active in
            if active { playEntrance() }
        }
    }

    @ViewBuilder
    private var artStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            page.accent.opacity(0.20),
                            page.secondary.opacity(0.14),
                            BrandTheme.surface.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(page.accent.opacity(0.32), lineWidth: 1.4)
                )
                .shadow(color: page.accent.opacity(0.18), radius: 18, y: 8)

            Circle()
                .stroke(page.accent.opacity(ring ? 0.0 : 0.35), lineWidth: 2)
                .frame(width: ring ? 190 : 72, height: ring ? 190 : 72)
                .animation(.easeOut(duration: 2.2).repeatForever(autoreverses: false), value: ring)

            switch page.art {
            case .welcome: welcomeArt
            case .capture: captureArt
            case .insights: insightsArt
            case .secure: secureArt
            }
        }
        .padding(.horizontal, BrandTheme.screenInset)
    }

    private var welcomeArt: some View {
        ZStack {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: page.accent.opacity(0.35), radius: 14, y: 7)
                .scaleEffect(bob ? 1.05 : 0.96)
                .rotationEffect(.degrees(bob ? 2 : -2))

            orbitChip("EGP", angle: spin)
            orbitChip("−85", angle: spin + 120)
            orbitChip(chipBudget, angle: spin + 240)
        }
    }

    private var captureArt: some View {
        HStack(spacing: 36) {
            symbolBubble("mic.fill", tint: BrandTheme.deepTeal)
                .scaleEffect(bob ? 1.08 : 0.94)
                .offset(y: bob ? -12 : 8)
            symbolBubble("camera.fill", tint: BrandTheme.azure)
                .scaleEffect(bob ? 0.94 : 1.08)
                .offset(y: bob ? 10 : -10)
        }
    }

    private var insightsArt: some View {
        ZStack {
            symbolBubble("chart.pie.fill", tint: page.accent, size: 88)
                .rotationEffect(.degrees(spin * 0.15))
                .scaleEffect(bob ? 1.06 : 0.96)

            orbitChip(chipTop, angle: spin)
            orbitChip(chipWeek, angle: spin + 180)
        }
    }

    private var secureArt: some View {
        ZStack {
            symbolBubble("faceid", tint: page.accent, size: 88)
                .scaleEffect(bob ? 1.08 : 0.95)

            orbitChip("iCloud", angle: spin + 40)
            orbitChip("Face ID", angle: spin + 220)
        }
    }

    private func symbolBubble(_ name: String, tint: Color, size: CGFloat = 76) -> some View {
        Image(systemName: name)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(.white)
            .symbolEffect(.bounce, options: .repeating.speed(0.35), value: bob)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [tint, tint.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(Circle())
            .shadow(color: tint.opacity(0.35), radius: 12, y: 6)
    }

    private func orbitChip(_ text: String, angle: Double) -> some View {
        let radians = angle * .pi / 180
        let radius: CGFloat = 82
        return Text(text)
            .font(AppFont.caption())
            .foregroundStyle(BrandTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(BrandTheme.surface.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(page.accent.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: page.accent.opacity(0.14), radius: 6, y: 3)
            .offset(x: CGFloat(cos(radians)) * radius, y: CGFloat(sin(radians)) * radius)
    }

    private func playEntrance() {
        entered = false
        ring = false
        bob = false
        spin = 0

        withAnimation(.spring(response: 0.62, dampingFraction: 0.78).delay(0.05)) {
            entered = true
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            spin = 360
        }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.2)) {
            bob = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            ring = true
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
