import SwiftUI

/// Guided in-app journey after first-install onboarding.
struct FeatureTourOverlay: View {
    @EnvironmentObject private var settings: AppSettings
    @Binding var stepIndex: Int
    var onSelectTab: (RootTabView.Tab) -> Void
    var onFinished: () -> Void

    private var steps: [TourStep] {
        [
            TourStep(tab: .home, accent: BrandTheme.deepTeal, symbol: "house.fill", title: .tour1Title, body: .tour1Body),
            TourStep(tab: .home, accent: BrandTheme.lagoon, symbol: "mic.fill", title: .tour2Title, body: .tour2Body),
            TourStep(tab: .home, accent: BrandTheme.azure, symbol: "camera.fill", title: .tour3Title, body: .tour3Body),
            TourStep(tab: .insights, accent: BrandTheme.highlight, symbol: "chart.pie.fill", title: .tour4Title, body: .tour4Body),
            TourStep(tab: .goals, accent: BrandTheme.ember, symbol: "flag.fill", title: .tour5Title, body: .tour5Body),
            TourStep(tab: .more, accent: BrandTheme.coral, symbol: "ellipsis.circle.fill", title: .tour6Title, body: .tour6Body)
        ]
    }

    var body: some View {
        let step = steps[min(stepIndex, steps.count - 1)]
        let isLast = stepIndex >= steps.count - 1

        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()
                .allowsHitTesting(true)

            VStack {
                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: step.symbol)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                LinearGradient(
                                    colors: [step.accent, step.accent.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(stepIndex + 1) / \(steps.count)")
                                .font(AppFont.caption())
                                .foregroundStyle(BrandTheme.muted)
                            Text(settings.t(step.title))
                                .font(AppFont.headline())
                                .foregroundStyle(BrandTheme.ink)
                        }
                        Spacer(minLength: 0)
                    }

                    Text(settings.t(step.body))
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    progressBar

                    HStack(spacing: 12) {
                        Button(settings.t(.tourSkip)) { finish() }
                            .font(AppFont.subheadline())
                            .foregroundStyle(BrandTheme.muted)
                            .frame(maxWidth: .infinity)

                        Button {
                            advance(isLast: isLast)
                        } label: {
                            Text(isLast ? settings.t(.tourDone) : settings.t(.tourNext))
                                .font(AppFont.headline())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(step.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(20)
                .background(BrandTheme.surface.opacity(0.97))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(step.accent.opacity(0.35), lineWidth: 1.4)
                )
                .shadow(color: step.accent.opacity(0.25), radius: 24, y: 10)
                .padding(.horizontal, BrandTheme.screenInset)
                .padding(.bottom, 110)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .id(stepIndex)
            }
        }
        .onAppear { onSelectTab(step.tab) }
        .onChange(of: stepIndex) { _, newValue in
            guard steps.indices.contains(newValue) else { return }
            withAnimation(Motion.softSpring) {
                onSelectTab(steps[newValue].tab)
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(BrandTheme.ink.opacity(0.08))
                Capsule()
                    .fill(steps[min(stepIndex, steps.count - 1)].accent)
                    .frame(width: geo.size.width * CGFloat(stepIndex + 1) / CGFloat(steps.count))
                    .animation(Motion.barFill, value: stepIndex)
            }
        }
        .frame(height: 6)
    }

    private func advance(isLast: Bool) {
        if isLast {
            finish()
        } else {
            withAnimation(Motion.softSpring) { stepIndex += 1 }
        }
    }

    private func finish() {
        settings.hasCompletedFeatureTour = true
        onSelectTab(.home)
        withAnimation(Motion.gentle) { onFinished() }
    }
}

private struct TourStep {
    let tab: RootTabView.Tab
    let accent: Color
    let symbol: String
    let title: L10n.Key
    let body: L10n.Key
}
