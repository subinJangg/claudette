import Foundation

final class AppSettings: ObservableObject {
    static let refreshIntervalOptions: [(label: String, seconds: Int)] = [
        ("1분", 60),
        ("3분", 180),
        ("5분", 300),
        ("10분", 600),
    ]

    @Published var refreshInterval: Int {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "refreshIntervalSeconds") }
    }

    @Published var menuBarDisplayMode: String {
        didSet { UserDefaults.standard.set(menuBarDisplayMode, forKey: "menuBarDisplayMode") }
    }

    @Published var menuBarIconStyle: String {
        didSet { UserDefaults.standard.set(menuBarIconStyle, forKey: "menuBarIconStyle") }
    }

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    @Published var notificationThresholds: [Int] {
        didSet { UserDefaults.standard.set(notificationThresholds, forKey: "notificationThresholds") }
    }

    @Published var weeklyModelOrder: [String] {
        didSet { UserDefaults.standard.set(weeklyModelOrder, forKey: "weeklyModelOrder") }
    }

    @Published var hiddenWeeklyModels: Set<String> {
        didSet { UserDefaults.standard.set(Array(hiddenWeeklyModels), forKey: "hiddenWeeklyModels") }
    }

    @Published var availableWeeklyModels: [(id: String, label: String)] = []

    static let availableThresholds = [50, 60, 70, 80, 90]

    init() {
        let storedRefresh = UserDefaults.standard.integer(forKey: "refreshIntervalSeconds")
        self.refreshInterval = storedRefresh > 0 ? storedRefresh : 300

        let storedMode = UserDefaults.standard.string(forKey: "menuBarDisplayMode")
        self.menuBarDisplayMode = storedMode ?? "percent"

        let storedIconStyle = UserDefaults.standard.string(forKey: "menuBarIconStyle")
        self.menuBarIconStyle = storedIconStyle ?? "donut"

        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")

        if let stored = UserDefaults.standard.array(forKey: "notificationThresholds") as? [Int] {
            self.notificationThresholds = stored
        } else {
            self.notificationThresholds = [80]
        }

        if let stored = UserDefaults.standard.array(forKey: "weeklyModelOrder") as? [String] {
            self.weeklyModelOrder = stored
        } else {
            self.weeklyModelOrder = []
        }

        if let stored = UserDefaults.standard.array(forKey: "hiddenWeeklyModels") as? [String] {
            self.hiddenWeeklyModels = Set(stored)
        } else {
            self.hiddenWeeklyModels = []
        }
    }

    func updateAvailableModels(from models: [WeeklyModelUsage]) {
        availableWeeklyModels = models.map { ($0.id, $0.displayName) }
        let existingIds = Set(models.map { $0.id })
        if weeklyModelOrder.isEmpty && hiddenWeeklyModels.isEmpty {
            weeklyModelOrder = models.map { $0.id }
        } else {
            weeklyModelOrder = weeklyModelOrder.filter { existingIds.contains($0) }
            for model in models where !weeklyModelOrder.contains(model.id) && !hiddenWeeklyModels.contains(model.id) {
                weeklyModelOrder.append(model.id)
            }
        }
        hiddenWeeklyModels = hiddenWeeklyModels.filter { existingIds.contains($0) }
    }
}
