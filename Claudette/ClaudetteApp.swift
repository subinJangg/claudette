import SwiftUI

@main
struct ClaudetteApp: App {
    @StateObject private var usageService: UsageService
    @StateObject private var settings: AppSettings
    @StateObject private var notificationService: NotificationService
    @StateObject private var usageSamples: UsageSamples

    init() {
        let service = UsageService()
        let s = AppSettings()
        let ns = NotificationService()
        let samples = UsageSamples()
        service.notificationService = ns
        service.settings = s
        service.usageSamples = samples
        _usageService = StateObject(wrappedValue: service)
        _settings = StateObject(wrappedValue: s)
        _notificationService = StateObject(wrappedValue: ns)
        _usageSamples = StateObject(wrappedValue: samples)
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(
                usageService: usageService,
                settings: settings,
                notificationService: notificationService,
                usageSamples: usageSamples
            )
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        switch usageService.state {
        case .loaded(let data):
            if let session = data.fiveHour {
                let level = UsageLevel(utilization: session.utilization)
                menuBarContent(session: session, level: level)
            } else {
                defaultLabel
            }
        default:
            defaultLabel
        }
    }

    @ViewBuilder
    private func menuBarContent(session: UsageBucket, level: UsageLevel) -> some View {
        let showCountdown = settings.menuBarDisplayMode == "countdown"

        if showCountdown, let resetDate = session.resetsAtDate {
            let remaining = resetDate.timeIntervalSince(Date())
            let minutes = max(0, Int(remaining / 60))
            HStack(spacing: 4) {
                menuBarIcon(value: session.utilization, color: level.color)
                Text("RESET \(minutes)m")
                    .font(.system(size: 12))
            }
            .accessibilityLabel("Claudette, \(minutes)분 후 재설정")
        } else {
            HStack(spacing: 4) {
                menuBarIcon(value: session.utilization, color: level.color)
                Text("\(Int(session.utilization.rounded()))%")
                    .font(.system(size: 12))
            }
            .accessibilityLabel("Claudette, 현재 세션 \(Int(session.utilization.rounded()))퍼센트")
        }
    }

    @ViewBuilder
    private func menuBarIcon(value: Double, color: Color) -> some View {
        if settings.menuBarIconStyle == "battery" {
            MenuBarBatteryIcon(value: value, color: color)
        } else {
            MenuBarDonutIcon(value: value, color: color)
        }
    }

    private var defaultLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge.medium")
                .font(.system(size: 12))
            Text("—")
                .font(.system(size: 12))
        }
        .accessibilityLabel("Claudette, 데이터 없음")
    }
}
