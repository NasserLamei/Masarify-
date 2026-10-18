import SwiftUI
import SwiftData

struct InsightsHubView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    @State private var showEmergency = false
    @State private var showBudgets = false
    @State private var showVoicePlan = false
    @State private var showTrip = false
    @State private var showDailyReport = false
    @State private var showCharts = false
    @Query(filter: #Predicate<Trip> { $0.isActive }) private var activeTrips: [Trip]

    private var peaks: [PeakInsight] {
        SpendingInsightsService.peakInsights(expenses: expenses, language: settings.language)
    }

    private var compares: [SelfCompareInsight] {
        SelfBenchmarkService.compare(expenses: expenses, categories: categories, language: settings.language)
    }

    private var ghosts: [GhostSubscription] {
        GhostSubscriptionHunter.detect(
            expenses: expenses,
            categories: categories,
            language: settings.language,
            dismissedIds: Set(settings.dismissedGhostIds)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                featureRow

                section(title: settings.t(.chartsTitle), icon: "chart.pie.fill") {
                    Button { showCharts = true } label: {
                        insightRow(
                            title: settings.t(.chartsTitle),
                            detail: settings.t(.chartsSubtitle),
                            image: "chart.bar.xaxis",
                            tint: BrandTheme.deepTeal
                        )
                    }
                    .buttonStyle(.plain)
                }

                section(title: settings.t(.roundUp), icon: "arrow.up.forward.circle.fill") {
                    featureToggleCard(
                        title: settings.t(.roundUpTitle),
                        detail: settings.roundUpEnabled
                            ? "\(settings.t(.roundUpPiggy)): \(CurrencyFormat.egp(settings.totalRoundUpSaved, language: settings.language)) — \(settings.t(.roundUpExample))"
                            : settings.t(.roundUpHint),
                        image: "banknote.fill",
                        tint: BrandTheme.lagoon,
                        isOn: $settings.roundUpEnabled
                    )
                }

                section(title: settings.t(.trueCost), icon: "clock.badge.exclamationmark.fill") {
                    featureToggleCard(
                        title: settings.t(.trueCostTitle),
                        detail: settings.trueCostEnabled
                            ? (
                                settings.language == .arabic
                                    ? "ساعة شغلك ≈ \(CurrencyFormat.egp(settings.hourlyRate, language: .arabic)). أي رفاهية أو مصروف كبير هيتحول لساعات شغل."
                                    : "Your hour ≈ \(CurrencyFormat.egp(settings.hourlyRate, language: .english)). Luxury or big spends convert to work hours."
                              )
                            : settings.t(.trueCostHint),
                        image: "hourglass",
                        tint: BrandTheme.coral,
                        isOn: $settings.trueCostEnabled
                    )
                }

                section(title: settings.t(.ghostHunter), icon: "sparkles") {
                    featureToggleCard(
                        title: settings.t(.ghostHunterTitle),
                        detail: settings.t(.ghostHunterHint),
                        image: "eye.trianglebadge.exclamationmark",
                        tint: BrandTheme.azure,
                        isOn: $settings.ghostHunterEnabled
                    )

                    if settings.ghostHunterEnabled {
                        if ghosts.isEmpty {
                            insightRow(
                                title: settings.t(.ghostHunterEmpty),
                                detail: settings.t(.ghostHunterHint),
                                image: "checkmark.seal",
                                tint: BrandTheme.lagoon
                            )
                        } else {
                            ForEach(ghosts) { ghost in
                                ghostCard(ghost)
                            }
                        }
                    }
                }

                section(title: settings.t(.tripMode), icon: "airplane") {
                    Button { showTrip = true } label: {
                        insightRow(
                            title: activeTrips.first?.title ?? settings.t(.tripMode),
                            detail: activeTrips.first != nil
                                ? settings.t(.tripActive) + " — " + settings.t(.tripSeparated)
                                : settings.t(.tripHint),
                            image: "airplane.departure",
                            tint: BrandTheme.azure
                        )
                    }
                    .buttonStyle(.plain)
                }

                section(title: settings.t(.peakTime), icon: "clock.badge.exclamationmark") {
                    ForEach(peaks) { insight in
                        insightRow(title: insight.title, detail: insight.detail, image: insight.systemImage, tint: BrandTheme.azure)
                    }
                }

                section(title: settings.t(.selfCompare), icon: "figure.walk.motion") {
                    ForEach(compares) { insight in
                        insightRow(
                            title: insight.title,
                            detail: insight.detail,
                            image: insight.systemImage,
                            tint: insight.improved ? BrandTheme.deepTeal : BrandTheme.coral
                        )
                    }
                }
            }
            .masarifyScreenInsets()
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .masarifyScreenBackground()
        .masarifyLeadingTrailingChrome(title: settings.t(.insights))
        .sheet(isPresented: $showEmergency) {
            NavigationStack { EmergencyModeView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showBudgets) {
            NavigationStack { BudgetsView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showVoicePlan) {
            NavigationStack { VoicePlanView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showTrip) {
            NavigationStack { TripModeView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showDailyReport) {
            NavigationStack { DailyReportView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: $showCharts) {
            NavigationStack { SpendingChartsView() }
                .environmentObject(settings)
                .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .onReceive(NotificationCenter.default.publisher(for: .masarifyOpenReport)) { _ in
            showDailyReport = true
        }
    }

    private var header: some View {
        Text(settings.t(.insightsSubtitle))
            .font(AppFont.subheadline())
            .foregroundStyle(BrandTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private var featureRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settings.t(.features))
                .font(AppFont.title3())
                .foregroundStyle(BrandTheme.ink)

            HStack(spacing: 10) {
                featureChip(settings.t(.emergency), "lifepreserver.fill", BrandTheme.coral) {
                    showEmergency = true
                }
                featureChip(settings.t(.voicePlan), "waveform", BrandTheme.azure) {
                    showVoicePlan = true
                }
                featureChip(settings.t(.openBudgets), "chart.pie.fill", BrandTheme.deepTeal) {
                    showBudgets = true
                }
            }
            HStack(spacing: 10) {
                featureChip(settings.t(.tripMode), "airplane", BrandTheme.azure) {
                    showTrip = true
                }
                featureChip(settings.t(.todayReport), "sun.max.fill", BrandTheme.lagoon) {
                    showDailyReport = true
                }
                featureChip(settings.t(.chartsTitle), "chart.pie.fill", BrandTheme.deepTeal) {
                    showCharts = true
                }
            }
        }
    }

    private func featureChip(_ title: String, _ image: String, _ tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: image)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(AppFont.caption())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }

    private func section<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(AppFont.title3())
                .foregroundStyle(BrandTheme.ink)
            content()
        }
    }

    private func ghostCard(_ ghost: GhostSubscription) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: ghost.systemImage)
                    .foregroundStyle(BrandTheme.azure)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(ghost.label)
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Text(ghost.report(language: settings.language))
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.muted)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button {
                    settings.dismissGhost(ghost.id)
                } label: {
                    Text(settings.t(.ghostKeep))
                        .font(AppFont.subheadline())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(BrandTheme.glass.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.2)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    settings.dismissGhost(ghost.id)
                } label: {
                    Text(settings.t(.ghostRemove))
                        .font(AppFont.subheadline())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(BrandTheme.brandGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .masarifyCard(cornerRadius: 18, accent: BrandTheme.azure, fillOpacity: 0.55)
    }

    private func insightRow(title: String, detail: String, image: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: image)
                .foregroundStyle(tint)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                Text(detail)
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .masarifyCard(cornerRadius: 18, accent: tint, fillOpacity: 0.55)
    }

    private func featureToggleCard(
        title: String,
        detail: String,
        image: String,
        tint: Color,
        isOn: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: image)
                    .foregroundStyle(tint)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Text(detail)
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.muted)
                }
                Spacer(minLength: 0)
            }

            Toggle(isOn: isOn) {
                Text(isOn.wrappedValue
                      ? (settings.language == .arabic ? "مفعّل" : "On")
                      : (settings.language == .arabic ? "إيقاف" : "Off"))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.ink)
            }
            .tint(tint)
        }
        .padding(16)
        .masarifyCard(cornerRadius: 18, accent: tint, fillOpacity: 0.55)
    }
}
