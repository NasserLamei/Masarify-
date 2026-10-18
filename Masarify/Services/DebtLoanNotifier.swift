import Foundation
import UserNotifications

enum DebtLoanNotifier {
    static func requestId(for id: UUID) -> String { "masarify.debt.\(id.uuidString)" }

    static func refresh(for item: DebtLoan, language: AppLanguage) {
        let center = UNUserNotificationCenter.current()
        let id = requestId(for: item.id)
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard item.reminderEnabled, !item.isSettled, let due = item.dueDate else { return }

        Task {
            let granted = await DailySummaryNotifier.requestAuthorization()
            guard granted else { return }

            // Remind morning of due day (9:00), or immediately if overdue window is today.
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: due)
            comps.hour = 9
            comps.minute = 0

            let content = UNMutableNotificationContent()
            if item.kind == .lent {
                content.title = language == .arabic ? "تذكير سلف" : "Lent money reminder"
                content.body = language == .arabic
                    ? "\(item.personName) المفروض يرد \(CurrencyFormat.egp(item.amount, language: .arabic)) النهارده — الذاكرة الخائنة مش حجة 😉"
                    : "\(item.personName) should return \(CurrencyFormat.egp(item.amount, language: .english)) today."
            } else {
                content.title = language == .arabic ? "تذكير دين" : "Debt reminder"
                content.body = language == .arabic
                    ? "ماتنساش تسدّد \(CurrencyFormat.egp(item.amount, language: .arabic)) لـ \(item.personName)."
                    : "Don’t forget to repay \(CurrencyFormat.egp(item.amount, language: .english)) to \(item.personName)."
            }
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    static func cancel(id: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [requestId(for: id)])
    }
}
