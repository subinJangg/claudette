import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var snoozeUntil: Date?
    private var notifiedThresholds: Set<Int> = []
    private var lastSessionResetId: String?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupCategories()
        restoreSnooze()
    }

    var isSnoozed: Bool {
        guard let until = snoozeUntil else { return false }
        return Date() < until
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func checkAndNotify(utilization: Double, thresholds: [Int], sessionResetId: String?) {
        if let newId = sessionResetId, newId != lastSessionResetId {
            lastSessionResetId = newId
            notifiedThresholds.removeAll()
        }

        guard !isSnoozed else { return }

        for threshold in thresholds.sorted() {
            if utilization >= Double(threshold) && !notifiedThresholds.contains(threshold) {
                notifiedThresholds.insert(threshold)
                sendThresholdNotification(threshold: threshold, utilization: utilization)
            }
        }
    }

    func snooze(duration: SnoozeDuration, sessionResetDate: Date?) {
        switch duration {
        case .oneHour:
            snoozeUntil = Date().addingTimeInterval(3600)
        case .today:
            snoozeUntil = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
        case .session:
            snoozeUntil = sessionResetDate ?? Date().addingTimeInterval(18000)
        }
        UserDefaults.standard.set(snoozeUntil?.timeIntervalSince1970, forKey: "snoozeUntilTimestamp")
    }

    func clearSnooze() {
        snoozeUntil = nil
        UserDefaults.standard.removeObject(forKey: "snoozeUntilTimestamp")
    }

    func restoreSnooze() {
        let ts = UserDefaults.standard.double(forKey: "snoozeUntilTimestamp")
        guard ts > 0 else { return }
        let date = Date(timeIntervalSince1970: ts)
        if Date() < date {
            snoozeUntil = date
        } else {
            UserDefaults.standard.removeObject(forKey: "snoozeUntilTimestamp")
        }
    }

    // MARK: - Private

    private func sendThresholdNotification(threshold: Int, utilization: Double) {
        let content = UNMutableNotificationContent()
        content.title = "한도 \(threshold)% 도달"
        content.body = "현재 세션 사용량이 \(Int(utilization.rounded()))%입니다."
        content.sound = .default
        content.categoryIdentifier = "USAGE_ALERT"

        let request = UNNotificationRequest(
            identifier: "threshold-\(threshold)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func setupCategories() {
        let snooze1h = UNNotificationAction(identifier: "SNOOZE_1H", title: "1시간 끄기")
        let snoozeToday = UNNotificationAction(identifier: "SNOOZE_TODAY", title: "오늘 그만")
        let snoozeSession = UNNotificationAction(identifier: "SNOOZE_SESSION", title: "이번 세션 끄기")

        let category = UNNotificationCategory(
            identifier: "USAGE_ALERT",
            actions: [snooze1h, snoozeToday, snoozeSession],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            switch response.actionIdentifier {
            case "SNOOZE_1H":
                snooze(duration: .oneHour, sessionResetDate: nil)
            case "SNOOZE_TODAY":
                snooze(duration: .today, sessionResetDate: nil)
            case "SNOOZE_SESSION":
                snooze(duration: .session, sessionResetDate: nil)
            default:
                break
            }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

enum SnoozeDuration {
    case oneHour
    case today
    case session
}
