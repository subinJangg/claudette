import SwiftUI

struct PopoverView: View {
    @ObservedObject var usageService: UsageService
    @ObservedObject var settings: AppSettings
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var usageSamples: UsageSamples
    @State private var showSettings = false

    var body: some View {
        Group {
            if showSettings {
                SettingsView(
                    settings: settings,
                    notificationService: notificationService,
                    onDismiss: { showSettings = false }
                )
            } else {
                mainContent
            }
        }
        .onChange(of: settings.refreshInterval) { _, newValue in
            usageService.startAutoRefresh(interval: newValue)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch usageService.state {
        case .notLoggedIn:
            SetupGuideView(usageService: usageService)

        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                Text("사용량 불러오는 중...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 320, height: 120)

        case .loaded(let data):
            loadedContent(data)

        case .error(let error):
            VStack(spacing: 12) {
                HeaderView(utilization: nil)
                ErrorCard(error: error, onRetry: {
                    usageService.checkToken()
                })
                footer
            }
            .padding(16)
            .frame(width: 320)
        }
    }

    @ViewBuilder
    private func loadedContent(_ data: UsageData) -> some View {
        VStack(spacing: 12) {
            HeaderView(utilization: data.fiveHour?.utilization)

            if let session = data.fiveHour {
                SessionCard(
                    bucket: session,
                    predictedMinutes: usageSamples.predictMinutesToLimit()
                )
            }

            if !data.weeklyModels.isEmpty {
                WeeklyCard(models: data.weeklyModels, settings: settings)
            }

            footer
        }
        .padding(16)
        .frame(width: 320)
    }

    private var footer: some View {
        FooterView(
            lastUpdated: usageService.lastUpdated,
            isRefreshing: usageService.isRefreshing,
            snoozeUntil: notificationService.snoozeUntil,
            snoozeDurationType: notificationService.snoozeDurationType,
            onRefresh: {
                Task { await usageService.fetch() }
            },
            onSettings: { showSettings = true },
            onQuit: { NSApplication.shared.terminate(nil) }
        )
    }
}
