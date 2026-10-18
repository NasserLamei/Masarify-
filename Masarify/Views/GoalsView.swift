import SwiftUI
import SwiftData

struct GoalsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<SavingsGoal> { !$0.isArchived }, sort: \SavingsGoal.createdAt)
    private var goals: [SavingsGoal]

    @State private var showEditor = false
    @State private var draftTitle = ""
    @State private var draftTarget = ""
    @State private var contributeGoalID: UUID?
    @State private var contributeAmount = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                roundUpChallengeCard
                    .masarifyAppear(0)

                if goals.isEmpty {
                    MasarifyPanel {
                        Text(settings.language == .arabic
                             ? "حط هدف كبير (لابتوب، سفر…) وكل مصروف هيقولك قدهّ قربك."
                             : "Set a big goal (laptop, trip…) and every spend shows how close you are.")
                            .font(AppFont.body())
                            .foregroundStyle(BrandTheme.muted)
                    }
                } else {
                    ForEach(goals) { goal in
                        goalCard(goal)
                            .masarifyAppear(1)
                    }
                }

                Button {
                    draftTitle = ""
                    draftTarget = ""
                    showEditor = true
                } label: {
                    Label(settings.t(.addGoal), systemImage: "plus.circle.fill")
                        .font(AppFont.headline())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(BrandTheme.goalGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(PressableStyle())
            }
            .masarifyScreenInsets()
            .padding(.vertical, 16)
            .padding(.bottom, 110)
        }
        .masarifyScreenBackground()
        .masarifyLeadingTrailingChrome(
            title: settings.t(.goals),
            showVoice: false,
            showCamera: false,
            trailingExtra: AnyView(
                ToolbarCircleButton(
                    systemImage: "plus",
                    tint: BrandTheme.highlight,
                    action: { showEditor = true }
                )
                .accessibilityLabel(settings.t(.addGoal))
            )
        )
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                Form {
                    TextField(settings.language == .arabic ? "اسم الهدف" : "Goal name", text: $draftTitle)
                        .masarifyFieldFont(16)
                    MasarifyAmountField(
                        placeholder: settings.language == .arabic ? "المبلغ المستهدف" : "Target amount",
                        text: $draftTarget
                    )
                }
                .masarifyInlineTitle(settings.t(.addGoal))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        MasarifyToolbarButton(title: settings.t(.cancel)) { showEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        MasarifyToolbarButton(title: settings.t(.save), prominent: true) { saveGoal() }
                    }
                }
                .background(MasarifyChromeHost())
            }
            .environmentObject(settings)
            .environment(\.layoutDirection, settings.language.layoutDirection)
        }
        .sheet(isPresented: Binding(
            get: { contributeGoalID != nil },
            set: { if !$0 { contributeGoalID = nil } }
        )) {
            NavigationStack {
                Form {
                    MasarifyAmountField(
                        placeholder: settings.language == .arabic ? "مبلغ التحويش" : "Amount saved",
                        text: $contributeAmount
                    )
                }
                .masarifyInlineTitle(goals.first(where: { $0.id == contributeGoalID })?.title ?? settings.t(.goals))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        MasarifyToolbarButton(title: settings.t(.cancel)) { contributeGoalID = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        MasarifyToolbarButton(title: settings.t(.save), prominent: true) { applyContribution() }
                    }
                }
                .background(MasarifyChromeHost())
            }
            .environmentObject(settings)
        }
    }

    private var header: some View {
        Text(settings.t(.goalsSubtitle))
            .font(AppFont.subheadline())
            .foregroundStyle(BrandTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private var roundUpChallengeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.forward.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BrandTheme.lagoon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.t(.roundUpTitle))
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Text(settings.t(.roundUp))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                }
                Spacer()
            }

            Text(settings.t(.roundUpHint))
                .font(AppFont.subheadline())
                .foregroundStyle(BrandTheme.muted)

            Text(settings.t(.roundUpExample))
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.deepTeal)

            Toggle(isOn: $settings.roundUpEnabled) {
                Text(settings.t(.roundUpChallenge))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.ink)
            }
            .tint(BrandTheme.lagoon)

            if settings.roundUpEnabled {
                HStack {
                    Text(settings.t(.roundUpPiggy))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                    Spacer()
                    Text(CurrencyFormat.egp(settings.totalRoundUpSaved, language: settings.language))
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.deepTeal)
                }

                if goals.isEmpty {
                    Text(settings.t(.roundUpNoGoal))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.coral)
                } else {
                    Text(settings.t(.roundUpPickGoal))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                    ForEach(goals) { goal in
                        Button {
                            settings.roundUpGoalId = goal.id.uuidString
                        } label: {
                            HStack {
                                Image(systemName: isRoundUpGoal(goal) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(BrandTheme.lagoon)
                                Text(goal.title)
                                    .font(AppFont.subheadline())
                                    .foregroundStyle(BrandTheme.ink)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(BrandTheme.lagoon.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(BrandTheme.cardBorder, lineWidth: 1.6)
        )
    }

    private func isRoundUpGoal(_ goal: SavingsGoal) -> Bool {
        if let id = settings.roundUpGoalId {
            return goal.id.uuidString == id
        }
        return goal.id == goals.first?.id
    }

    private func goalCard(_ goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goal.emojiSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(BrandTheme.highlight)
                Text(goal.title)
                    .font(AppFont.title3())
                    .foregroundStyle(BrandTheme.ink)
                Spacer()
                Text("\(Int(goal.progress * 100))%")
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.deepTeal)
            }

            AnimatedProgressBar(progress: goal.progress, tint: BrandTheme.highlight)

            HStack {
                Text(CurrencyFormat.egp(goal.savedAmount, language: settings.language))
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
                Spacer()
                Text(CurrencyFormat.egp(goal.targetAmount, language: settings.language))
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.ink)
            }

            Button {
                contributeAmount = ""
                contributeGoalID = goal.id
            } label: {
                Text(settings.language == .arabic ? "حوّش لهذا الهدف" : "Add to this goal")
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.deepTeal)
            }
        }
        .padding(16)
        .masarifyCard(cornerRadius: 20, accent: BrandTheme.deepTeal, fillOpacity: 0.72)
    }

    private func saveGoal() {
        let target = Double(draftTarget.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty, target > 0 else { return }
        modelContext.insert(SavingsGoal(title: draftTitle.trimmingCharacters(in: .whitespaces), targetAmount: target))
        showEditor = false
    }

    private func applyContribution() {
        guard let id = contributeGoalID,
              let goal = goals.first(where: { $0.id == id }) else { return }
        let amount = Double(contributeAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard amount > 0 else { return }
        goal.savedAmount += amount
        contributeGoalID = nil
    }
}
