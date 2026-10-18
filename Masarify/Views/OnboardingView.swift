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
                    .padding(.top, 10)

                // Middle band: true vertical center for art + copy
                GeometryReader { geo in
                    let width = geo.size.width
                    ZStack {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                            OnboardingPageView(page: item, isActive: page == index)
                                .frame(width: width, height: geo.size.height)
                                .offset(x: CGFloat(index - page) * width + dragOffset)
                        }
                    }
                    .frame(width: width, height: geo.size.height, alignment: .center)
                    .clipped()
                    .gesture(pageDrag(width: width))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                pageDots
                    .padding(.top, 8)
                    .padding(.bottom, 14)

                primaryButton
                    .padding(.horizontal, BrandTheme.screenInset)
                    .padding(.bottom, 22)
            }
            .safeAreaPadding(.top, 4)
            .safeAreaPadding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
                orbPhase = true
            }
        }
    }

    private func pageDrag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                // RTL: swipe right advances in Arabic layout feel; keep LTR math and flip by layout
                let dx = settings.language == .arabic ? -value.translation.width : value.translation.width
                dragOffset = dx
            }
            .onEnded { value in
                let dx = settings.language == .arabic ? -value.translation.width : value.translation.width
                let threshold = width * 0.22
                withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
                    if dx < -threshold, page < pages.count - 1 {
                        page += 1
                    } else if dx > threshold, page > 0 {
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
                .opacity(0.18)
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
    }

    private var primaryButton: some View {
        let isLast = page == pages.count - 1
        return Button {
            if isLast {
                finish()
            } else {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) { page += 1 }
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
        .animation(.easeInOut(duration: 0.35), value: page)
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

    var body: some View {
        // Equal spacers = true vertical center of art + copy as one block
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 20) {
                artStage
                    .frame(maxWidth: 300)
                    .frame(height: 210)
                    .scaleEffect(entered ? 1 : 0.78)
                    .opacity(entered ? 1 : 0)

                VStack(spacing: 10) {
                    Text(settings.t(.appName))
                        .font(AppFont.brand(32))
                        .foregroundStyle(page.accent)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .opacity(entered ? 1 : 0)
                        .offset(y: entered ? 0 : 16)

                    Text(settings.t(page.titleKey))
                        .font(AppFont.display(24))
                        .foregroundStyle(BrandTheme.ink)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)
                        .opacity(entered ? 1 : 0)
                        .offset(y: entered ? 0 : 18)

                    Text(settings.t(page.bodyKey))
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                        .opacity(entered ? 1 : 0)
                        .offset(y: entered ? 0 : 20)
                }
                .padding(.horizontal, BrandTheme.screenInset)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .frame(width: ring ? 200 : 80, height: ring ? 200 : 80)
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
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: page.accent.opacity(0.35), radius: 16, y: 8)
                .scaleEffect(bob ? 1.05 : 0.96)
                .rotationEffect(.degrees(bob ? 2 : -2))

            orbitChip("EGP", angle: spin)
            orbitChip("−85", angle: spin + 120)
            orbitChip("ميزانية", angle: spin + 240)
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

            orbitChip("مصاصة", angle: spin)
            orbitChip("أسبوعي", angle: spin + 180)
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
        let radius: CGFloat = 86
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
