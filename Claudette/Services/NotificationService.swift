import Foundation
import AppKit
import UserNotifications

@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var snoozeUntil: Date?
    @Published var snoozeDurationType: SnoozeDuration?
    @Published var systemAuthStatus: UNAuthorizationStatus = .notDetermined
    private var notifiedThresholds: Set<Int> {
        didSet {
            UserDefaults.standard.set(Array(notifiedThresholds), forKey: "notifiedThresholds")
        }
    }
    private var lastSessionResetId: String? {
        didSet {
            UserDefaults.standard.set(lastSessionResetId, forKey: "lastSessionResetId")
        }
    }
    private var sessionResetDate: Date?

    override init() {
        if let stored = UserDefaults.standard.array(forKey: "notifiedThresholds") as? [Int] {
            self.notifiedThresholds = Set(stored)
        } else {
            self.notifiedThresholds = []
        }
        self.lastSessionResetId = UserDefaults.standard.string(forKey: "lastSessionResetId")
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupCategories()
        restoreSnooze()
        refreshAuthStatus()
    }

    func refreshAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.systemAuthStatus = settings.authorizationStatus
            }
        }
    }

    func openSystemNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings") {
            NSWorkspace.shared.open(url)
        }
    }

    var isSnoozed: Bool {
        guard let until = snoozeUntil else { return false }
        return Date() < until
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func checkAndNotify(utilization: Double, thresholds: [Int], sessionResetId: String?, resetDate: Date?) {
        self.sessionResetDate = resetDate
        let normalizedId = sessionResetId.map { String($0.prefix(16)) }
        if let newId = normalizedId, newId != lastSessionResetId {
            lastSessionResetId = newId
            notifiedThresholds.removeAll()
        }

        guard !isSnoozed else { return }

        let newlyExceeded = thresholds.sorted().filter {
            utilization >= Double($0) && !notifiedThresholds.contains($0)
        }
        guard !newlyExceeded.isEmpty else { return }

        for threshold in newlyExceeded {
            notifiedThresholds.insert(threshold)
        }
        if let highest = newlyExceeded.last {
            sendThresholdNotification(threshold: highest, utilization: utilization)
        }
    }

    func snooze(duration: SnoozeDuration, sessionResetDate: Date?) {
        snoozeDurationType = duration
        switch duration {
        case .oneHour:
            snoozeUntil = Date().addingTimeInterval(3600)
        case .today:
            snoozeUntil = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86399)
        case .session:
            snoozeUntil = sessionResetDate ?? Date().addingTimeInterval(18000)
        }
        UserDefaults.standard.set(snoozeUntil?.timeIntervalSince1970, forKey: "snoozeUntilTimestamp")
        UserDefaults.standard.set(duration.rawValue, forKey: "snoozeDurationType")
    }

    func restoreSnooze() {
        let ts = UserDefaults.standard.double(forKey: "snoozeUntilTimestamp")
        guard ts > 0 else { return }
        let date = Date(timeIntervalSince1970: ts)
        if Date() < date {
            snoozeUntil = date
            if let raw = UserDefaults.standard.string(forKey: "snoozeDurationType") {
                snoozeDurationType = SnoozeDuration(rawValue: raw)
            }
        } else {
            clearSnooze()
        }
    }

    func clearSnooze() {
        snoozeUntil = nil
        snoozeDurationType = nil
        UserDefaults.standard.removeObject(forKey: "snoozeUntilTimestamp")
        UserDefaults.standard.removeObject(forKey: "snoozeDurationType")
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
                snooze(duration: .oneHour, sessionResetDate: sessionResetDate)
            case "SNOOZE_TODAY":
                snooze(duration: .today, sessionResetDate: sessionResetDate)
            case "SNOOZE_SESSION":
                snooze(duration: .session, sessionResetDate: sessionResetDate)
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

enum SnoozeDuration: String {
    case oneHour
    case today
    case session

    var label: String {
        switch self {
        case .oneHour: "1시간 끄기"
        case .today: "오늘 그만"
        case .session: "이번 세션 끄기"
        }
    }
}
