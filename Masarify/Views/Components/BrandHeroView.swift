import SwiftUI

/// Interactive animated balance hero — ring + remaining, taps open budgets.
struct BrandHeroView: View {
    @EnvironmentObject private var settings: AppSettings
    var todayTotal: Double = 0
    var monthRemaining: Double? = nil
    var monthLimit: Double = 0
    var onManageBudget: (() -> Void)? = nil

    @State private var appeared = false
    @State private var ringProgress: CGFloat = 0
    @State private var breathe = false
    @State private var shimmer = false

    private var hasBudget: Bool { monthLimit > 0 }

    private var remaining: Double { monthRemaining ?? 0 }

    /// Remaining fraction (1 = full budget left).
    private var remainingRatio: CGFloat {
        guard monthLimit > 0 else { return 0 }
        return CGFloat(min(1, max(0, remaining / monthLimit)))
    }

    private var isLow: Bool { hasBudget && remainingRatio < 0.2 }
    private var isTight: Bool { hasBudget && remainingRatio < 0.35 }

    var body: some View {
        Button {
            onManageBudget?()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.t(.tagline))
                            .font(AppFont.subheadline())
                            .foregroundStyle(BrandTheme.muted)
                            .multilineTextAlignment(.leading)

                        Text(settings.t(.balance))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.deepTeal.opacity(0.75))

                        if hasBudget {
                            balanceAmount
                                .padding(.top, 1)
                        }
                    }

                    Spacer(minLength: 8)

                    balanceRing
                }

                if hasBudget {
                    Text(settings.t(.balanceRemaining))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)

                    HStack(spacing: 10) {
                        statChip(
                            title: settings.t(.spentToday),
                            value: CurrencyFormat.egp(todayTotal, language: settings.language),
                            tint: BrandTheme.azure
                        )
                        statChip(
                            title: settings.t(.total),
                            value: CurrencyFormat.egp(monthLimit, language: settings.language),
                            tint: BrandTheme.lagoon
                        )
                    }
                } else {
                    Text(settings.t(.balanceNoBudget))
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(settings.t(.manageBudget))
                            .font(AppFont.headline())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(BrandTheme.brandGradient)
                    .clipShape(Capsule())
                    .shadow(color: BrandTheme.deepTeal.opacity(0.25), radius: 8, y: 3)
                }

                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(settings.language == .arabic ? "اضغط لإدارة الميزانية" : "Tap to manage budget")
                        .font(AppFont.caption())
                }
                .foregroundStyle(BrandTheme.azure.opacity(0.85))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.6)
            )
            .shadow(color: BrandTheme.deepTeal.opacity(appeared ? 0.12 : 0), radius: 18, y: 8)
            .scaleEffect(appeared ? 1 : 0.96)
            .opacity(appeared ? 1 : 0)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(settings.t(.balance))
        .accessibilityHint(settings.t(.manageBudget))
        .onAppear {
            withAnimation(Motion.softSpring) { appeared = true }
            withAnimation(Motion.barFill.delay(0.15)) {
                ringProgress = remainingRatio
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .onChange(of: remainingRatio) { _, newValue in
            withAnimation(Motion.barFill) { ringProgress = newValue }
        }
    }

    /// Number in teal/coral, currency suffix in azure (second color).
    private var balanceAmount: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(CurrencyFormat.number(remaining, language: settings.language))
                .font(AppFont.display(34))
                .foregroundStyle(isLow ? BrandTheme.coral : BrandTheme.deepTeal)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(settings.t(.currencySuffix))
                .font(AppFont.custom(.bold, size: 16))
                .foregroundStyle(isLow ? BrandTheme.ember : BrandTheme.azure)
        }
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
    }

    private var balanceRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.55), lineWidth: 10)
                .frame(width: 86, height: 86)

            Circle()
                .trim(from: 0, to: max(0.02, ringProgress))
                .stroke(
                    AngularGradient(
                        colors: isLow
                            ? [BrandTheme.coral, BrandTheme.ember]
                            : [BrandTheme.deepTeal, BrandTheme.lagoon, BrandTheme.azure, BrandTheme.deepTeal],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 86, height: 86)
                .rotationEffect(.degrees(-90))
                .shadow(color: (isLow ? BrandTheme.coral : BrandTheme.deepTeal).opacity(0.28), radius: breathe ? 8 : 4)

            VStack(spacing: 0) {
                Text("\(Int((ringProgress * 100).rounded()))%")
                    .font(AppFont.custom(.extraBold, size: 18))
                    .foregroundStyle(isLow ? BrandTheme.coral : BrandTheme.deepTeal)
                    .contentTransition(.numericText())
                Text(settings.language == .arabic ? "فاضل" : "left")
                    .font(AppFont.caption(10))
                    .foregroundStyle(BrandTheme.muted)
            }
            .scaleEffect(breathe ? 1.04 : 1.0)
        }
        .padding(4)
        .background(
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(shimmer ? 0.75 : 0.55),
                            BrandTheme.seafoam.opacity(0.35),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 52
                    )
                )
        )
    }

    private func statChip(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)
            Text(value)
                .font(AppFont.headline())
                .foregroundStyle(BrandTheme.ink)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tint.opacity(0.28), lineWidth: 1)
        )
    }

    private var panelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.52))

            LinearGradient(
                colors: [
                    BrandTheme.lagoon.opacity(shimmer ? 0.14 : 0.08),
                    Color.clear,
                    BrandTheme.azure.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            if isTight {
                LinearGradient(
                    colors: [BrandTheme.coral.opacity(0.10), Color.clear],
                    startPoint: .trailing,
                    endPoint: .leading
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }
}
