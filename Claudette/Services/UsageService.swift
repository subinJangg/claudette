import Foundation

enum UsageState {
    case notLoggedIn
    case loading
    case loaded(UsageData)
    case error(UsageError)
}

enum UsageError: Equatable {
    case sessionExpired
    case serverError
    case networkError
    case parseError
}

@MainActor
final class UsageService: ObservableObject {
    @Published var state: UsageState = .notLoggedIn
    @Published var lastUpdated: Date?
    @Published var isRefreshing = false

    private var timer: Timer?
    var notificationService: NotificationService?
    var settings: AppSettings?
    var usageSamples: UsageSamples?

    init() {
        state = .loading
        Task { [weak self] in
            guard let self else { return }
            if await CredentialsStore.shared.loadAsync() != nil {
                await self.fetch()
                let interval = UserDefaults.standard.integer(forKey: "refreshIntervalSeconds")
                self.startAutoRefresh(interval: interval > 0 ? interval : 300)
            } else {
                self.state = .notLoggedIn
            }
        }
    }

    func startAutoRefresh(interval: Int) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetch()
            }
        }
    }


    func fetch() async {
        guard let credentials = await CredentialsStore.shared.loadAsync() else {
            state = .notLoggedIn
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        guard let url = URL(string: "https://claude.ai/api/organizations/\(credentials.orgId)/usage") else {
            state = .error(.parseError)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("sessionKey=\(credentials.sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh) AppleWebKit/605.1.15 Safari/605.1.15", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                state = .error(.networkError)
                return
            }

            switch httpResponse.statusCode {
            case 200:
                do {
                    let usage = try UsageData(from: data)
                    state = .loaded(usage)
                    lastUpdated = Date()
                    settings?.updateAvailableModels(from: usage.weeklyModels)
                    if let session = usage.fiveHour {
                        usageSamples?.record(session.utilization)
                    }
                    if let session = usage.fiveHour,
                       let ns = notificationService,
                       let s = settings,
                       s.notificationsEnabled {
                        ns.checkAndNotify(
                            utilization: session.utilization,
                            thresholds: s.notificationThresholds,
                            sessionResetId: session.resetsAt,
                            resetDate: session.resetsAtDate
                        )
                    }
                } catch {
                    state = .error(.parseError)
                }
            case 401, 403:
                CredentialsStore.shared.invalidateCache()
                state = .error(.sessionExpired)
            default:
                state = .error(.serverError)
            }
        } catch {
            state = .error(.networkError)
        }
    }

    func checkToken() {
        CredentialsStore.shared.invalidateCache()
        state = .loading
        Task { [weak self] in
            guard let self else { return }
            if await CredentialsStore.shared.loadAsync() != nil {
                await self.fetch()
                let interval = UserDefaults.standard.integer(forKey: "refreshIntervalSeconds")
                self.startAutoRefresh(interval: interval > 0 ? interval : 300)
            } else {
                self.timer?.invalidate()
                self.state = .notLoggedIn
            }
        }
    }
}
