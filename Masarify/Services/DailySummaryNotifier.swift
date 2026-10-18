import Foundation
import UserNotifications
import UIKit

/// Schedules a local summary for today/yesterday spend at a user-chosen time.
enum DailySummaryNotifier {
    static let requestId = "masarify.dailySummary"

    static let presentationDelegate = PresentationDelegate()

    /// Call once at launch so banners show even while the app is open.
    static func configureAtLaunch() {
        UNUserNotificationCenter.current().delegate = presentationDelegate
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        if status == .authorized || status == .provisional { return true }
        if status == .denied { return false }
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    static func refreshSchedule(
        enabled: Bool,
        hour: Int,
        minute: Int = 0,
        language: AppLanguage,
        bodyProvider: @escaping () -> (title: String, body: String)
    ) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestId, "masarify.dailySummary.test"])
        guard enabled else { return }

        Task {
            let granted = await requestAuthorization()
            guard granted else { return }

            let content = UNMutableNotificationContent()
            let copy = bodyProvider()
            content.title = copy.title
            content.body = copy.body
            content.sound = .default
            content.userInfo = ["deepLink": "masarify://report"]

            var comps = DateComponents()
            comps.hour = max(0, min(23, hour))
            comps.minute = max(0, min(59, minute))

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    static func rescheduleFromSnapshot(
        enabled: Bool,
        hour: Int,
        minute: Int = 0,
        snapshot: DailySummarySnapshot,
        focusDay: DailySummaryFocusDay,
        language: AppLanguage
    ) {
        refreshSchedule(enabled: enabled, hour: hour, minute: minute, language: language) {
            (
                snapshot.notificationTitle(language: language, focusDay: focusDay),
                snapshot.notificationBody(language: language, focusDay: focusDay)
            )
        }
    }

    static func nextFireDescription(hour: Int, minute: Int, language: AppLanguage) -> String {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let cal = Calendar.current
        let now = Date()
        guard let today = cal.nextDate(
            after: now.addingTimeInterval(-1),
            matching: comps,
            matchingPolicy: .nextTime
        ) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let time = formatter.string(from: today)
        let isToday = cal.isDateInToday(today)
        if language == .arabic {
            return isToday ? "الجدولة: النهارده الساعة \(time)" : "الجدولة: بكرة الساعة \(time)"
        }
        return isToday ? "Scheduled: today at \(time)" : "Scheduled: tomorrow at \(time)"
    }

    final class PresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification
        ) async -> UNNotificationPresentationOptions {
            [.banner, .sound, .list]
        }

        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse
        ) async {
            if let link = response.notification.request.content.userInfo["deepLink"] as? String,
               let url = URL(string: link) {
                await MainActor.run {
                    NotificationCenter.default.post(name: .masarifyOpenReport, object: nil)
                    _ = url
                }
            } else {
                await MainActor.run {
                    NotificationCenter.default.post(name: .masarifyOpenReport, object: nil)
                }
            }
        }
    }
}
