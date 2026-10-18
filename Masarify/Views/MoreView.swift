import SwiftUI

/// Hub tab that hosts Settings and secondary tools.
struct MoreView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var appeared = false

    private var summaryDetail: String {
        if !settings.dailySummaryEnabled {
            return settings.t(.dailySummaryHint)
        }
        let formatter = DateFormatter()
        formatter.locale = settings.language.locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let time = formatter.string(from: settings.dailySummaryTime)
        let dayLabel: String = {
            switch settings.dailySummaryFocusDay {
            case .today: return settings.t(.filterToday)
            case .yesterday: return settings.t(.yesterday)
            }
        }()
        return settings.language == .arabic
            ? "مفعّل — \(dayLabel) · \(time)"
            : "On — \(dayLabel) · \(time)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(settings.t(.moreSubtitle))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                    .masarifyAppear(0)

                NavigationLink {
                    SettingsView()
                } label: {
                    moreRow(
                        title: settings.t(.settings),
                        detail: settings.language == .arabic
                            ? "اللغة، المظهر، وعن التطبيق"
                            : "Language, appearance, and about",
                        systemImage: "gearshape.fill",
                        tint: BrandTheme.deepTeal
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(1)

                NavigationLink {
                    PrivacySecurityView()
                } label: {
                    moreRow(
                        title: settings.t(.privacyTitle),
                        detail: settings.t(.privacySubtitle),
                        systemImage: "lock.shield.fill",
                        tint: BrandTheme.coral
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(2)

                NavigationLink {
                    FinancialCoachView()
                } label: {
                    moreRow(
                        title: settings.t(.coachTitle),
                        detail: settings.t(.coachSubtitle),
                        systemImage: "person.wave.2.fill",
                        tint: BrandTheme.deepTeal
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(3)

                NavigationLink {
                    DebtLoanView()
                } label: {
                    moreRow(
                        title: settings.t(.debtTitle),
                        detail: settings.t(.debtHint),
                        systemImage: "person.2.fill",
                        tint: BrandTheme.highlight
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(3)

                NavigationLink {
                    PredictiveCashFlowView()
                } label: {
                    moreRow(
                        title: settings.t(.cashFlowTitle),
                        detail: settings.t(.cashFlowHint),
                        systemImage: "calendar.badge.exclamationmark",
                        tint: BrandTheme.coral
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(3)

                NavigationLink {
                    SmartShoppingView()
                } label: {
                    moreRow(
                        title: settings.t(.shopTipsTitle),
                        detail: settings.t(.shopTipsHint),
                        systemImage: "cart.fill",
                        tint: BrandTheme.azure
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(3)

                NavigationLink {
                    DailySummarySettingsView()
                } label: {
                    moreRow(
                        title: settings.t(.dailySummary),
                        detail: summaryDetail,
                        systemImage: "bell.badge.fill",
                        tint: BrandTheme.lagoon
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(3)

                NavigationLink {
                    TrueCostSettingsView()
                } label: {
                    moreRow(
                        title: settings.t(.trueCost),
                        detail: settings.t(.trueCostHint),
                        systemImage: "clock.badge.exclamationmark.fill",
                        tint: BrandTheme.coral
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(4)

                NavigationLink {
                    CategoriesView()
                } label: {
                    moreRow(
                        title: settings.t(.categories),
                        detail: settings.language == .arabic
                            ? "إدارة الفئات والألوان"
                            : "Manage categories & colors",
                        systemImage: "folder.fill",
                        tint: BrandTheme.lagoon
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(5)

                NavigationLink {
                    BudgetsView()
                } label: {
                    moreRow(
                        title: settings.t(.budgets),
                        detail: settings.t(.manageBudget),
                        systemImage: "chart.pie.fill",
                        tint: BrandTheme.azure
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(6)

                NavigationLink {
                    SpendingChartsView()
                } label: {
                    moreRow(
                        title: settings.t(.chartsTitle),
                        detail: settings.t(.exportHint),
                        systemImage: "chart.bar.xaxis",
                        tint: BrandTheme.deepTeal
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(7)

                NavigationLink {
                    TripModeView()
                } label: {
                    moreRow(
                        title: settings.t(.tripMode),
                        detail: settings.t(.tripHint),
                        systemImage: "airplane",
                        tint: BrandTheme.azure
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(8)

                NavigationLink {
                    EmergencyModeView()
                } label: {
                    moreRow(
                        title: settings.t(.emergency),
                        detail: settings.t(.emergencyHint),
                        systemImage: "lifepreserver.fill",
                        tint: BrandTheme.coral
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(9)

                NavigationLink {
                    VoicePlanView()
                } label: {
                    moreRow(
                        title: settings.t(.voicePlan),
                        detail: settings.t(.voicePlanHint),
                        systemImage: "waveform",
                        tint: BrandTheme.highlight
                    )
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(10)
            }
            .masarifyScreenInsets()
            .padding(.top, 8)
            .padding(.bottom, 120)
            .opacity(appeared ? 1 : 0)
        }
        .masarifyScreenBackground()
        .masarifyLeadingTrailingChrome(
            title: settings.t(.tabMore),
            showVoice: false,
            showCamera: false
        )
        .onAppear {
            withAnimation(Motion.gentle) { appeared = true }
        }
    }

    private func moreRow(title: String, detail: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 46, height: 46)
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                    .multilineTextAlignment(.leading)
                Text(detail)
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.forward")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandTheme.muted.opacity(0.7))
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .masarifyCard(cornerRadius: 18, accent: tint, fillOpacity: 0.55)
    }
}
