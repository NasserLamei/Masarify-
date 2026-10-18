import SwiftUI
import SwiftData

struct VoicePlanView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    @Query private var goals: [SavingsGoal]

    @StateObject private var recognizer = SpeechRecognizer()
    @State private var plan: VoicePlanResult?
    @State private var pulse = false
    @State private var appliedMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(settings.t(.voicePlanHint))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .padding(.top, 4)

                Button {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                    recognizer.toggleRecording()
                    if !recognizer.isRecording {
                        pulse = false
                        parseCurrent()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(BrandTheme.azure.opacity(0.15))
                            .frame(width: pulse && recognizer.isRecording ? 140 : 120, height: pulse && recognizer.isRecording ? 140 : 120)
                        Circle()
                            .fill(BrandTheme.brandGradient)
                            .frame(width: 88, height: 88)
                        Image(systemName: recognizer.isRecording ? "stop.fill" : "waveform")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                Text(recognizer.statusMessage)
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
                    .frame(maxWidth: .infinity)

                if !recognizer.transcript.isEmpty {
                    Text(recognizer.transcript)
                        .font(AppFont.body())
                        .foregroundStyle(BrandTheme.ink)
                        .padding(BrandTheme.screenInset)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BrandTheme.surface.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                HStack(spacing: 10) {
                    Button {
                        plan = VoicePlanParser.mock(categories: categories)
                        recognizer.transcript = VoicePlanParser.mockTranscript
                    } label: {
                        Label(settings.language == .arabic ? "تجربة" : "Demo", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(BrandTheme.azure)

                    Button {
                        parseCurrent()
                    } label: {
                        Label(settings.language == .arabic ? "تحليل" : "Parse", systemImage: "brain.head.profile")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandTheme.deepTeal)
                    .disabled(recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let plan {
                    planCard(plan)
                }

                if let appliedMessage {
                    Text(appliedMessage)
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.deepTeal)
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 16)
        }
        .masarifyScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            MasarifyCustomHeader(title: settings.t(.voicePlan)) {
                MasarifyHeaderTextButton(title: settings.t(.cancel)) { dismiss() }
            } trailing: {
                Color.clear.frame(width: 80, height: 44)
            }
        }
        .background(MasarifyChromeHost())
    }

    private func planCard(_ plan: VoicePlanResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let income = plan.income {
                labeled(settings.t(.income), CurrencyFormat.egp(income, language: settings.language))
            }
            ForEach(plan.allocations.filter { !$0.isSavings }) { item in
                labeled(item.note, CurrencyFormat.egp(item.amount, language: settings.language))
            }
            if plan.savingsAmount > 0 {
                labeled(settings.t(.savings), CurrencyFormat.egp(plan.savingsAmount, language: settings.language))
            }

            Button {
                apply(plan)
            } label: {
                Text(settings.t(.applyPlan))
                    .font(AppFont.headline())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(BrandTheme.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressableStyle())
        }
        .padding(BrandTheme.screenInset)
        .background(BrandTheme.surface.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(AppFont.body())
                .foregroundStyle(BrandTheme.muted)
            Spacer()
            Text(value)
                .font(AppFont.headline())
                .foregroundStyle(BrandTheme.ink)
        }
    }

    private func parseCurrent() {
        let text = recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        plan = VoicePlanParser.parse(text, categories: categories)
    }

    private func apply(_ plan: VoicePlanResult) {
        let month = MonthlyBudget.currentMonthKey()
        if let income = plan.income, income > 0 {
            let existing = (try? modelContext.fetch(FetchDescriptor<MonthlyBudget>())) ?? []
            if let overall = existing.first(where: { $0.monthKey == month && $0.categoryId == nil }) {
                overall.limitAmount = income
                overall.updatedAt = .now
            } else {
                modelContext.insert(MonthlyBudget(monthKey: month, categoryId: nil, limitAmount: income))
            }
        }

        for item in plan.allocations where !item.isSavings {
            let categoryId = item.categoryId ?? BuiltInCategory.other.rawValue
            modelContext.insert(
                Expense(
                    amount: item.amount,
                    categoryId: categoryId,
                    note: item.note,
                    date: .now,
                    source: .voice
                )
            )
            if let existing = ((try? modelContext.fetch(FetchDescriptor<MonthlyBudget>())) ?? [])
                .first(where: { $0.monthKey == month && $0.categoryId == categoryId }) {
                existing.limitAmount = item.amount
                existing.updatedAt = .now
            } else {
                modelContext.insert(MonthlyBudget(monthKey: month, categoryId: categoryId, limitAmount: item.amount))
            }
        }

        if plan.savingsAmount > 0 {
            if let goal = goals.first(where: { !$0.isArchived }) {
                goal.savedAmount += plan.savingsAmount
            } else {
                modelContext.insert(
                    SavingsGoal(
                        title: settings.language == .arabic ? "تحويش" : "Savings",
                        targetAmount: max(plan.savingsAmount * 3, plan.savingsAmount),
                        savedAmount: plan.savingsAmount
                    )
                )
            }
        }

        try? modelContext.save()
        appliedMessage = settings.language == .arabic
            ? "تم تطبيق الخطة: ميزانيات + مصروفات + تحويش."
            : "Plan applied: budgets + expenses + savings."
    }
}
