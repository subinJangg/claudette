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

    @Published var notificationThresholds: [Int] {
        didSet { UserDefaults.standard.set(notificationThresholds, forKey: "notificationThresholds") }
    }

    init() {
        let storedRefresh = UserDefaults.standard.integer(forKey: "refreshIntervalSeconds")
        self.refreshInterval = storedRefresh > 0 ? storedRefresh : 300

        let storedMode = UserDefaults.standard.string(forKey: "menuBarDisplayMode")
        self.menuBarDisplayMode = storedMode ?? "percent"

        let storedIconStyle = UserDefaults.standard.string(forKey: "menuBarIconStyle")
        self.menuBarIconStyle = storedIconStyle ?? "donut"

        if let stored = UserDefaults.standard.array(forKey: "notificationThresholds") as? [Int] {
            self.notificationThresholds = stored
        } else {
            self.notificationThresholds = [80]
        }
    }
}
