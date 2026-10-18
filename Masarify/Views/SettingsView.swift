import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                settingsPanel(
                    title: settings.t(.language),
                    icon: "globe"
                ) {
                    VStack(spacing: 10) {
                        ForEach(AppLanguage.allCases) { lang in
                            languageRow(lang)
                        }
                    }
                }
                .masarifyAppear(1)

                settingsPanel(
                    title: settings.t(.appearance),
                    icon: "moon.stars.fill"
                ) {
                    Toggle(isOn: $settings.isDarkMode) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.t(.darkTheme))
                                .font(AppFont.headline())
                                .foregroundStyle(BrandTheme.ink)
                            Text(settings.t(.darkThemeHint))
                                .font(AppFont.caption())
                                .foregroundStyle(BrandTheme.muted)
                        }
                    }
                    .tint(BrandTheme.deepTeal)
                }
                .masarifyAppear(2)

                settingsPanel(
                    title: settings.t(.about),
                    icon: "info.circle.fill"
                ) {
                    HStack {
                        Text(settings.t(.version))
                            .font(AppFont.body())
                            .foregroundStyle(BrandTheme.muted)
                        Spacer()
                        Text("1.0")
                            .font(AppFont.headline())
                            .foregroundStyle(BrandTheme.ink)
                    }
                }
                .masarifyAppear(3)
            }
            .masarifyScreenInsets()
            .padding(.top, 8)
            .padding(.bottom, 120)
            .opacity(appeared ? 1 : 0)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(title: settings.t(.settings))
        .onAppear {
            withAnimation(Motion.gentle) { appeared = true }
        }
    }

    private var header: some View {
        Text(
            settings.language == .arabic
                ? "اللغة، المظهر، وعن التطبيق."
                : "Language, appearance, and about."
        )
            .font(AppFont.subheadline())
            .foregroundStyle(BrandTheme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .masarifyAppear(0)
    }

    private func settingsPanel<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text(title)
                    .font(AppFont.title3())
                    .foregroundStyle(BrandTheme.ink)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(BrandTheme.deepTeal)
            }

            content()
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .masarifyCard(cornerRadius: 18, accent: BrandTheme.deepTeal, fillOpacity: 0.72)
        }
    }

    private func languageRow(_ lang: AppLanguage) -> some View {
        let selected = settings.language == lang
        return Button {
            withAnimation(Motion.snappy) {
                settings.language = lang
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(selected ? BrandTheme.deepTeal : BrandTheme.muted.opacity(0.5))

                Text(lang == .arabic ? settings.t(.languageArabic) : settings.t(.languageEnglish))
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.ink)

                Spacer()

                Text(lang.displayNameFallback)
                    .font(AppFont.caption())
                    .foregroundStyle(BrandTheme.muted)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension AppLanguage {
    var displayNameFallback: String {
        switch self {
        case .arabic: "AR"
        case .english: "EN"
        }
    }
}
