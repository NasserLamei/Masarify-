import SwiftUI
import SwiftData

/// Friendly on-device financial coach + saving challenges.
struct FinancialCoachView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var speech = CoachSpeechService.shared
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]

    @State private var pulse = false
    @State private var didAutoSpeak = false

    private var tips: [FinancialCoachService.Tip] {
        FinancialCoachService.tips(
            expenses: expenses,
            budgets: budgets,
            categories: categories,
            language: settings.language,
            activeChallenges: settings.activeChallenges
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                heroCard
                    .masarifyAppear(0)

                voiceToggleCard
                    .masarifyAppear(0)

                Text(settings.t(.coachTipsSection))
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)

                ForEach(Array(tips.prefix(4).enumerated()), id: \.element.id) { index, tip in
                    tipCard(tip)
                        .masarifyAppear(index + 1)
                }

                Text(settings.t(.coachChallengesSection))
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                    .padding(.top, 4)

                if let active = settings.activeChallenges.first {
                    activeChallengeCard(active)
                        .masarifyAppear(5)
                }

                ForEach(FinancialCoachService.ChallengeKind.allCases) { kind in
                    challengeOffer(kind)
                        .masarifyAppear(6)
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 16)
            .padding(.bottom, 100)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(title: settings.t(.coachTitle))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
            pruneFinishedChallenges()
            autoSpeakPrimaryTipIfNeeded()
        }
        .onDisappear {
            speech.stop()
        }
        .onChange(of: settings.coachVoiceEnabled) { _, enabled in
            if enabled {
                didAutoSpeak = false
                autoSpeakPrimaryTipIfNeeded()
            } else {
                speech.stop()
            }
        }
    }

    private var heroCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [BrandTheme.deepTeal, BrandTheme.lagoon],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse ? 1.05 : 0.96)

                Image(systemName: "person.wave.2.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(settings.t(.coachName))
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.deepTeal)
                Text(settings.t(.coachSubtitle))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .masarifyCard(cornerRadius: 20, accent: BrandTheme.deepTeal, fillOpacity: 0.55)
    }

    private var voiceToggleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $settings.coachVoiceEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(settings.t(.coachVoice), systemImage: "speaker.wave.2.fill")
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Text(settings.t(.coachVoiceHint))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(BrandTheme.deepTeal)

            if settings.coachVoiceEnabled, let tip = tips.first {
                Button {
                    if speech.isSpeaking {
                        speech.stop()
                    } else {
                        speech.speak(
                            title: tip.title,
                            message: tip.message,
                            language: settings.language,
                            enabled: true
                        )
                    }
                } label: {
                    HStack {
                        Image(systemName: speech.isSpeaking ? "stop.fill" : "play.fill")
                        Text(speech.isSpeaking ? settings.t(.coachStopSpeak) : settings.t(.coachSpeak))
                            .font(AppFont.headline())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(BrandTheme.deepTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .masarifyCard(cornerRadius: 18, accent: BrandTheme.azure, fillOpacity: 0.45)
    }

    private func tipCard(_ tip: FinancialCoachService.Tip) -> some View {
        let tint: Color = {
            switch tip.tone {
            case .watch: return BrandTheme.coral
            case .nudge: return BrandTheme.ember
            case .cheer: return BrandTheme.lagoon
            case .challenge: return BrandTheme.highlight
            }
        }()

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: tip.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(tip.title)
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                Text(tip.message)
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if settings.coachVoiceEnabled {
                    Button {
                        speech.speak(
                            title: tip.title,
                            message: tip.message,
                            language: settings.language,
                            enabled: true
                        )
                    } label: {
                        Label(settings.t(.coachSpeak), systemImage: "speaker.wave.2.fill")
                            .font(AppFont.caption())
                            .foregroundStyle(tint)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint.opacity(0.28), lineWidth: 1.2)
        )
    }

    private func autoSpeakPrimaryTipIfNeeded() {
        guard settings.coachVoiceEnabled, !didAutoSpeak, let tip = tips.first else { return }
        didAutoSpeak = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            speech.speak(
                title: tip.title,
                message: tip.message,
                language: settings.language,
                enabled: settings.coachVoiceEnabled
            )
        }
    }

    private func activeChallengeCard(_ challenge: FinancialCoachService.ActiveChallenge) -> some View {
        let kind = challenge.kind
        let status = FinancialCoachService.evaluate(
            challenge: challenge,
            expenses: expenses,
            roundUpTotal: settings.totalRoundUpSaved,
            language: settings.language
        )
        let accent = Color(hex: kind?.accentHex ?? 0x0C6B63)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: kind?.systemImage ?? "flag.checkered")
                    .foregroundStyle(accent)
                Text(kind?.title(settings.language) ?? settings.t(.coachChallengesSection))
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)
                Spacer()
                Button(settings.t(.coachDismissChallenge)) {
                    settings.clearChallenge(id: challenge.id)
                }
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)
            }

            switch status {
            case .active(let daysLeft, let progress):
                Text(
                    settings.language == .arabic
                        ? "فاضل \(daysLeft) يوم — كمّل يا بطل"
                        : "\(daysLeft) day(s) left — keep going"
                )
                .font(AppFont.subheadline())
                .foregroundStyle(BrandTheme.muted)
                AnimatedProgressBar(progress: progress, tint: accent)

            case .won:
                Text(settings.t(.coachChallengeWon))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.lagoon)

            case .failed(let reason):
                Text(reason)
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.coral)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(accent.opacity(0.3), lineWidth: 1.2)
        )
    }

    private func challengeOffer(_ kind: FinancialCoachService.ChallengeKind) -> some View {
        let accent = Color(hex: kind.accentHex)
        let isCurrent = settings.activeChallenges.first?.kind == kind

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: kind.systemImage)
                    .foregroundStyle(accent)
                    .frame(width: 36, height: 36)
                    .background(accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title(settings.language))
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                    Text(kind.detail(settings.language))
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                settings.startChallenge(kind)
            } label: {
                Text(isCurrent ? settings.t(.coachChallengeActive) : settings.t(.coachStartChallenge))
                    .font(AppFont.headline())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PressableStyle())
            .disabled(isCurrent)
            .opacity(isCurrent ? 0.55 : 1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .masarifyCard(cornerRadius: 18, accent: accent, fillOpacity: 0.45)
    }

    private func pruneFinishedChallenges() {
        // Keep won/failed visible until user dismisses; no auto-prune.
    }
}
