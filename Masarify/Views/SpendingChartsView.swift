import Charts
import SwiftUI
import SwiftData

/// Weekly / monthly pie + bar charts and CSV/PDF export.
struct SpendingChartsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]

    @State private var period: SpendingPeriod = .week
    @State private var chartKind: ChartKind = .pie
    @State private var shareItem: ShareFileItem?
    @State private var isExporting = false
    @State private var exportError: String?

    enum ChartKind: String, CaseIterable, Identifiable {
        case pie, bar
        var id: String { rawValue }
    }

    private var periodExpenses: [Expense] {
        SpendingAnalytics.expenses(in: period, from: expenses)
    }

    private var slices: [CategorySpendSlice] {
        SpendingAnalytics.categorySlices(
            expenses: periodExpenses,
            categories: categories,
            language: settings.language
        )
    }

    private var daily: [DaySpendPoint] {
        SpendingAnalytics.dailyPoints(
            expenses: periodExpenses,
            period: period,
            language: settings.language
        )
    }

    private var total: Double {
        periodExpenses.reduce(0) { $0 + $1.amount }
    }

    private var topDrain: CategorySpendSlice? {
        SpendingAnalytics.topDrain(slices: slices)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(settings.t(.chartsSubtitle))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .padding(.top, 4)

                Picker("", selection: $period) {
                    Text(settings.t(.chartsWeek)).tag(SpendingPeriod.week)
                    Text(settings.t(.chartsMonth)).tag(SpendingPeriod.month)
                }
                .pickerStyle(.segmented)

                summaryCard

                if let topDrain, total > 0 {
                    drainCallout(topDrain)
                }

                Picker("", selection: $chartKind) {
                    Text(settings.t(.chartsPie)).tag(ChartKind.pie)
                    Text(settings.t(.chartsBar)).tag(ChartKind.bar)
                }
                .pickerStyle(.segmented)

                chartCard

                if !slices.isEmpty {
                    legendList
                }

                exportSection
            }
            .masarifyScreenInsets()
            .padding(.vertical, 20)
            .padding(.bottom, 100)
            .animation(Motion.gentle, value: period)
            .animation(Motion.gentle, value: chartKind)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(title: settings.t(.chartsTitle))
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
        .alert(
            settings.t(.exportFailed),
            isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )
        ) {
            Button(settings.t(.cancel), role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settings.t(.total))
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)
            Text(CurrencyFormat.egp(total, language: settings.language))
                .font(AppFont.display(36))
                .foregroundStyle(BrandTheme.deepTeal)
                .contentTransition(.numericText())
            Text(
                settings.language == .arabic
                    ? "\(periodExpenses.count) مصروف"
                    : "\(periodExpenses.count) expenses"
            )
            .font(AppFont.caption())
            .foregroundStyle(BrandTheme.muted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .masarifyCard(cornerRadius: 22, accent: BrandTheme.deepTeal, fillOpacity: 0.72)
    }

    private func drainCallout(_ slice: CategorySpendSlice) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(Color(hex: UInt32(slice.tintHex & 0xFFFFFF)))
            VStack(alignment: .leading, spacing: 4) {
                Text(settings.t(.chartsMoneyDrain))
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
                Text("\(slice.label) — \(CurrencyFormat.egp(slice.amount, language: settings.language)) (\(Int((slice.percent * 100).rounded()))%)")
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .masarifyCard(cornerRadius: 18, accent: Color(hex: UInt32(slice.tintHex & 0xFFFFFF)), fillOpacity: 0.55)
    }

    @ViewBuilder
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if periodExpenses.isEmpty {
                Text(settings.t(.chartsEmpty))
                    .font(AppFont.body())
                    .foregroundStyle(BrandTheme.muted)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
            } else if chartKind == .pie {
                pieChart
                    .frame(height: 240)
            } else {
                barChart
                    .frame(height: 240)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .masarifyCard(cornerRadius: 22, accent: BrandTheme.azure, fillOpacity: 0.55)
    }

    private var pieChart: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("amount", slice.amount),
                innerRadius: .ratio(0.52),
                angularInset: 1.5
            )
            .foregroundStyle(Color(hex: UInt32(slice.tintHex & 0xFFFFFF)))
            .cornerRadius(4)
        }
        .chartLegend(.hidden)
    }

    private var barChart: some View {
        Chart(daily) { point in
            BarMark(
                x: .value("day", point.label),
                y: .value("amount", point.amount)
            )
            .foregroundStyle(BrandTheme.brandGradient)
            .cornerRadius(6)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(AppFont.caption(10))
            }
        }
    }

    private var legendList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(settings.t(.categories))
                .font(AppFont.title3())
                .foregroundStyle(BrandTheme.ink)
            ForEach(slices) { slice in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: UInt32(slice.tintHex & 0xFFFFFF)))
                        .frame(width: 12, height: 12)
                    Text(slice.label)
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    Text(CurrencyFormat.egp(slice.amount, language: settings.language))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                    Text("\(Int((slice.percent * 100).rounded()))%")
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.deepTeal)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settings.t(.exportTitle))
                .font(AppFont.title3())
                .foregroundStyle(BrandTheme.ink)
            Text(settings.t(.exportHint))
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)

            HStack(spacing: 12) {
                exportButton(title: settings.t(.exportCSV), systemImage: "tablecells", format: .csv)
                exportButton(title: settings.t(.exportPDF), systemImage: "doc.richtext", format: .pdf)
            }

            if isExporting {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }

    private func exportButton(title: String, systemImage: String, format: ExpenseExportFormat) -> some View {
        Button {
            export(format)
        } label: {
            Label(title, systemImage: systemImage)
                .font(AppFont.subheadline())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(format == .csv ? BrandTheme.deepTeal : BrandTheme.azure)
        .disabled(expenses.isEmpty || isExporting)
    }

    private func export(_ format: ExpenseExportFormat) {
        isExporting = true
        exportError = nil
        do {
            // Export all expenses (full archive), not only the chart period.
            let url = try ExpenseExportService.makeFile(
                expenses: expenses,
                categories: categories,
                language: settings.language,
                format: format
            )
            shareItem = ShareFileItem(url: url)
        } catch {
            exportError = error.localizedDescription
        }
        isExporting = false
    }
}

// MARK: - Share

private struct ShareFileItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
