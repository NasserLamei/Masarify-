import SwiftUI
import UserNotifications

struct DailySummarySettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(settings.t(.dailySummaryHint))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $settings.dailySummaryEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.t(.dailySummaryTitle))
                                .font(AppFont.headline())
                                .foregroundStyle(BrandTheme.ink)
                            Text(permissionCaption)
                                .font(AppFont.caption())
                                .foregroundStyle(
                                    authStatus == .denied ? BrandTheme.coral : BrandTheme.muted
                                )
                        }
                    }
                    .tint(BrandTheme.deepTeal)
                    .onChange(of: settings.dailySummaryEnabled) { _, enabled in
                        Task {
                            if enabled {
                                _ = await DailySummaryNotifier.requestAuthorization()
                                await refreshAuthStatus()
                            }
                            NotificationCenter.default.post(name: .masarifyRefreshDailySummary, object: nil)
                        }
                    }

                    if authStatus == .denied {
                        Button(settings.t(.openNotificationSettings)) {
                            DailySummaryNotifier.openSystemSettings()
                        }
                        .font(AppFont.subheadline())
                        .foregroundStyle(BrandTheme.deepTeal)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .masarifyCard(cornerRadius: 18, accent: BrandTheme.deepTeal, fillOpacity: 0.55)

                if settings.dailySummaryEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(settings.t(.dailySummaryDay))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)

                        Picker("", selection: focusDayBinding) {
                            Text(settings.t(.filterToday)).tag(DailySummaryFocusDay.today)
                            Text(settings.t(.yesterday)).tag(DailySummaryFocusDay.yesterday)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .masarifyCard(cornerRadius: 18, accent: BrandTheme.lagoon, fillOpacity: 0.45)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(settings.t(.dailySummaryHour))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)

                        DatePicker(
                            "",
                            selection: timeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .environment(\.layoutDirection, .leftToRight)

                        Text(formattedTime)
                            .font(AppFont.headline())
                            .foregroundStyle(BrandTheme.deepTeal)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Text(
                            DailySummaryNotifier.nextFireDescription(
                                hour: settings.dailySummaryHour,
                                minute: settings.dailySummaryMinute,
                                language: settings.language
                            )
                        )
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .masarifyCard(cornerRadius: 18, accent: BrandTheme.azure, fillOpacity: 0.5)
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 20)
            .padding(.bottom, 100)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(title: settings.t(.dailySummary))
        .task {
            await refreshAuthStatus()
            if settings.dailySummaryEnabled {
                NotificationCenter.default.post(name: .masarifyRefreshDailySummary, object: nil)
            }
        }
    }

    private var permissionCaption: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral:
            return settings.t(.notificationsAllowed)
        case .denied:
            return settings.t(.notificationsDenied)
        default:
            return settings.t(.dailySummaryHint)
        }
    }

    private var focusDayBinding: Binding<DailySummaryFocusDay> {
        Binding(
            get: { settings.dailySummaryFocusDay },
            set: { newValue in
                settings.dailySummaryFocusDay = newValue
                NotificationCenter.default.post(name: .masarifyRefreshDailySummary, object: nil)
            }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: { settings.dailySummaryTime },
            set: { newValue in
                settings.dailySummaryTime = newValue
                NotificationCenter.default.post(name: .masarifyRefreshDailySummary, object: nil)
            }
        )
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = settings.language.locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: settings.dailySummaryTime)
    }

    private func refreshAuthStatus() async {
        authStatus = await DailySummaryNotifier.authorizationStatus()
    }
}
